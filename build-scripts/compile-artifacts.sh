#!/bin/bash
git submodule update --init --recursive --remote
cd ./contracts || echo "ERROR: ./contracts/ doesn't exist?"

UP=../
DEPLOYMENT_ARTIFACT=fixtures/full-deployment.json

yarn install
yarn build

rm -f $UP$DEPLOYMENT_ARTIFACT
yarn hardhat export --export $UP$DEPLOYMENT_ARTIFACT --network mainnet
cd $UP || exit 1
exit 0
