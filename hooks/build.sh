#!/bin/bash

# SPINNER FUNCTIONS

spinnerChar="⠁⠂⠄⡀⢀⠠⠐⠈"
spinnerIndex=0
spinnerSTART() {
  printf "\b${spinnerChar:spinnerIndex++:1}"
  ((spinnerIndex == ${#spinnerChar})) && spinnerIndex=0
}
spinnerSTOP() {
  printf "\r%s\n" "$@"
}

if [ -f ./contracts/.env ]; then
  source ./contracts/.env
else
  echo "Please add a .env inside the contracts folder."
  exit 1
fi
rm -f ./frontend/src/uad-contracts-deployment.json
cd ./contracts || echo "ERROR: ./contracts/ doesn't exist?"
# yarn install
yarn compile
kill $(lsof -t -i:8545) || true
yarn hardhat node --fork https://eth-mainnet.alchemyapi.io/v2/$ALCHEMY_API_KEY --fork-block-number 12150000 --show-accounts --export-all tmp-uad-contracts-deployment.json >../local.node.log 2>&1 &
sleep 10
echo "Pausing until uad-contracts-deployment.json exists."
while :; do
  spinnerSTART
  [[ -f "tmp-uad-contracts-deployment.json" ]] && break
  sleep .06
done
spinnerSTOP

node ../hooks/process-deployment.js ./tmp-uad-contracts-deployment.json ../frontend/src/uad-contracts-deployment.json
rm -f ./tmp-uad-contracts-deployment.json

cd ..
cp -r ./contracts/* ./frontend/contracts # copy artifacts to be accessible by frontend

exit 0
