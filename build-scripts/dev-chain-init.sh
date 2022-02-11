#!/usr/bin/env bash

# first run node from ubiquistick
# then run faucet from uad-contracts
# restart faucet on fail

# hardhat node must first instantiate in a seperate process, which takes 10-15 seconds on my machine
# only after the node is ready then this faucet can run successfully

assistant() {

    # while
    nc -z 127.0.0.1 8545
    # ; do yarn hardhat faucet --network localhost; done
    if [ $? -eq 0 ]; then
        echo "Faucet szn"
        yarn hardhat faucet --network localhost
    else
        echo
        echo "FAIL - retrying faucet in 10 seconds..."
        echo
        sleep 10
        assistant "$1"
    fi
}

cd contracts/dollar || exit 1
assistant &

cd ../ubiquistick || exit 1
yarn hardhat node --fork-block-number 14044209
