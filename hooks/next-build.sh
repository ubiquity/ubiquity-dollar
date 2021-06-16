#!/bin/bash

cd $(pwd)/../contracts/
echo "✅ --- 0 ---"
pwd
yarn
echo "✅ --- 1 ---"
pwd
yarn add hardhat
echo "✅ --- 2 ---"
pwd
export TS_NODE_TRANSPILE_ONLY=1 && yarn hardhat compile
echo "✅ --- 3 ---"
pwd
# mkdir -p ../frontend/src/
echo "✅ --- 4 ---"
pwd
cp -r ./artifacts/types $(pwd)/src/
echo "✅ --- 5 ---"
pwd
cd $(pwd)/
echo "✅ --- 6 ---"
pwd
yarn
echo "✅ --- 7 ---"
pwd
next build;
yarn run prestart;
echo "✅ --- 8 ---"
pwd
# yarn next start
echo "✅ --- 9 ---"
pwd