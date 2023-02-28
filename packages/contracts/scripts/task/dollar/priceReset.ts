import { OptionDefinition } from "command-line-args";

import { A_PRECISION, deployments, DEPLOYMENT_OVERRIDES, get_burn_lp_amount, Networks, TaskFuncParam, pressAnyKey } from "../../shared";
import { ethers, BigNumber } from "ethers";
import { abi as metaPoolABI } from "../../../out/IMetaPool.sol/IMetaPool.json";

export const optionDefinitions: OptionDefinition[] = [
  { name: "task", defaultOption: true },
  { name: "price", alias: "p", type: Number },
  { name: "dryrun", alias: "d", type: Boolean },
  { name: "network", alias: "n", type: String },
];

const func = async (params: TaskFuncParam) => {
  const { env, args } = params;
  const { price, network } = args;

  const chainId = Networks[network] ?? undefined;
  if (!chainId) {
    throw new Error(`Unsupported network: ${network} Please configure it out first`);
  }

  const signer = new ethers.Wallet(env.privateKey, new ethers.providers.JsonRpcProvider(env.rpcUrl));
  const OVERRIDE_PARAMS = DEPLOYMENT_OVERRIDES[network];
  // cspell: disable-next-line
  const managerDeployments = await deployments(chainId.toString(), "UbiquityAlgorithmicDollarManager");
  // cspell: disable-next-line
  const managerAddress = managerDeployments.address || OVERRIDE_PARAMS.UbiquityAlgorithmicDollarManagerAddress;
  const managerContract = new ethers.Contract(managerAddress, managerDeployments.abi, signer);
  const curve3CrvTokenAddress = OVERRIDE_PARAMS?.curve3CrvToken;
  if (!curve3CrvTokenAddress) {
    throw new Error(`Not configured 3CRV token address`);
  }
  const stakingAddr = await managerContract.stakingContractAddress();
  const stakingDeployments = await deployments(chainId.toString(), "Staking");
  const stakingContract = new ethers.Contract(stakingAddr, stakingDeployments.abi, signer);

  const metaPoolAddr = await managerContract.stableSwapMetaPoolAddress();
  const metaPoolContract = new ethers.Contract(metaPoolAddr, metaPoolABI, signer);

  const metaPoolA = await metaPoolContract.A();
  const fee = await metaPoolContract.fee();
  const balances = await metaPoolContract.get_balances();
  const totalSupply = await metaPoolContract.totalSupply();

  const uADBalanceOfMetaPool = balances[0];
  const curve3CRVBalanceOfMetaPool = balances[1];
  const impactedPrice = Math.floor(price * 10);
  const expectedUADAmount = curve3CRVBalanceOfMetaPool.div(impactedPrice).mul(10);
  console.log({
    stakingAddr,
    metaPoolAddr,
    uADBalance: uADBalanceOfMetaPool.toString(),
    curve3CRVBalance: curve3CRVBalanceOfMetaPool.toString(),
    expectedUADAmount: expectedUADAmount.toString(),
    impactedPrice,
  });
  if (expectedUADAmount.gt(uADBalanceOfMetaPool)) {
    throw new Error(
      `We don't currently support to make the price lower. price: ${price}, uADAmount: ${ethers.utils.formatEther(
        uADBalanceOfMetaPool
      )}, expectedUAD: ${ethers.utils.formatEther(expectedUADAmount)}`
    );
  }

  console.log(`Calculating burn amount to reset price...`);

  const amp = metaPoolA.mul(A_PRECISION);
  const base_pool = OVERRIDE_PARAMS.curve3CrvBasePool;
  const curveBasePool = new ethers.Contract(base_pool, metaPoolABI, signer);
  const virtual_price = await curveBasePool.get_virtual_price();
  const amounts: BigNumber[] = [uADBalanceOfMetaPool.sub(expectedUADAmount), BigNumber.from("0")];

  console.log({
    amp: amp.toString(),
    virtual_price: virtual_price.toString(),
    fee: fee.toString(),
    balances: balances.map((balance) => balance.toString()),
    totalSupply: totalSupply.toString(),
    amounts: amounts.map((amount) => amount.toString()),
  });

  const burn_lp_amount = get_burn_lp_amount({ amp, virtual_price, fee, balances, totalSupply, amounts });

  const available_lp_amount = await metaPoolContract.balanceOf(stakingAddr);
  console.log({
    burn_lp_amount: burn_lp_amount.toString(),
    available_lp_amount: available_lp_amount.toString(),
  });

  if (available_lp_amount.lt(burn_lp_amount)) {
    throw new Error(`Not enough lp amount for burn in staking contract, needed: ${burn_lp_amount.toString()}, available: ${available_lp_amount.toString()}`);
  }

  await pressAnyKey("Press any key if you are sure you want to continue ...");
  const tx = await stakingContract.uADPriceReset(burn_lp_amount);
  console.log(`tx mined! hash: ${tx.hash}`);
  await tx.wait(1);
  console.log(`price reset tx confirmed!`);

  const new_balances = await metaPoolContract.get_balances();
  console.log({
    new_balances: new_balances.map((balance) => balance.toString()),
  });

  return "succeeded";
};
export default func;
