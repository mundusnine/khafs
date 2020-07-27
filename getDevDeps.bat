start "" /WAIT cmd.exe /c "scoop install coreutils"
start "" /WAIT cmd.exe /c "scoop install wget"
set version="0.11.2"
wget -m -A * -pk -e robots=off https://unpkg.com/browse/@wasmer/wasmfs@%version%/lib/
mv unpkg.com/@wasmer/wasmfs@%version%/lib/node_modules ./Assets/node_modules
mv unpkg.com/@wasmer/wasmfs@%version%/lib/packages ./Assets/packages
mv unpkg.com/@wasmer/wasmfs@%version%/lib/index.iife.js ./Assets/wasmfs.js
rm -r unpkg.com
wget https://unpkg.com/dexie@latest/dist/dexie.js
mv dexie.js ./Assets/dexie.js