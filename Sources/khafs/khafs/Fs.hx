package khafs;

#if (kha_html5 && js)
import js.html.idb.Database;
import js.html.idb.OpenDBRequest;
import js.html.idb.Transaction;
import js.html.idb.TransactionMode;
import js.html.StorageType;
import js.html.PermissionState;
import js.html.InputElement;
import js.html.CanvasElement;
import js.Browser.navigator;
import js.Browser.document;
import js.Browser.window;
import js.Syntax;
#end

class Fs {
	#if !macro
	public static var dataPath = "";
	public static var curDir:String = "";
	public static var sep = "/";
	static var lastPath:String = "";

	#if (kha_html5 && js)
	static var db:Database;
	public static var dbKeys:Map<String, Bool> = new Map<String, Bool>();
	static var wasm:khafs.WasmFs;

	static function includeJs(path:String, done:Void->Void) {
		var js:js.html.ScriptElement = cast(document.createElement("script"));
		js.type = "text/javascript";
		js.src = path;
		js.onload = done;
		document.body.appendChild(js);
	}

	/**
	 * [BROWSER]
	 *
	 * Call input.click() from your button event to open browser OS file input.
	 */
	public static var input:InputElement;

	static function addInputElement() {
		// Base it on this: https://developer.mozilla.org/en-US/docs/Web/API/File/Using_files_from_web_applications
		input = document.createInputElement();
		input.type = "file";
		input.id = "fileElem";
		input.multiple = true;
		input.style.display = "none";
		input.onchange = onAddFiles;
		document.body.appendChild(input);
	}

	static var reader:js.html.FileReader = new js.html.FileReader();

	static function next(index:Int) {
		var file = input.files[index];
		reader.onload = function() {
			var url = reader.result.split('base64,')[1];
			var data:haxe.io.Bytes = haxe.crypto.Base64.decode(url);
			var path = curDir + sep + file.name;

			saveContent(path, url, function() {
				if (index + 1 < input.files.length) {
					next(index + 1);
				}
			});
		}
		reader.readAsDataURL(file);
	}

	static function onAddFiles() {
		if (input != null) {
			trace("num in's: " + input.files.length);
			if (0 < input.files.length) {
				next(0);
			}
		}
	}

	static function tryPersistWithoutPromtingUser(done:String->Void) {
		if (navigator.storage == null || navigator.storage.persisted == null) {
			done("never");
			return;
		}
		navigator.storage.persisted().then(function(persisted) {
			if (persisted) {
				done("persisted");
				return;
			}
			if (navigator.permissions == null || navigator.permissions.query == null) {
				done("prompt"); // It MAY be successful to prompt. Don't know.
				return;
			}
			navigator.permissions.query({
				name: "persistent-storage"
			}).then(function(permission) {
				if (permission.state == PermissionState.GRANTED) {
					navigator.storage.persist().then(function(persisted) {
						if (persisted) {
							done("persisted");
							return;
						} else {
							throw "Failed to persist";
						}
					});
				}
				if (permission.state == PermissionState.PROMPT) {
					done("prompt");
					return;
				}
				done("never");
				return;
			});
		});
	}
	#end

	public static function init(done:Void->Void) {
		#if (kha_html5 && js)
		addInputElement();
		includeJs('./wasmfs.js', function() {
			wasm = new WasmFs();
			includeJs('./dexie.js', function() {
				var tdb:Dynamic = null;
				untyped __js__('{0} = new Dexie("projects")', tdb);
				var create = function(e) {
					tdb.version(1).stores({projects: ''});
					var out = function() {
						if (tdb.isOpen()) {
							db = tdb.backendDB();
							tryPersistWithoutPromtingUser(function(result:String) {
								switch (result) {
									case "never":
										trace("Not possible to persist storage");
									case "persisted":
										trace("Successfully persisted storage silently");
									case "prompt":
										trace("Not persisted, but we may prompt user when we want to.");
								}
								done();
							});
						} else {
							trace("IndexedDB been closed: " + tdb.hasBeenClosed());
							trace("IndexedDB has failed to open: " + tdb.hasFailed());
						}
					};
					untyped __js__('tdb.open().then({0}).catch({1})', out, function(e) {
						trace(e.name);
					});
				};
				var open = function(p_db) {
					db = p_db.backendDB();
					#if debug
					trace("Opened DB with name: " + db.name);
					#end
					var transaction:Transaction = db.transaction(["projects"], TransactionMode.READWRITE);
					var store = transaction.objectStore("projects");
					var req = store.getAllKeys();
					req.onsuccess = function(e) {
						var data:Array<String> = req.result;
						for (name in data) {
							dbKeys.set(name, true);
						}
						done();
					}
				};
				untyped __js__('tdb.open().then({0}).catch({1})', open, create);
			});
		});
		// done();
		#else
		done();
		#end
	}

