# !/bin/bash

# rust setup
echo "Download and Install rustup"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source /opt/buildhome/.bashrc
# foundry setup
echo "Build foundry from the github source code"
cargo install --git https://github.com/foundry-rs/foundry foundry-cli anvil --bins --locked
# build workspace
yarn build:all
