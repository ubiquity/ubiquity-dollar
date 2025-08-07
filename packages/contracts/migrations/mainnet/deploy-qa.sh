#!/bin/bash

# load env variables
source .env

UBQ_ETH_ADDRESS=0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd;

# pretend we're `ubq.eth` address
cast rpc anvil_impersonateAccount $UBQ_ETH_ADDRESS;

# Deploy001_Diamond_Dollar_Governance (deploys Diamond, Dollar and Governance related contracts)
forge script migrations/mainnet/Deploy001_Diamond_Dollar_Governance.s.sol:Deploy001_Diamond_Dollar_Governance --rpc-url $RPC_URL --broadcast -vvvv

# Deploy002_Staking (deploys `StakingFacet`)
forge script migrations/mainnet/Deploy002_Staking.s.sol:Deploy002_Staking --rpc-url $RPC_URL --broadcast -vvvv --unlocked

# stop pretending we're `ubq.eth` address
cast rpc anvil_stopImpersonatingAccount $UBQ_ETH_ADDRESS;
