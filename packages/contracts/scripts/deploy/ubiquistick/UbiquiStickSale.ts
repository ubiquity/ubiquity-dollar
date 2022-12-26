import { CMDType, deployments, Networks } from "../../shared";
import { create, getENV } from "../create";
import { ethers } from "ethers";

const ubiquiStickSaleHandler = async (args: CMDType) => {
  const env = await getENV();
  const contractInstance = "src/ubiquistick/UbiquiStickSale.sol:UbiquiStickSale";
  const treasury = args.treasury;

  const chainId = Networks[args.network] ?? undefined;
  if (!chainId) {
    throw new Error(`Unsupported network: ${args.network} Please configure it out first`);
  }

  const { result, stderr } = await create({ ...env, name: args.task, network: args.network, contractInstance, constructorArguments: [] });

  const signer = new ethers.Wallet(env.privateKey, new ethers.providers.JsonRpcProvider(env.rpcUrl));
  const ubiquiStickSaleAddress = result!.deployedTo;
  const ubiquiStickDeployments = await deployments(chainId.toString(), "UbiquiStick");
  const ubiquiStickContract = new ethers.Contract(ubiquiStickDeployments.address, ubiquiStickDeployments.abi, signer);
  console.log("Granting minter role to UbiquiStickSale contract...");
  let tx = await ubiquiStickContract.setMinter(ubiquiStickSaleAddress);
  let receipt = await tx.wait();
  console.log("Granting minter role to UbiquiStickSale contract done!!!, hash: ", receipt.transactionHash);

  console.log("Setting up funds address and token contract...");
  const ubiquiStickSaleDeployments = await deployments(chainId.toString(), "UbiquiStickSale");
  const ubiquiStickSaleContract = new ethers.Contract(ubiquiStickSaleAddress, ubiquiStickSaleDeployments.abi, signer);
  tx = await ubiquiStickSaleContract.setFundsAddress(treasury);
  console.log("Setting funds address tx mined, tx: ", tx);
  receipt = await tx.wait();
  console.log("Setting funds address done, hash: ", receipt.transactionHash);

  tx = await ubiquiStickSaleContract.setTokenContract(ubiquiStickDeployments.address);
  console.log("Setting token address tx mined, tx: ", tx);
  receipt = await tx.wait();
  console.log("Setting token address done, hash: ", receipt.transactionHash);
  return !stderr ? "succeeded" : "failed";
};
export default ubiquiStickSaleHandler;