	static function initPath(systemId:String) {
		switch (systemId) {
			case "Windows":
				return "C:\\Users";
			case "Linux":
				return "$HOME";
			default:
				return "/";
		}
		// %HOMEDRIVE% + %HomePath%
		// ~
	}

	static public function fixPath(path:String) {
		#if (kha_webgl || js)
		// We are in the browser or electron ergo posix env
		var systemId = "Linux";
		#else
		var systemId = kha.System.systemId;
		#end

		if (path == "")
			path = initPath(systemId);
		switch (systemId) {
			case "Windows":
				return StringTools.replace(path, "/", "\\");
			case "Linux":
				var home = "/";
				if (StringTools.contains(path, "$HOME") || path.charAt(0) == "~") {
					#if kha_krom
					var save = Krom.getFilesLocation() + sep + dataPath + "HOME.txt";
					Krom.sysCommand("echo $HOME " + '> $save');
					home = haxe.io.Bytes.ofData(Krom.loadBlob(save)).toString();
					var temp = home.split("\n");
					temp.pop();
					home = temp.join("");
					#elseif (kha_kore || sys)
					var names = Sys.programPath().split('/');
					names.pop();
					path = names.join('/');
					#elseif (kha_webgl || js)
					// We are in a virtualized, secure wasmfs situation
					home = './';
					#end
					if (path.charAt(0) == "~") {
						path = StringTools.replace(path, "~", home);
					} else {
						path = StringTools.replace(path, "$HOME", home);
					}
				}
				return path;
			default:
				return path;
		}
	}

	static public function exists(path:String) {
		path = fixPath(path);
		#if kha_krom
		var save = Krom.getFilesLocation() + sep + dataPath + "exists.txt";
		var systemId = kha.System.systemId;
		var cmd = 'if [ -f "$path" ]; then\n\techo "true"\nelse\n\techo "false"\nfi > $save';
		if (systemId == "Windows") {
			// cmd = "dir /b ";
			// sep = "\\";
			// path = StringTools.replace(path, "\\\\", "\\");
			// path = StringTools.replace(path, "\r", "");
			return false;
		}
		Krom.sysCommand(cmd);
		var str = haxe.io.Bytes.ofData(Krom.loadBlob(save)).toString();
		return str == "true";
		#elseif (kha_kore || sys)
		return sys.FileSystem.exists(path);
		#elseif (kha_webgl || js)
		return wasm.fs.existsSync(path) || (db != null && dbKeys.exists(path));
		#else
		return false;
		#end
	}

	static public function readDirectory(path:String, folderOnly = false) {
		#if kha_krom
		var cmd = "ls -F ";
		var systemId = kha.System.systemId;
		if (systemId == "Windows") {
			cmd = "dir /b ";
			if (folderOnly)
				cmd += "/ad ";
			sep = "\\";
			path = StringTools.replace(path, "\\\\", "\\");
			path = StringTools.replace(path, "\r", "");
		}
		path = fixPath(path);
		var save = Krom.getFilesLocation() + sep + dataPath + "dir.txt";
		if (path != lastPath)
			Krom.sysCommand(cmd + '"' + path + '"' + ' > ' + '"' + save + '"');
		lastPath = path;
		var str = haxe.io.Bytes.ofData(Krom.loadBlob(save)).toString();
		var files = str.split("\n");
		#elseif (kha_kore || sys)
		path = fixPath(path);
		var files = sys.FileSystem.isDirectory(path) ? sys.FileSystem.readDirectory(path) : [];
		#elseif (kha_webgl || js)
		var files:Array<String> = [];
		try {
			path = fixPath(path);
			files = wasm.fs.readdirSync(path);
		} catch (e:Dynamic) {
			// Non-directory item selected
		}
		#else
		var files:Array<String> = [];
		#end
		curDir = path;
		if (folderOnly) {
			files = files.filter(function(e:String) {
				return isDirectory(path + sep + e);
			});
		}
		#if kha_krom
		for (i in 0...files.length) {
			var f = files[i];
			if (f.charAt(f.length - 1) == '/') {
				var temp = f.split('/');
				temp.pop();
				files[i] = temp.join('/');
			}
		}
		#end
		return files;
	}

	public static function isDirectory(path:String):Bool {
		#if kha_krom
		return path.charAt(path.length - 1) == "/";
		#elseif (kha_kore || sys)
		return sys.FileSystem.isDirectory(path);
		#elseif (kha_webgl || js)
		return try Fs.stat(path).isDirectory() catch (e:Dynamic) false;
		#else
		return false;
		#end
	}

