import { addressBook } from ".";
import { abi as tokenABI } from "../../../../artifacts/contracts/UbiquityGovernance.sol/UbiquityGovernance.json";
import { UbiquityGovernance } from "../../../../artifacts/types/UbiquityGovernance";
import { Account, Balance, EthersAndNetwork } from "./impersonate-types";
import { HardhatRpcMethods } from "./rpc-methods/hardhat-rpc-methods";

const account = {
  token: new Account(),
  sender: new Account(),
  receiver: new Account(),
} as { [key in keyof typeof addressBook]: Account };

export async function impersonate(taskArgs: { [key in keyof typeof addressBook]: string }, { ethers, network }: EthersAndNetwork) {
  console.log(`impersonating ${taskArgs.sender}`);
  await network.provider.request({ method: "hardhat_impersonateAccount" as HardhatRpcMethods, params: [taskArgs.sender] }); // impersonate

  // initialize
  account.sender.signer = await ethers.getSigner(taskArgs.sender);
  account.receiver.signer = await ethers.getSigner(taskArgs.receiver);
  account.token.contract = new ethers.Contract(taskArgs.token, tokenABI, account.sender.signer);
  const tokenContractAsSender = account.token.contract.connect(account.sender.signer) as UbiquityGovernance;

  await printAllBalances();
  await doTheTransfer();
  await printAllBalances();

  async function getBalanceOf(address: string): Promise<Balance> {
    const bigNumber = await account.token.contract?.balanceOf(address);
    if (!bigNumber) {
      throw new Error(`balanceOf(${address}) returned null`);
    }
    return {
      bigNumber,
      decimal: bigNumber / 1e18,
    };
  }
  async function printAllBalances() {
    const balances = {
      [shortenAddress(taskArgs.sender)]: (account.sender.balance = await getBalanceOf(taskArgs.sender)).decimal,
      [shortenAddress(taskArgs.receiver)]: (account.receiver.balance = await getBalanceOf(taskArgs.receiver)).decimal,
      // [taskArgs.token]: (account.token.balance = await getBalanceOf(taskArgs.token)).decimal,
    };

    console.table(balances);
  }
  async function doTheTransfer() {
    const transferAmount = await getBalanceOf(taskArgs.sender);
    console.log(shortenAddress(taskArgs.sender), transferAmount.decimal, await tokenContractAsSender.symbol(), `=>`, shortenAddress(taskArgs.receiver));
    await tokenContractAsSender.transfer(taskArgs.receiver, transferAmount.bigNumber);
  }
}

function shortenAddress(address: string) {
  return address.slice(0, 6) + "..." + address.slice(-4);
}
