#!/bin/bash

source .env

# Impersonates an account with high 3crv token balance
cast rpc anvil_impersonateAccount 0x72A916702BD97923E55D78ea5A3F413dEC7F7F85 -r http://localhost:8545

# Transfers tokens to default first account for Anvil
cast send 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490 0xa9059cbb000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb9226600000000000000000000000000000000000000000000021e19e0c9bab2400000 --from 0x72A916702BD97923E55D78ea5A3F413dEC7F7F85

# Ends account impersonation
cast rpc anvil_stopImpersonatingAccount 0x72A916702BD97923E55D78ea5A3F413dEC7F7F85 -r http://localhost:8545

# Deploys Protocol to Anvil Localchain
forge script scripts/deploy/dollar/solidityScripting/08_DevelopmentDeploy.s.sol:DevelopmentDeploy --fork-url http://localhost:8545 --broadcast
