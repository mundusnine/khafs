package kha;

#if (kha_html5 &&js)
import js.html.CanvasElement;
import js.Browser.document;
import js.Browser.window;
import js.Syntax;
#end

class FileSystem {
	#if !macro
    public static var dataPath = "";
    public static var curDir:String = "";
    public static var sep ="/";
	static var lastPath:String = "";

	#if ( kha_html5 && js)
	static var wasm:kha.WasmFs;
	static function includeJs(path:String,done:Void->Void){
		var js:js.html.ScriptElement = cast(document.createElement("script"));
		js.type = "text/javascript";
		js.src = path;
		js.onload = done;
		document.body.appendChild(js);
	}
	#end
	public static function init(done:Void->Void){
		#if ( kha_html5 && js)
		includeJs('./wasmfs.js',function(){
			wasm = new WasmFs();
			done();
		});
		
		// done();
		#else
		done();
		#end
	}
    static function initPath(systemId: String) {
		switch (systemId){
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
	
	static public function fixPath(path:String){
		#if kha_webgl
		var systemId = "None";
		var userAgent = untyped navigator.userAgent.toLowerCase();
		if (userAgent.indexOf(' electron/') > -1) {
			var pp = untyped window.process.platform;
			systemId = pp == "win32" ? "Windows" : (pp == "darwin" ? "OSX" : "Linux");
		}
		#else
		var systemId = kha.System.systemId;
		#end
		
		if (path == "") path = initPath(systemId);
		switch (systemId){
			case "Windows":
				return StringTools.replace(path, "/", "\\");
			case "Linux":
				var home ="/";
				if(StringTools.contains(path,"$HOME") || path.charAt(0) == "~"){
					#if kha_krom
					var save = Krom.getFilesLocation() + sep + dataPath + "HOME.txt";
					Krom.sysCommand("echo $HOME "+'> $save');
					home = haxe.io.Bytes.ofData(Krom.loadBlob(save)).toString();
					var temp = home.split("\n");
					temp.pop();
					home = temp.join("");
					#elseif kha_kore
					var names = Sys.programPath().split('/');
					names.pop(); 
					path = names.join('/');

					#elseif kha_webgl
					var userAgent = untyped navigator.userAgent.toLowerCase();
					if (userAgent.indexOf(' electron/') > -1) {
						home = untyped process.env.HOME || process.env.HOMEPATH || process.env.USERPROFILE;
					}
					
					#end
					if(path.charAt(0) == "~"){
						path = StringTools.replace(path,"~",home);
					}
					else {
						path = StringTools.replace(path,"$HOME",home);
					}
				}
				return path;
			default:
				return path;
		}
	}
    
	static public function exists(path:String){
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
		#elseif kha_kore
		return sys.FileSystem.exists(path);
		#elseif kha_webgl
		return wasm.fs.existsSync(path);
		#else
		return false;
		#end
	}
    static public function getFiles(path:String, folderOnly =false){

        #if kha_krom

		var cmd = "ls -F ";
		var systemId = kha.System.systemId;
		if (systemId == "Windows") {
			cmd = "dir /b ";
			if (folderOnly) cmd += "/ad ";
			sep = "\\";
			path = StringTools.replace(path, "\\\\", "\\");
			path = StringTools.replace(path, "\r", "");
		}
		path = fixPath(path);
		var save = Krom.getFilesLocation() + sep + dataPath + "dir.txt";
		if (path != lastPath) Krom.sysCommand(cmd + '"' + path + '"' + ' > ' + '"' + save + '"');
		lastPath = path;
		var str = haxe.io.Bytes.ofData(Krom.loadBlob(save)).toString();
		var files = str.split("\n");
		#elseif kha_kore

		path = fixPath(path);
		var files = sys.FileSystem.isDirectory(path) ? sys.FileSystem.readDirectory(path) : [];

		#elseif kha_webgl

		var files:Array<String> = [];

		var userAgent = untyped navigator.userAgent.toLowerCase();
		if (userAgent.indexOf(' electron/') > -1) {
			try {
				path = fixPath(path);
				files = wasm.fs.readdirSync(path);
			}
			catch(e:Dynamic) {
				// Non-directory item selected
			}
		}

		#else

		var files:Array<String> = [];

		#end
        curDir = path;
		if(folderOnly){
			files = files.filter(function (e:String){
				return isDirectory(path+sep+e);
			});
		}
		#if kha_krom
		for(i in 0...files.length){
			var f = files[i];
			if(f.charAt(f.length-1) == '/'){
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
		return path.charAt(path.length-1)=="/";
		#elseif kha_kore
		return sys.FileSystem.isDirectory(path);
		#elseif kha_webgl
		return try wasm.fs.statSync(path).isDirectory() catch (e:Dynamic) false;
		#else
		return false;
		#end
		
	}
	public static function createDirectory(path:String,onDone:Void->Void = null):Void {
		#if kha_krom
		var cmd = "mkdir";
		var systemId = kha.System.systemId;
		if (systemId == "Windows") {
			sep = "\\";
			path = StringTools.replace(path, "\\\\", "\\");
			path = StringTools.replace(path, "\r", "");
		}
		Krom.sysCommand(cmd + '"' + path + '"');
		if(onDone!= null)
			onDone();
		#elseif kha_kore
		sys.FileSystem.createDirectory(path);
		if(onDone!= null)
			onDone();
		#elseif kha_webgl
		try  wasm.fs.mkdir(path,null,function(err){
			if(err!=null) throw err;
			else if(onDone!= null)
				onDone();
		});
		#else
		throw "Target platform doesn't support creating a directory";
		#end
	}
	
	public static function getContent(path:String,onDone:String->Void):Void{
		if(FileSystem.exists(path)){
			var data = "";
			#if kha_krom
			var buffer = Krom.loadBlob(path);
			onDone(buffer.toString());// @:Incomplete we need to test this
			#elseif kha_kore
			data = sys.io.File.getContent(path);
			onDone();
			#elseif kha_webgl
			wasm.fs.readFile(path,{encoding:'utf8'},function (err,data){
				if(err!=null) throw err;
				onDone(data);
			});
			#else
			throw "Target platform doesn't support saving data to files";
			#end
			
		}
	}

	#end// !macro
	public static function saveToFile(path:String,data:haxe.io.Bytes,onDone:Void->Void = null){
		#if kha_krom
		Krom.fileSaveBytes(path,data.getData());
		if(onDone!= null)
			onDone();
		#elseif (kha_kore || macro)
		sys.io.File.saveBytes(path,data);
		if(onDone!= null)
			onDone();
		#elseif kha_webgl
		wasm.fs.writeFile(path,data,null,function (err){
			if(err!=null) throw err;
			else if(onDone!= null)
				onDone();
		});
		#else
		throw "Target platform doesn't support saving data to files";
		#end
	}
}