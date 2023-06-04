import { ethers } from "hardhat";
import diamondContract from "../../packages/contracts/src/dollar/Diamond.sol";

async function main() {
  const diamondStorageSlot = ethers.utils.keccak256("diamond.standard.diamond.storage");

  // Deployed Diamond contract instance
  const diamond = await diamondContract.deployed();

  // Retrieve the diamond storage address from the contractOwner field
  const diamondStorageAddress = await diamond.contractOwner();

  // Access the diamond storage using the storage slot and storage address
  const diamondStorage = await ethers.provider.getStorageAt(diamondStorageAddress, diamondStorageSlot);
  console.log("Diamond Storage:", diamondStorage);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
