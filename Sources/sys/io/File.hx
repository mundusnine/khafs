package sys.io;
#if (wasmfs && js)
import sys.FileSystem

class File{
    /**
     * [This is a fake simili function to be used by libraries already using the sys api not by users]
     * @param path the path to the file
     * @param onDone this function is async so the data can be set by this function when the fetch is done
     */
    public static function getContent(path:String,onDone:String->Void):Void{
        FileSystem.getContent(path,onDone);
    }
}
#end