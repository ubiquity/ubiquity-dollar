#!/bin/bash

cd contracts/
npm install
yes | npx hardhat compile
mkdir -p frontend/src/types
cp -r contracts/artifacts/types frontend/src/types
cd ../frontend/
npm install
npx next build
npx next start