#!/bin/bash

# load env variables
source .env

# Deploy001_Diamond_Dollar_Governance (deploys Diamond, Dollar and Governance related contracts)
forge script migrations/development/Deploy001_Diamond_Dollar_Governance.s.sol:Deploy001_Diamond_Dollar_Governance --rpc-url $RPC_URL --broadcast -vvvv

# extract diamond contract address from the latest broadcast logs (to make it available for future migrations)
BROADCAST_LOGS=$(cat $(pwd)/broadcast/Deploy001_Diamond_Dollar_Governance.s.sol/31337/run-latest.json)
export DIAMOND_ADDRESS=$(echo $BROADCAST_LOGS | jq --raw-output '.transactions[] | select (.contractName == "Diamond" and .transactionType == "CREATE") | .contractAddress')

# Deploy002_Staking (deploys `StakingFacet`)
forge script migrations/development/Deploy002_Staking.s.sol:Deploy002_Staking --rpc-url $RPC_URL --broadcast -vvvv
