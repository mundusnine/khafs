package khafs;

@:native('WasmFs.WasmFs')
extern class WasmFs {
    public function new():Void;
    public var fs:Wasmer;
    
}
extern class Wasmer{
	public function existsSync(path:String):Bool;
    public function unlinkSync(path:String):Void;
    public function unlink(path:String,callback:js.lib.Error->Void):Void;
    public function rmdirSync(path:String,?options:{maxRetries:Int,recursive:Bool,retryDelay:Int}):Void;
    public function rmdir(path:String,?options:{maxRetries:Int,recursive:Bool,retryDelay:Int},callback:js.lib.Error->Void):Void;
    public function readdirSync(path:String,?options:{encoding:String,withFileTypes:Bool}):Dynamic;
    public function statSync(path:String,?options:{bigint:Bool}):Stats;
    public function mkdir(path:String,?options:{recursive:Bool,?mode:Int},callback:js.lib.Error->Void):Void;
    public function readFile(path:String,?options:{encoding:Null<String>,?flag:String},callback:js.lib.Error->Dynamic->Void):Void;
    public function writeFile(file:String,data:Dynamic,?options:{encoding:Null<String>,?mode:Int,?flag:String},callback:js.lib.Error->Void):Void;
}

/**
	Objects returned from `Fs.stat`, `Fs.lstat` and `Fs.fstat` and their synchronous counterparts are of this type.
**/
extern class Stats {
	var dev:Int;
	var ino:Float;
	var mode:Int;
	var nlink:Int;
	var uid:Int;
	var gid:Int;
	var rdev:Int;
	var size:Float;
	var blksize:Null<Int>;
	var blocks:Null<Float>;

	/**
		"Access Time" - Time when file data last accessed.
		Changed by the mknod(2), utimes(2), and read(2) system calls.
	**/
	var atime:Date;

	/**
		"Modified Time" - Time when file data last modified.
		Changed by the mknod(2), utimes(2), and write(2) system calls.
	**/
	var mtime:Date;

	/**
		"Change Time" - Time when file status was last changed (inode data modification).
		Changed by the chmod(2), chown(2), link(2), mknod(2), rename(2), unlink(2), utimes(2), read(2), and write(2) system calls.
	**/
	var ctime:Date;

	/**
		"Birth Time" - Time of file creation. Set once when the file is created.
		On filesystems where birthtime is not available, this field may instead hold either the ctime or 1970-01-01T00:00Z (ie, unix epoch timestamp 0).
		Note that this value may be greater than `atime` or `mtime` in this case. On Darwin and other FreeBSD variants,
		also set if the `atime` is explicitly set to an earlier value than the current birthtime using the utimes(2) system call.
	**/
	var birthtime:Date;

	function isFile():Bool;
	function isDirectory():Bool;
	function isBlockDevice():Bool;
	function isCharacterDevice():Bool;

	/**
		Only valid with `Fs.lstat`.
	**/
	function isSymbolicLink():Bool;

	function isFIFO():Bool;
	function isSocket():Bool;
}