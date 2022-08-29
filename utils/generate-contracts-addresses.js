/* eslint-disable @typescript-eslint/no-var-requires */

const fs = require("fs");
const path = require("path");

generateAddressesFile("dollar");
generateAddressesFile("ubiquistick");

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
    const chainId = fs.readFileSync(pathToChainId, "utf-8");
    chains[chainId] = {};

    fs.readdirSync(chainDeploymentPath)
      .filter((fileName) => fileName.endsWith(".json"))
      .forEach(_processDeployment(chainDeploymentPath, directoryContractsNames, chains, chainId));
  };
}

function _processDeployment(chainDeploymentPath, directoryContractsNames, chains, chainId) {
  return function processDeployment(fileName) {
    const filePath = path.join(chainDeploymentPath, fileName);
    const buffer = fs.readFileSync(filePath, "utf-8");
    const contractDeployment = JSON.parse(buffer);
    const contractName = fileName.replace(/\.json$/, "");
    if (!directoryContractsNames.includes(contractName)) {
      directoryContractsNames.push(contractName);
    }
    chains[chainId][contractName] = contractDeployment.address;
  };
}

function generateAddressesFile(directory) {
  const addresses = getContractsAddressesFor(directory);

  const pathToDir = path.join(__dirname, "..", "fixtures", "contracts-addresses");
  fs.mkdirSync(pathToDir, { recursive: true });

  const pathToJson = path.join(pathToDir, directory.concat(".json"));
  fs.writeFileSync(pathToJson, JSON.stringify(addresses, null, 2));
}
