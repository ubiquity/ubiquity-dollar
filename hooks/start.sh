#!/bin/bash

if [ -f ./contracts/.env ]
then
  export $(cat ./contracts/.env | sed 's/#.*//g' | xargs)
else
  echo "Please add a .env inside the contracts folder."
  exit 1
fi
rm -f ./frontend/src/uad-contracts-deployment.json
cd ./contracts || echo "ERROR: ./contracts/ doesn't exist?"

yarn && yarn compile
kill $(lsof -t -i:8545) || true
yarn hardhat node --fork https://eth-mainnet.alchemyapi.io/v2/$ALCHEMY_API_KEY --fork-block-number 12150000 --show-accounts --export-all tmp-uad-contracts-deployment.json > ../local.node.log 2>&1 &
sleep 10
while : ; do
    [[ -f "tmp-uad-contracts-deployment.json" ]] && break
    echo "Pausing until uad-contracts-deployment.json exists."
    sleep 5
done
node ../hooks/process-deployment.js ./tmp-uad-contracts-deployment.json ../frontend/src/uad-contracts-deployment.json
rm -f ./tmp-uad-contracts-deployment.json
exit 0