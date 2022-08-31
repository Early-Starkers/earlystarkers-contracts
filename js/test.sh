#! /bin/bash
SRC_PATH=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

source /home/zet/dev/cairo/cairo_venv/bin/activate

$SRC_PATH/prepare_artifacts.sh

starknet-devnet --seed 180735907 &
sleep 3

node src/deploy.mjs

killall starknet-devnet
