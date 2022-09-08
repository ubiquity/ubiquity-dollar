import { BondingV2 } from "../../../artifacts/types/BondingV2";
import { ERC20 } from "../../../artifacts/types/ERC20";
import { IMetaPool } from "../../../artifacts/types/IMetaPool";
import { UbiquityAlgorithmicDollar } from "../../../artifacts/types/UbiquityAlgorithmicDollar";
import { UbiquityAlgorithmicDollarManager } from "../../../artifacts/types/UbiquityAlgorithmicDollarManager";

export async function getAddresses({ getNamedAccounts, net, ethers }: { getNamedAccounts: any; net: any; ethers: any }) {
  let curve3CrvToken = "";
  ({ curve3CrvToken } = await getNamedAccounts());
  if (net.name === "hardhat") {
    console.warn("You are running the task with Hardhat network");
  }
  console.log(`net chainId: ${net.chainId}  `);
  const manager = (await ethers.getContractAt(
    "UbiquityAlgorithmicDollarManager",
    "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98"
  )) as UbiquityAlgorithmicDollarManager;
  const uADAdr = await manager.dollarTokenAddress();
  const uAD = (await ethers.getContractAt("UbiquityAlgorithmicDollar", uADAdr)) as UbiquityAlgorithmicDollar;
  const curveToken = (await ethers.getContractAt("ERC20", curve3CrvToken)) as ERC20;
  const treasuryAddr = await manager.treasuryAddress();
  console.log(`---treasury Address:${treasuryAddr}  `);
  const bondingAddr = await manager.bondingContractAddress();
  console.log(`---bonding Contract Address:${bondingAddr}  `);
  const bonding = (await ethers.getContractAt("BondingV2", bondingAddr)) as BondingV2;
  const metaPoolAddr = await manager.stableSwapMetaPoolAddress();
  console.log(`---metaPoolAddr:${metaPoolAddr}  `);
  const metaPool = (await ethers.getContractAt("IMetaPool", metaPoolAddr)) as IMetaPool;
  let curveFactory = "";
  let DAI = "";
  let USDC = "";
  let USDT = "";
  return { curveFactory, DAI, USDC, USDT, uAD, treasuryAddr, curveToken, metaPool, bondingAddr, manager, curve3CrvToken, bonding };
}
