#!/usr/bin/env bash

cd "$(npm root)" || exit 1
cd ..
cd "$1" || exit 1

yarn hardhat export --network mainnet
yarn hardhat export --network hardhat

