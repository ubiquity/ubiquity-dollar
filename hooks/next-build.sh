#!/bin/bash

cd contracts/
echo "--- 1 ---"
sleep 1
yarn
echo "--- 2 ---"
sleep 1
yes | yarn hardhat compile
echo "--- 3 ---"
sleep 1
mkdir -p frontend/src/types
echo "--- 4 ---"
sleep 1
cp -r contracts/artifacts/types frontend/src/types
echo "--- 5 ---"
sleep 1
cd ../frontend/
echo "--- 6 ---"
sleep 1
yarn
echo "--- 7 ---"
sleep 1
yarn next build
echo "--- 8 ---"
sleep 1
yarn next start
echo "--- 9 ---"
sleep 1