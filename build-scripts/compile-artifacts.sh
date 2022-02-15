#!/usr/bin/env bash
cd "$(npm root)"
cd ..
cd ./contracts/dollar || echo "ERROR: ./contracts/dollar/ doesn't exist?"

UP=../
DEPLOYMENT_ARTIFACT=fixtures/ubiquity-dollar-deployment.json

yarn install
yarn build

rm -f $UP$DEPLOYMENT_ARTIFACT
yarn hardhat export --export $UP$DEPLOYMENT_ARTIFACT --network mainnet
cd $UP || exit 1
