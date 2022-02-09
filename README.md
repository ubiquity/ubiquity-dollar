# Ubiquity Dollar

## Setup

```bash
git clone https://github.com/ubiquity/uad-ui
cd uad-ui
git checkout launch-party
yarn
yarn contracts:init
# Fill the .env file on contracts and the-ubiquity-stick
# It’s the same .env except the-ubiquity-stick requires # DEPLOYER_PRIVATE_KEY (export it from Metamask) because # the hardhat.config.ts works differently from the contracts repo
yarn contracts:build
yarn contracts:node (this keeps running)
yarn contracts:faucet   # (in another terminal after the node is running)
yarn next:dev
```

https://github.com/ubiquity/uad-ui/issues/78
