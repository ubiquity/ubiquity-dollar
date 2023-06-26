import fs from "fs";
import path from "path";

const updateFoundryToml = async () => {
  const currentDirectory = process.cwd();
  const foundryTomlPath = path.join(currentDirectory, "foundry.toml");

  try {
    // Read the contents of foundry.toml
    let foundryTomlContent = fs.readFileSync(foundryTomlPath, "utf-8");

    // Check if the model_checker section exists in foundry.toml
    const regex = /\[profile\.default\.model_checker\]/;
    const match = regex.exec(foundryTomlContent);

    if (match) {
      console.log("model_checker section already exists in foundry.toml.");
      return;
    }

    // Generate the model_checker section content
    const modelCheckerSectionContent = generateModelCheckerSectionContent();

    // Update foundry.toml with the model_checker section
    foundryTomlContent = updateFoundryTomlContent(foundryTomlContent, modelCheckerSectionContent);

    // Write the updated content back to foundry.toml
    fs.writeFileSync(foundryTomlPath, foundryTomlContent);

    console.log("foundry.toml updated successfully.");
  } catch (error) {
    console.error("Error updating foundry.toml:", error);
  }
};

const generateModelCheckerSectionContent = (): string => {
  const modelCheckerSectionContent = `
[profile.SMT.model_checker]
contracts = { }
engine = 'chc'
solvers = ['z3']
show_unproved = true
timeout = 0
targets = [
  'assert',
  'constantCondition',
  'divByZero',
  'outOfBounds',
  'overflow',
  'popEmptyArray',
  'underflow',
  'balance',
]
`;
  return modelCheckerSectionContent.trim() + "\n";
};

const updateFoundryTomlContent = (foundryTomlContent: string, modelCheckerSectionContent: string): string => {
  const lastTwoLinesRegex = /.*\n.*\n.*$/s;
  const match = lastTwoLinesRegex.exec(foundryTomlContent);

  if (match) {
    const insertionIndex = match.index + match[0].length;
    return foundryTomlContent.slice(0, insertionIndex) + `\n${modelCheckerSectionContent}\n` + foundryTomlContent.slice(insertionIndex);
  } else {
    return foundryTomlContent + `\n\n${modelCheckerSectionContent}\n`;
  }
};

updateFoundryToml();
