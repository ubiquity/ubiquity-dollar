#!/bin/bash

cd $(pwd)/../contracts/
yarn
export TS_NODE_TRANSPILE_ONLY=1 && yarn hardhat compile
next build
yarn run prestart
