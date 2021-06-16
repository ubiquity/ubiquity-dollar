#!/bin/bash

cd contracts/
echo "--- 0 ---"
yarn
echo "--- 1 ---"
yarn add hardhat
echo "--- 2 ---"
export TS_NODE_TRANSPILE_ONLY=1 && yarn hardhat compile
echo "--- 3 ---"
mkdir -p frontend/src/types
echo "--- 4 ---"
cp -r contracts/artifacts/types frontend/src/types
echo "--- 5 ---"
cd ../frontend/
echo "--- 6 ---"
yarn
echo "--- 7 ---"
yarn next build
echo "--- 8 ---"
yarn next start
echo "--- 9 ---"