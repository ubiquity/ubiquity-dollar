import { globSync } from "glob";
import fs from "fs";
import path from "path";
import readline from "readline";

const searchContracts = async (directory) => {
  const contracts = await globSync(`${directory}/**/*.{sol,t.sol}`);
  return contracts.map((contract) => ({
    path: contract.replace(directory, ""),
    name: contract.replace(/^.*[\\/]/, "").replace(/\.[^.]+$/, ""),
  }));
};

const updateFoundryToml = async () => {
  const currentDirectory = process.cwd();
  const foundryTomlPath = path.join(currentDirectory, "foundry.toml");
  const contractsDirectoryPath = path.join(currentDirectory, "src", "dollar");

  try {
    // Read the contents of foundry.toml
    let foundryTomlContent = fs.readFileSync(foundryTomlPath, "utf-8");

    // List all the contracts
    const contractsArray = await searchContracts(contractsDirectoryPath);

    // Choose contracts to add
    const selectedContracts = [];
    let shouldContinue = true;
    while (shouldContinue) {
      const contractIndex = await promptContractSelection(contractsArray);
      if (contractIndex !== -1) {
        const selectedContract = contractsArray[contractIndex];
        selectedContracts.push(selectedContract);
        console.log(`Contract '${selectedContract.name}' selected to be added to foundry.toml.`);
      } else {
        shouldContinue = false;
      }
    }

    // Generate the contracts section content
    const contractsSectionContent = generateContractsSectionContent(selectedContracts);

    // Update the contracts section in foundry.toml
    foundryTomlContent = updateContractsSection(foundryTomlContent, contractsSectionContent);

    // Write the updated content back to foundry.toml
    fs.writeFileSync(foundryTomlPath, foundryTomlContent);

    console.log("foundry.toml updated successfully.");
  } catch (error) {
    console.error("Error updating foundry.toml:", error);
  }
};

const promptContractSelection = (contractsArray) => {
  return new Promise((resolve) => {
    const rd = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
    });

    const printContractsList = () => {
      console.log("Contracts:");
      contractsArray.forEach((contract, index) => {
        console.log(`${index + 1}. ${contract.name}`);
      });
    };

    let selectedContract;

    const handleAnswer = (answer) => {
      rd.close();
      const selectedContractIndex = parseInt(answer) - 1;

      if (!isNaN(selectedContractIndex) && selectedContractIndex >= 0 && selectedContractIndex < contractsArray.length) {
        selectedContract = contractsArray[selectedContractIndex];
        resolve(selectedContractIndex);
      } else {
        resolve(-1);
      }
    };
    printContractsList();
    rd.question("Enter the number of the contract to add or press Enter to finish: ", (answer) => {
      handleAnswer(answer);

      if (selectedContract) {
        console.log(`Contract '${selectedContract.name}' added to the selection.`);
      }
    });
  });
};

const generateContractsSectionContent = (selectedContracts) => {
  const contractsEntries = selectedContracts.map((contract) => `"${path.join("src", "dollar", contract.path)}" = ["${contract.name}"]`);
  return `contracts = { ${contractsEntries.join(", ")} }`;
};

const updateContractsSection = (foundryTomlContent, contractsSectionContent) => {
  const regex = /contracts\s*=\s*\{([^}]+)\}/;
  const match = regex.exec(foundryTomlContent);

  if (match) {
    const updatedContent = foundryTomlContent.replace(match[0], contractsSectionContent);
    const modifiedContent = removeExtraSpace(updatedContent);
    return modifiedContent;
  } else {
    const modelCheckerSectionRegex = /\[profile\.default\.model_checker\]/;
    const modelCheckerMatch = modelCheckerSectionRegex.exec(foundryTomlContent);

    if (modelCheckerMatch) {
      const modelCheckerSectionStartIndex = modelCheckerMatch.index;
      const insertionIndex = foundryTomlContent.indexOf("\n", modelCheckerSectionStartIndex);
      return foundryTomlContent.slice(0, insertionIndex) + `\n\n${contractsSectionContent}\n` + foundryTomlContent.slice(insertionIndex);
    } else {
      return foundryTomlContent + `\n\n${contractsSectionContent}\n`;
    }
  }
};

const removeExtraSpace = (content) => {
  return content.replace(/\n\n+/g, "\n\n").trim() + "\n";
};

updateFoundryToml();
