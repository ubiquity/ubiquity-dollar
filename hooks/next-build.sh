#!/bin/bash

cd contracts/
yes | npm install
npx hardhat compile
cp contracts/artifacts/types frontend/src/types
cd ../frontend/
yes | npm install
npx next build
npx next start