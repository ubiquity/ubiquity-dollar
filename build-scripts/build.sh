#!/bin/bash
cd ./contracts || echo "ERROR: ./contracts/ doesn't exist?"
DEPLOYMENT_ARTIFACT=fixtures/full-deployment.json
yarn
yarn build
rm -f ../$DEPLOYMENT_ARTIFACT
yarn hardhat export --export ../$DEPLOYMENT_ARTIFACT --network mainnet
cd ..
yarn prettier --write $DEPLOYMENT_ARTIFACT
exit 0
