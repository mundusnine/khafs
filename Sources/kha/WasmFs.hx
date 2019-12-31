package kha;

@:native('WasmFs.WasmFs')
extern class WasmFs {
    public function new():Void;
    public var fs:Dynamic;
    public function existsSync(path:String):Bool;
    public function readdirSync(path:String,?options:{encoding:String,withFileTypes:Bool}):Dynamic;
    public function statSync(path:String,?options:{bigint:Bool}):Dynamic;
    public function mkdir(path:String,?options:{recursive:Bool,?mode:Int},callback:js.lib.Error->Void):Void;
    public function readFile(path:String,?options:{encoding:Null<String>,?flag:String},callback:js.lib.Error->Dynamic->Void):Void;
    public function writeFile(file:String,data:Dynamic,?options:{encoding:Null<String>,?mode:Int,?flag:String},callback:js.lib.Error->Void):Void;
}