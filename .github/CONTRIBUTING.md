# Contributing
- We welcome everybody to participate in improving the codebase.
- We offer financial incentives for solved issues.
- Please learn how to contribute via the DevPool [here](https://dao.ubq.fi/devpool).

### Coding Styleguide

- We use camelCase for identifiers (variable, function, method names) do not use snake_case
- `NFT` should be `Nft` in identifers e.g. `creditNft`
- Do not refer to token symbols directly in identifiers, instead write the intent of the token. We have the ability to update the names of the tokens (as we already have done on Ethereum mainnet) which leads to confusion.
  - `uAD` ⮕ `dollar`
  - `uCR` ⮕ `credit`
  - `uCR-NFT` ⮕ `creditNft`
  - `UBQ` ⮕ `governance`

- We generally should not use "Ubiquity" in identifers and filenames. This is the Ubiquity Dollar repository so Ubiquity is implied.
  - The exception is when we are working in third party contexts, for example the Curve (3pool) metapool related code, it is good to write ubiquityDollar because the other assets in the pool are USDC, USDT and DAI (other types of dollars!)

#### Contract Renames

- We rebranded "Bonding" to "Staking" to disambiguate our bonds (e.g. Chicken Bonds) branding.
- We rebranded "Debts" to "Credits" because it has a positive connotation for the users.
- We rebranded "Ubiquity Algorithmic Dollar" to "Ubiquity Dollar" because the term "algorithmic" is contentious in this context after Luna.
- Filenames should be in kebab-case for example (note as of writing this we still have to fix this):
  - credit-nft-manager.sol
  - credit-nft-redemption-calculator.sol
  - credit-nft.sol
  - credit-redemption-calculator.sol
  - credit-token.sol
  - dollar-manager.sol
  - dollar-mint-calculator.sol
  - dollar-mint-excess.sol
  - dollar-token.sol
  - dollar3pool-oracle.sol
  - erc1155-ubiquity.sol
  - erc20-ubiquity.sol
  - formulas.sol 
  - governance-token.sol
  - masterchef-ubiquity.sol
  - staking-formulas.sol
  - staking-token.sol
  - staking.sol
  - transfer-hooks/dollar3pool.sol
