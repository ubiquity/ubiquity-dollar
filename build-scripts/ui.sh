#!/bin/bash

git submodule update --init --recursive --remote # pull in uad-contracts
cd contracts || exit 1
yarn
TS_NODE_TRANSPILE_ONLY=1 yarn hardhat compile # errors compiling typings in tasks/
# create deployment artifact