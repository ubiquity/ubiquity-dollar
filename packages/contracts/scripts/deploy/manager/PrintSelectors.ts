import { ethers } from "ethers";
import path from "path";

const args = process.argv.slice(2);

if (args.length != 1) {
  console.log(`please supply the correct parameters:
    facetName
  `);
  process.exit(1);
}

async function printSelectors(contractName: string, artifactFolderPath = "../../../out") {
  const contractFilePath = path.join(
    artifactFolderPath,
    `${contractName}.sol`,
    `${contractName}.json`
  );
  const contractArtifact = require(contractFilePath);
  const abi = contractArtifact.abi;
  const bytecode = contractArtifact.bytecode;
  const target = new ethers.ContractFactory(abi, bytecode);
  const signatures = Object.keys(target.interface.functions);

  const selectors = signatures.reduce((acc, val) => {
    if (val !== "init(bytes)") {
      // @ts-ignore
      acc.push(target.interface.getSighash(val));
    }
    return acc;
  }, []);

  console.log(`Selectors of ${contractName}: `, selectors);
  console.log(`Length: `, selectors.length);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
printSelectors(args[0], args[1])
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
