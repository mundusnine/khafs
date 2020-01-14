# khafs
Because the Std FileSystem didn't support browsers and I wanted an easier way to handle FileSystem across the board.

This library aims to be usable by libraries already using sys but aims to simplify using the FileSystem for new users so instead of having a File class and a FileSystem class we use one FileSystem class to do everything i.e. ` kha.FileSystem.getContent(pathToFile)` instead of ` sys.io.File.getContent(pathToFile)`.

For know if you have a kha project just add this to the khafile.js:
`await project.addProject('/path/to/khafs');`

Haxelib json will be added eventually or make a PR.