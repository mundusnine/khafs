#if (wasmfs && js)
package sys.io;

import sys.FileSystem;

class File{
    /**
     * [This is a fake simili function to be used by libraries already using the sys api not by users]
     * @param path the path to the file
     * @param onDone this function is async so the data can be set by this function when the fetch is done
     */
    public static function getContent(path:String,onDone:String->Void):Void{
        khafs.Fs.getContent(path,onDone);
    }
}
#end