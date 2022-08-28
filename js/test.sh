#! /bin/bash

source /home/zet/dev/cairo/cairo_venv/bin/activate

starknet-devnet --seed 180735907 &
sleep 3

node src/deploy.mjs

killall starknet-devnet