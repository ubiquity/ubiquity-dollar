const fs = require("fs");
const _ = require("lodash");
const path = require("path");

// adjust this to include the path(s) to your solidity files
const solidityFilePaths = [
  "packages/contracts/scripts/deploy/dollar/solidityScripting/00-constants-s.sol",
  "packages/contracts/scripts/deploy/dollar/solidityScripting/01-diamond-s.sol",
  "packages/contracts/scripts/deploy/dollar/solidityScripting/02-ubiquity-dollar-token-s.sol",
  "packages/contracts/scripts/deploy/dollar/solidityScripting/03-ubiquity-governance-token-s.sol",
  "packages/contracts/scripts/deploy/dollar/solidityScripting/04-ubiquity-credit-s.sol",
  "packages/contracts/scripts/deploy/dollar/solidityScripting/05-staking-share-s.sol",
  "packages/contracts/scripts/task/dollar/migrate-metapool-s.sol",
  "packages/contracts/src/dollar/diamond.sol",
  "packages/contracts/src/dollar/direct-governance-farmer.sol",
  "packages/contracts/src/dollar/core/credit-clock.sol",
  "packages/contracts/src/dollar/core/credit-nft.sol",
  "packages/contracts/src/dollar/core/erc-1155-ubiquity.sol",
  "packages/contracts/src/dollar/core/staking-share.sol",
  "packages/contracts/src/dollar/core/ubiquity-credit-token.sol",
  "packages/contracts/src/dollar/core/ubiquity-dollar-token.sol",
  "packages/contracts/src/dollar/core/ubiquity-governance-token.sol",
  "packages/contracts/src/dollar/facets/collectable-dust-facet.sol",
  "packages/contracts/src/dollar/facets/credit-nft-manager-facet.sol",
  "packages/contracts/src/dollar/facets/credit-nft-redemption-calculator-facet.sol",
  "packages/contracts/src/dollar/facets/credit-redemption-calculator-facet.sol",
  "packages/contracts/src/dollar/facets/diamond-loupe-facet.sol",
  "packages/contracts/src/dollar/facets/manager-facet.sol",
  "packages/contracts/src/dollar/interfaces/i-credit-nft-manager.sol",
  "packages/contracts/src/dollar/interfaces/i-credit-nft-redemption-calculator.sol",
  "packages/contracts/src/dollar/interfaces/i-credit-nft.sol",
  "packages/contracts/src/dollar/interfaces/i-dollar-mint-calculator.sol",
  "packages/contracts/src/dollar/interfaces/i-dollar-mint-excess.sol",
  "packages/contracts/src/dollar/interfaces/i-jar.sol",
  "packages/contracts/src/dollar/interfaces/i-master-chef.sol",
  "packages/contracts/src/dollar/interfaces/i-staking-share.sol",
  "packages/contracts/src/dollar/interfaces/i-sushi-master-chef.sol",
  "packages/contracts/src/dollar/interfaces/i-ubiquity-chef.sol",
  "packages/contracts/src/dollar/interfaces/i-ubiquity-dollar-manager.sol",
  "packages/contracts/src/dollar/interfaces/i-ubiquity-dollar-token.sol",
  "packages/contracts/src/dollar/interfaces/i-ubiquity-governance.sol",
  "packages/contracts/src/dollar/interfaces/ierc-20-ubiquity.sol",
  "packages/contracts/src/dollar/interfaces/ierc-1155-ubiquity.sol",
  "packages/contracts/src/dollar/libraries/constants.sol",
  "packages/contracts/src/dollar/libraries/lib-app-storage.sol",
  "packages/contracts/src/dollar/libraries/lib-bonding-curve.sol",
  "packages/contracts/src/dollar/libraries/lib-chef.sol",
  "packages/contracts/src/dollar/libraries/lib-collectable-dust.sol",
  "packages/contracts/src/dollar/libraries/lib-credit-nft-manager.sol",
  "packages/contracts/src/dollar/libraries/lib-credit-nft-redemption-calculator.sol",
  "packages/contracts/src/dollar/libraries/lib-credit-redemption-calculator.sol",
  "packages/contracts/src/dollar/libraries/lib-curve-dollar-incentive.sol",
  "packages/contracts/src/dollar/libraries/lib-diamond.sol",
  "packages/contracts/src/dollar/libraries/lib-dollar-mint-calculator.sol",
  "packages/contracts/src/dollar/libraries/lib-dollar-mint-excess.sol",
  "packages/contracts/src/dollar/libraries/lib-staking-formulas.sol",
  "packages/contracts/src/dollar/libraries/lib-staking.sol",
  "packages/contracts/src/dollar/libraries/lib-ubiquity-pool.sol",
  "packages/contracts/src/dollar/mocks/mock-bonding-share-v-2.sol",
  "packages/contracts/src/dollar/mocks/mock-credit-nft.sol",
  "packages/contracts/src/dollar/mocks/mock-credit-token.sol",
  "packages/contracts/src/dollar/mocks/mock-dollar-token.sol",
  "packages/contracts/src/dollar/mocks/mock-share-v-1.sol",
  "packages/contracts/src/dollar/mocks/mock-ubiquistick.sol",
  "packages/contracts/src/dollar/mocks/zozo-vault.sol",
  "packages/contracts/src/dollar/upgradeInitializers/diamond-init.sol",
  "packages/contracts/src/dollar/utils/collectable-dust.sol",
  "packages/contracts/src/ubiquistick/lp.sol",
  "packages/contracts/src/ubiquistick/mock-ub-qmanager.sol",
  "packages/contracts/src/ubiquistick/simple-bond.sol",
  "packages/contracts/src/ubiquistick/sushi-swap-pool.sol",
  "packages/contracts/src/ubiquistick/ubiqui-stick-sale.sol",
  "packages/contracts/src/ubiquistick/ubiqui-stick.sol",
  "packages/contracts/test/diamond/diamond-init-t.sol",
  "packages/contracts/test/diamond/diamond-test-setup.sol",
  "packages/contracts/test/diamond/diamond-test-t.sol",
  "packages/contracts/test/diamond/erc-20-ubiquity-dollar-test-t.sol",
  "packages/contracts/test/diamond/facets/access-control-facet-t.sol",
  "packages/contracts/test/diamond/facets/bonding-curve-facet-t.sol",
  "packages/contracts/test/diamond/facets/chef-facet-t.sol",
  "packages/contracts/test/diamond/facets/collectable-dust-facet-t.sol",
  "packages/contracts/test/diamond/facets/credit-nft-manager-facet-t.sol",
  "packages/contracts/test/diamond/facets/credit-nft-redemption-calculator-facet-t.sol",
  "packages/contracts/test/diamond/facets/credit-redemption-calculator-facet-t.sol",
  "packages/contracts/test/diamond/facets/curve-dollar-incentive-facet-t.sol",
  "packages/contracts/test/diamond/facets/dollar-mint-calculator-facet-t.sol",
  "packages/contracts/test/diamond/facets/dollar-mint-excess-facet-t.sol",
  "packages/contracts/test/diamond/facets/manager-facet-t.sol",
  "packages/contracts/test/diamond/facets/ownership-facet-t.sol",
  "packages/contracts/test/diamond/facets/staking-facet-t.sol",
  "packages/contracts/test/diamond/facets/staking-formulas-facet-t.sol",
  "packages/contracts/test/diamond/facets/twap-oracle-facet-t.sol",
  "packages/contracts/test/diamond/facets/ubiquity-pool-facet-t.sol",
  "packages/contracts/test/dollar/direct-governance-farmer-t.sol",
  "packages/contracts/test/dollar/core/credit-clock-t.sol",
  "packages/contracts/test/dollar/core/credit-nft-t.sol",
  "packages/contracts/test/dollar/core/staking-share-t.sol",
  "packages/contracts/test/dollar/core/ubiquity-credit-token-t.sol",
  "packages/contracts/test/dollar/core/ubiquity-dollar-token-t.sol",
  "packages/contracts/test/dollar/core/ubiquity-governance-token-t.sol",
  "packages/contracts/test/helpers/diamond-test-helper.sol",
  "packages/contracts/test/scripts/migrate-metapool-t.sol",
  "packages/contracts/test/ubiquistick/simple-bond-t.sol",
  "packages/contracts/test/ubiquistick/ubiqui-stick-sale-t.sol",
  "packages/contracts/test/ubiquistick/ubiqui-stick-t.sol",
];

solidityFilePaths.forEach((filePath) => {
  const data = fs.readFileSync(filePath, "utf8");

  const result = data.replace(/import\s+"([^"]*[A-Z][^"]*)";/g, (match, p1) => {
    const dir = path.dirname(p1);
    const base = path.basename(p1);
    const ext = path.extname(base);
    const nameWithoutExt = path.basename(base, ext);
    const kebabCaseName = _.kebabCase(nameWithoutExt);
    const newBase = `${kebabCaseName}${ext}`;
    const newImportPath = path.join(dir, newBase);
    return `import "${newImportPath}";`;
  });

  fs.writeFileSync(filePath, result, "utf8");
});
