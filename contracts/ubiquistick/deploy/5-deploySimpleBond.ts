import type { SimpleBond } from "../types/SimpleBond";
import type { HardhatRuntimeEnvironment } from "hardhat/types";

const deploySimpleBond = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, network, ethers } = hre;
  const { deploy } = deployments;
  const { provider, BigNumber } = ethers;
  const { deployer, treasury } = await ethers.getNamedSigners();

  const uARDeployment = await deployments.get("UAR");

  const vestingBlocks = 32300; // about 5 days
  const allowance = BigNumber.from(10).pow(32);

  const deploySimpleBond = await deploy("SimpleBond", {
    from: deployer.address,
    args: [uARDeployment.address, vestingBlocks, treasury.address],
    log: true,
  });

  if (deploySimpleBond.newlyDeployed) {
    const theUbiquityStick = await ethers.getContract("TheUbiquityStick");
    const simpleBond = new ethers.Contract(deploySimpleBond.address, deploySimpleBond.abi, deployer) as SimpleBond;
    await simpleBond.setSticker(theUbiquityStick.address);

    if (network.name === "mainnet") {
      console.log("Have to allow MINTER_ROLE to SimpleBond");
      console.log("Have to set infinite allowance to SimpleBond");
    } else {
      // Transfer ownership of uAR Token to SimpleBond contract in order to Mint it
      const uARContract = new ethers.Contract(uARDeployment.address, uARDeployment.abi, provider);
      await (await uARContract.connect(deployer).transferOwnership(deploySimpleBond.address)).wait();

      // Set allowance for SimpleBond to spend treasury money
      await uARContract.connect(treasury).increaseAllowance(deploySimpleBond.address, allowance);
    }
  }
};
deploySimpleBond.tags = ["SimpleBond"];
deploySimpleBond.dependencies = ["Tokens", "TheUbiquityStick"];
deploySimpleBond.runAtTheEnd = () => console.log("END");

export default deploySimpleBond;
