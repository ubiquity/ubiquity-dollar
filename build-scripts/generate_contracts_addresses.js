const fs = require("fs");

function getContractsAddressesFor(directory) {
  const directoryContractsNames = [];
  const chains = {};
  const deploymentsPath = `${__dirname}/../contracts/${directory}/deployments`;
  const chainsDirectories = fs.readdirSync(deploymentsPath);
  chainsDirectories.forEach((chainDirectory) => {
    const chainDeploymentPath = `${deploymentsPath}/${chainDirectory}`;
    const id = fs.readFileSync(`${chainDeploymentPath}/.chainId`);
    const contractsDirectories = fs.readdirSync(chainDeploymentPath);
    chains[id] = {};
    fs.readdirSync(chainDeploymentPath).forEach((file) => {
      if (file.endsWith(".json")) {
        const contractDeployment = JSON.parse(fs.readFileSync(`${chainDeploymentPath}/${file}`));
        const contractName = file.replace(/\.json$/, "");
        if (directoryContractsNames.indexOf(contractName) === -1) {
          directoryContractsNames.push(contractName);
        }
        chains[id][contractName] = contractDeployment.address;
      }
    });

    for (let chainId in chains) {
      directoryContractsNames.forEach((contractName) => {
        if (!chains[chainId][contractName]) {
          chains[chainId][contractName] = "";
        }
      });
    }
  });
  return chains;
}

function generateAddressesFile(directory) {
  const addresses = getContractsAddressesFor(directory);
  fs.writeFileSync(`${__dirname}/../fixtures/contracts-addresses/${directory}.json`, JSON.stringify(addresses, null, 2));
}

generateAddressesFile("dollar");
generateAddressesFile("ubiquistick");
