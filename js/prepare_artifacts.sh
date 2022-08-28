#! /bin/sh
SRC_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BUILD_PATH="$SRC_PATH/../build"
SJS_ARTIFACTS_PATH="$SRC_PATH/artifacts"

if [ ! -d $BUILD_PATH ]
then
  printf "build/ folder doesn't exist, run:\n"
  printf "$ cd ..\n"
  printf "$ protostar build --cairo-path lib/cairo-contracts/src/\n"
  exit 0
fi

if [ ! -d $SJS_ARTIFACTS_PATH ]
then
  mkdir $SJS_ARTIFACTS_PATH
fi

cd $BUILD_PATH

# Copy all .json files to artifacts as .txt
find . -wholename "*.json" ! -wholename "*_abi.json" \
  -exec sh -c 'cp "$1" "../js/artifacts/${1%.json}.txt"' _ {} \;