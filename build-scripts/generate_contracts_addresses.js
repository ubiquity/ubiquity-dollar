const fs = require("fs");

function getContractsAddressesFor(directory) {
  const chains = {};
  const deploymentsPath = `${__dirname}/../contracts/${directory}/deployments`;
  const chainsDirectories = fs.readdirSync(deploymentsPath);
  chainsDirectories.forEach((chainDirectory) => {
    const chainDeploymentPath = `${deploymentsPath}/${chainDirectory}`;
    const id = fs.readFileSync(`${chainDeploymentPath}/.chainId`);

    chains[id] = {};
    fs.readdirSync(chainDeploymentPath).forEach((file) => {
      if (file.endsWith(".json")) {
        const contractDeployment = JSON.parse(fs.readFileSync(`${chainDeploymentPath}/${file}`));
        const contractName = file.replace(/\.json$/, "");
        chains[id][contractName] = contractDeployment.address;
      }
    });
  });
  return chains;
}

function generateAddressesFile(directory) {
  const addresses = getContractsAddressesFor(directory);
  fs.writeFileSync(`${__dirname}/../fixtures/contracts-addresses/${directory}.json`, JSON.stringify(addresses, null, 2));
}

generateAddressesFile("dollar");
generateAddressesFile("ubiquistick");
