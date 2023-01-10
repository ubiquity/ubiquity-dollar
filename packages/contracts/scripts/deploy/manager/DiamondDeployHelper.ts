import { ethers } from "ethers";
import path from "path";

export const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 };

export async function getSelectorsFromFacet(contractName: string, artifactFolderPath = "../../../out") {
    const contractFilePath = path.join(artifactFolderPath, `${contractName}.sol`, `${contractName}.json`);
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

    return selectors;
}

export function getContractInstance(contractName: string, account?: any, artifactFolderPath = "../../../out") {
    const contractFilePath = path.join(artifactFolderPath, `${contractName}.sol`, `${contractName}.json`);
    const contractArtifact = require(contractFilePath);
    const abi = contractArtifact.abi;
    const bytecode = contractArtifact.bytecode;
    let target;
    if (account) {
        target = new ethers.ContractFactory(abi, bytecode, account);
    } else {
        target = new ethers.ContractFactory(abi, bytecode);
    }

    return target;
}