	public static function createDirectory(path:String, onDone:Void->Void = null):Void {
		#if kha_krom
		var cmd = "mkdir";
		var systemId = kha.System.systemId;
		if (systemId == "Windows") {
			sep = "\\";
			path = StringTools.replace(path, "\\\\", "\\");
			path = StringTools.replace(path, "\r", "");
		}
		Krom.sysCommand(cmd + '"' + path + '"');
		if (onDone != null)
			onDone();
		#elseif kha_kore
		sys.FileSystem.createDirectory(path);
		if (onDone != null)
			onDone();
		#elseif (kha_webgl || js)
		try
			wasm.fs.mkdir(path, {recursive: true}, function(err) {
				if (err != null)
					throw err;
				else if (onDone != null)
					onDone();
			});
		#else
		throw "Target platform doesn't support creating a directory";
		#end
	}

	public static function stat(path:String) {
		#if (kha_kore || sys)
		return sys.FileSystem.stat(path);
		#else
		return wasm.fs.statSync(path);
		#end
	}

	/**
	 * Deletes the directory specified by path. If recursive is false, only empty directories can be deleted.
	 * If path does not denote a valid directory, an exception is thrown in debug mode.
	 * @param path the path to the folder to remove.
	 * @param recursive if we should recursively remove files and folders. Defaults to false.
	 * @param done if specified, we will use async functions in supported platforms.
	 */
	public static function deleteDirectory(path:String, recursive:Bool = false, done:Void->Void = null) {
		if (!recursive) {
			#if (kha_kore || sys)
			sys.FileSystem.deleteDirectory(path);
			if (done != null)
				done();
			#else
			if (done != null) {
				wasm.fs.rmdir(path, null, function(e) {
					#if debug
					if (e != null)
						throw e;
					#end
					done();
				});
			} else {
				wasm.fs.rmdirSync(path);
			}
			#end
		} else {
			var async = done != null ? function() {} : null;
			for (p in Fs.readDirectory(path)) {
				var pa = '$path/$p';
				if (Fs.isDirectory(pa)) {
					Fs.deleteDirectory(pa, true, async);
				} else {
					Fs.deleteFile(pa, async);
					#if (wasmfs && js)
					khafs.Fs.dbKeys.remove(pa);
					#end
				}
			}
			Fs.deleteDirectory(path, false, done);
		}
	}

	/**
	 * Deletes the file specified by path. If a function is given we call the async method in supported platforms.
	 * If path does not denote a valid file we continue in release mode or we throw in debug mode.
	 * @param path a String representing the path to the file.
	 * @param done the function to be called when the async call is done.
	 */
	public static function deleteFile(path:String, done:Void->Void = null) {
		#if (kha_kore || sys)
		sys.FileSystem.deleteFile(path);
		if (done != null)
			done();
		#else
		var transaction:Transaction = db.transaction(["projects"], TransactionMode.READWRITE);
		var store = transaction.objectStore("projects");
		if (done != null) {
			wasm.fs.unlink(path, null, function(e) {
				#if debug
				if (e != null)
					throw e;
				#end
				var req = store.delete(path);
				req.onsuccess = function(event) {
					trace('Successfully deleted file $path from DB');
					done();
				};
				req.onerror = function(event) {
					#if debug throw #else trace(#end 'Error file at $path was not found' #if debug #else) #end;
					done();
				};
			});
		} else {
			wasm.fs.unlinkSync(path);
			var req = store.delete(path);
			req.onsuccess = function(event) {
				trace('Successfully deleted file $path');
			};
			req.onerror = function(event) {
				trace('Error file at $path was not found');
			};
		}
		#end
	}

	#if wasmfs
	public static function getData(path:String, onDone:kha.Blob->Void, onError:kha.AssetError->Void = null) {
		if (StringTools.endsWith(path, '.json')) {
			getContent(path, function(data:String) {
				var bytes = haxe.io.Bytes.ofString(data);
				onDone(kha.Blob.fromBytes(bytes));
			});
		} else {
			getBytes(path, onDone, onError);
		}
	}
	#end

