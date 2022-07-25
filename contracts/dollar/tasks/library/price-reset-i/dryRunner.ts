import { Signer } from "ethers";
import { TaskArgs } from "../price-reset-i";

const ADMIN_WALLET = "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd";

interface Params {
  resetFork: (blockNumber: number) => Promise<void>;
  taskArgs: TaskArgs;
  network: any;
  ethers: any;
}

export async function dryRunner({ resetFork, taskArgs, network, ethers }: Params) {
  await resetFork(taskArgs.blockHeight);
  const impersonate = async (account: string): Promise<Signer> => {
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [account],
    });
    return ethers.provider.getSigner(account);
  };
  const admin = await impersonate(ADMIN_WALLET);
  return { adminAdr: ADMIN_WALLET, admin };
}
