#!/bin/bash

cd contracts/ || echo "ERROR: contracts/ doesn't exist?" && exit
yarn
yarn hardhat compile
cp uad/contracts/artifacts/types uad/frontend/src/types
cd ../frontend/ || echo "ERROR: ../frontend/ doesn't exist?" && exit
yarn
yarn next start