	public static function getBytes(path:String, onDone:kha.Blob->Void, onError:kha.AssetError->Void = null) {
		if (Fs.exists(path)) {
			var data:kha.Blob;
			#if kha_krom
			var buffer = Krom.loadBlob(path);
			onDone(buffer); // @:Incomplete we need to test this
			#elseif (kha_kore || sys)
			data = kha.Blob.fromBytes(sys.io.File.getBytes(path));
			onDone(data);
			#elseif (kha_webgl || js)
			if (wasm.fs.existsSync(path)) {
				wasm.fs.readFile(path, null, function(err, p_data) {
					if (err != null) {
						if (onError != null)
							onError({url: path, error: err});
						else
							throw err;
						return;
					}
					var bytes = haxe.crypto.Base64.decode(haxe.io.Bytes.ofData(p_data).toString());
					onDone(kha.Blob.fromBytes(bytes));
				});
			} else {
				// No need to check if db null, checked in exists();
				var transaction:Transaction = db.transaction(["projects"], TransactionMode.READWRITE);
				var store = transaction.objectStore("projects");
				var req = store.get(path);
				req.onsuccess = function(event) {
					var bytes:haxe.io.Bytes = haxe.io.Bytes.ofData(req.result.b);
					var p:Dynamic = path.split('/');
					p.pop();
					p = p.join('/');
					if (!Fs.exists(p))
						Fs.createDirectory(p);
					Fs.saveBytes(path, bytes);
					onDone(kha.Blob.fromBytes(bytes));
				};
				req.onerror = function(event) {
					trace('Error file at $path was not found');
				};
			}
			#else
			throw "Target platform doesn't support saving data to files";
			#end
		}
	}

	public static function getContent(path:String, onDone:String->Void):Void {
		if (Fs.exists(path)) {
			var data = "";
			#if kha_krom
			var buffer = Krom.loadBlob(path);
			onDone(buffer.toString()); // @:Incomplete we need to test this
			#elseif (kha_kore || sys)
			data = sys.io.File.getContent(path);
			onDone(data);
			#elseif (kha_webgl || js)
			if (wasm.fs.existsSync(path)) {
				wasm.fs.readFile(path, {encoding: 'utf8'}, function(err, data) {
					if (err != null)
						throw err;
					onDone(data);
				});
			} else {
				// No need to check if db null, checked in exists();
				var transaction:Transaction = db.transaction(["projects"], TransactionMode.READWRITE);
				var store = transaction.objectStore("projects");
				var req = store.get(path);
				req.onsuccess = function(event) {
					var bytes:haxe.io.Bytes;
					if (Std.is(req.result, String)) {
						bytes = haxe.io.Bytes.ofString(req.result);
					} else {
						bytes = haxe.io.Bytes.ofData(req.result.b);
					}
					var p:Dynamic = path.split('/');
					p.pop();
					p = p.join('/');
					if (!Fs.exists(p))
						Fs.createDirectory(p);
					Fs.saveBytes(path, bytes);
					onDone(bytes.toString());
				};
				req.onerror = function(event) {
					trace('Error file at $path was not found');
				};
			}
			#else
			throw "Target platform doesn't support saving data to files";
			#end
		}
	}
	#end // !macro

	public static function saveBytes(path:String, data:haxe.io.Bytes, onDone:Void->Void = null) {
		saveToFile(path, data, null, onDone);
	}

	public static function saveContent(path:String, data:String, onDone:Void->Void = null) {
		saveToFile(path, null, data, onDone);
	}

	static function saveToFile(path:String, bytes:haxe.io.Bytes = null, content:String = null, onDone:Void->Void = null) {
		#if kha_krom
		Krom.fileSaveBytes(path, data.getData());
		if (onDone != null)
			onDone();
		#elseif (kha_kore || sys)
		if (bytes != null)
			sys.io.File.saveBytes(path, bytes);
		else if (content != null)
			sys.io.File.saveContent(path, content);
		if (onDone != null)
			onDone();
		#elseif (kha_webgl || js)
		var data:Any;
		if (bytes != null)
			data = bytes;
		else
			data = content;
		wasm.fs.writeFile(path, data, null, function(err) {
			if (err != null)
				throw err;
			if (db != null) {
				var transaction:Transaction = db.transaction(["projects"], TransactionMode.READWRITE);
				var store = transaction.objectStore("projects");

				var error = function(event) {
					#if debug
					trace('Was unable to create $path, maybe not enough space is available');
					#end
					if (onDone != null)
						onDone();
				};
				var sucess = function(event) {
					#if debug
					trace('succeeded in writing $path');
					#end
					dbKeys.set(path, true);
					if (onDone != null)
						onDone();
				};

				var req = store.get(path);
				// If already exists
				req.onsuccess = function(event) {
					var r = store.delete(path);
					r.onsuccess = function(event) {
						var nreq = store.put(data, path);
						nreq.onsuccess = sucess;
						nreq.onerror = error;
					};
				};
				req.onerror = function(event) {
					var nreq = store.put(data, path);
					nreq.onsuccess = sucess;
					nreq.onerror = error;
				};
			} else {
				if (onDone != null)
					onDone();
			}
		});
		#else
		throw "Target platform doesn't support saving data to files";
		#end
	}
}
