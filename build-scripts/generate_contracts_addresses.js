/* eslint-disable @typescript-eslint/no-var-requires */

generateAddressesFile("dollar");
generateAddressesFile("ubiquistick");

//
//
//

const fs = require("fs");
const path = require("path");

function getContractsAddressesFor(directory) {
  const directoryContractsNames = [];
  const chains = {};
  const deploymentsPath = path.join(__dirname, "..", "contracts", directory, "deployments");
  const chainsDirectories = fs.readdirSync(deploymentsPath);
  chainsDirectories.forEach(_processDirectory(deploymentsPath, chains, directoryContractsNames));
  return chains;
}

function _processDirectory(deploymentsPath, chains, directoryContractsNames) {
  return function processDirectory(chainDirectory) {
    const chainDeploymentPath = path.join(deploymentsPath, chainDirectory);
    const pathToChainId = path.join(chainDeploymentPath, ".chainId");
    const id = fs.readFileSync(pathToChainId, "utf-8");
    chains[id] = {};
    fs.readdirSync(chainDeploymentPath).forEach(_processDeployment(chainDeploymentPath, directoryContractsNames, chains, id));
    for (let chainId in chains) {
      directoryContractsNames.forEach((contractName) => {
        if (!chains[chainId][contractName]) {
          chains[chainId][contractName] = "";
        }
      });
    }
  };
}

function _processDeployment(chainDeploymentPath, directoryContractsNames, chains, id) {
  return function processDeployment(file) {
    if (file.endsWith(".json")) {
      const filePath = path.join(chainDeploymentPath, file);
      const buffer = fs.readFileSync(filePath, "utf-8");
      const contractDeployment = JSON.parse(buffer);
      const contractName = file.replace(/\.json$/, "");
      if (directoryContractsNames.indexOf(contractName) === -1) {
        directoryContractsNames.push(contractName);
      }
      chains[id][contractName] = contractDeployment.address;
    }
  };
}

function generateAddressesFile(directory) {
  const addresses = getContractsAddressesFor(directory);
  const pathToJson = path.join(__dirname, "..", "fixtures", "contracts-addresses", directory.concat(".json"));
  fs.writeFileSync(pathToJson, JSON.stringify(addresses, null, 2));
}
