#!/bin/bash
git clone --recurse-submodules -j8 https://github.com/ubiquity/uad-contracts.git contracts
cd ./contracts || echo "ERROR: ./contracts/ doesn't exist?"

UP=../
DEPLOYMENT_ARTIFACT=fixtures/full-deployment.json

yarn install
yarn build

rm -f $UP$DEPLOYMENT_ARTIFACT
yarn hardhat export --export $UP$DEPLOYMENT_ARTIFACT --network mainnet
cd $UP || exit 1
exit 0
