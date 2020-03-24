let project = new Project('khafs');
project.addAssets('Assets/wasmfs.js');
project.addAssets('Assets/dexie.js');
project.addDefine("wasmfs");

let html5 = process.argv.indexOf("html5") >= 0;
if(html5){
    project.addSources('Sources/khafs');
    project.addSources('Sources/sys');
}
else {
    project.addSources('Sources/khafs');
}
resolve(project);
