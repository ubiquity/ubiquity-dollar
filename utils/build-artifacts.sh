#!/usr/bin/env bash

cd "$(npm root)" || exit 1
cd ..
cd "$1" || exit 1

yarn hardhat export --network mainnet
yarn hardhat export --network hardhat

# cd "$(npm root)" || exit 1
# cd ..
# cd ./contracts/dollar || echo "ERROR: ./contracts/dollar/ doesn't exist?"

# UP=../
# DEPLOYMENT_ARTIFACT=fixtures/ubiquity-dollar-deployment.json

# yarn install
# yarn build

# rm -f $UP$DEPLOYMENT_ARTIFACT
# yarn hardhat export --export $UP$DEPLOYMENT_ARTIFACT --network mainnet &
# yarn hardhat export --export $UP$DEPLOYMENT_ARTIFACT --network hardhat
# cd $UP || exit 1
