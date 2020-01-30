#/bin/bash

cd odc
./build.sh "$@"
cd ../odc-jupyter
./build.sh "$@"
cd ..
