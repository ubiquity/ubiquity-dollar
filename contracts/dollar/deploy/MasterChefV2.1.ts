import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const MANAGER_ADDRESS = "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98";
const ALREADY_MIGRATED = [
  "0x89eae71b865a2a39cba62060ab1b40bbffae5b0d",
  "0x4007ce2083c7f3e18097aeb3a39bb8ec149a341d",
  "0x7c76f4db70b7e2177de10de3e2f668dadcd11108",
  "0x0000ce08fa224696a819877070bf378e8b131acf",
  "0xa53a6fe2d8ad977ad926c485343ba39f32d3a3f6",
  "0xcefd0e73cc48b0b9d4c8683e52b7d7396600abb2",
];
const AMOUNTS = [
  "1301000000000000000",
  "74603879373206500005186",
  "44739174270101943975392",
  "1480607760433248019987",
  "9351040526163838324896",
  "8991650309086743220575",
];
const IDS = [1, 2, 3, 4, 5, 6];

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, ethers } = hre;
  const [admin] = await ethers.getSigners();
  deployments.log("admin address :", admin.address);

  const opts = {
    from: admin.address,
    log: true,
  };
  const masterchef = await deployments.deploy("MasterChefV2", {
    args: [MANAGER_ADDRESS, ALREADY_MIGRATED, AMOUNTS, IDS],
    ...opts,
  });
  deployments.log("ExcessDollarsDistributor deployed at:", masterchef.address);
};
export default func;
func.tags = ["MasterChefV2.1"];
