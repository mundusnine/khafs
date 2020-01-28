let project = new Project('khafs');
project.addAssets('Assets/wasmfs.js');
project.addAssets('Assets/dexie.js');
project.addDefine("wasmfs");
project.addSources('Sources');
resolve(project);
