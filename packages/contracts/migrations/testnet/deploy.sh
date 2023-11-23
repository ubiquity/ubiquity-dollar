#!/bin/bash

# load env variables
source .env

# Deploy001_Diamond_Dollar (deploys Diamond and Dollar contracts)
forge script migrations/testnet/Deploy001_Diamond_Dollar.s.sol:Deploy001_Diamond_Dollar --rpc-url $RPC_URL --broadcast -vvvv

# Deploy002_Governance (deploys Governance token)
forge script migrations/testnet/Deploy002_Governance.s.sol:Deploy002_Governance --rpc-url $RPC_URL --broadcast -vvvv
