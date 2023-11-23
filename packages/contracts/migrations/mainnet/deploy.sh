#!/bin/bash

# load env variables
source .env

# Deploy001_Diamond_Dollar (deploys Diamond and Dollar contracts)
forge script migrations/mainnet/Deploy001_Diamond_Dollar.s.sol:Deploy001_Diamond_Dollar --rpc-url $RPC_URL --broadcast -vvvv

# Deploy002_Governance (use already deployed Governance token)
forge script migrations/mainnet/Deploy002_Governance.s.sol:Deploy002_Governance --rpc-url $RPC_URL --broadcast -vvvv
