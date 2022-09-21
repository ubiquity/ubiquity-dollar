import { BigNumber } from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ERC20 } from "../../../artifacts/types";
import { BondingShareV2 } from "../../../artifacts/types/BondingShareV2";
import { UbiquityAlgorithmicDollarManager } from "../../../artifacts/types/UbiquityAlgorithmicDollarManager";
import { accountWithWithdrawableBond } from "../faucet";
const NETWORK_ADDRESS = "http://localhost:8545";
export default async function faucet(taskArgs: { receiver: string | null; manager: string | null }, { ethers, getNamedAccounts }: HardhatRuntimeEnvironment) {
  const net = await ethers.provider.getNetwork();
  if (net.name === "hardhat") {
    console.warn(
      "You are running the faucet task with Hardhat network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }
  console.log(`net chainId: ${net.chainId}  `);

  // Gotta use this provider otherwise impersonation doesn't work
  // https://github.com/nomiclabs/hardhat/issues/1226#issuecomment-924352129
  const provider = new ethers.providers.JsonRpcProvider(NETWORK_ADDRESS);

  const {
    UbiquityAlgorithmicDollarManagerAddress: namedManagerAddress,
    ubq: namedTreasuryAddress,
    usdcWhaleAddress,
    USDC: usdcTokenAddress,
    // curve3CrvToken: namedCurve3CrvAddress,
  } = await getNamedAccounts();

  console.log(namedManagerAddress, namedTreasuryAddress);

  const managerAddress = taskArgs.manager || namedManagerAddress;
  const [firstAccount] = await ethers.getSigners();
  const receiverAddress = taskArgs.receiver || firstAccount.address;

  await provider.send("hardhat_impersonateAccount", [namedTreasuryAddress]);
  await provider.send("hardhat_impersonateAccount", [accountWithWithdrawableBond]);
  await provider.send("hardhat_impersonateAccount", [usdcWhaleAddress]);
  const treasuryAccount = provider.getSigner(namedTreasuryAddress);
  const accountWithWithdrawableBondAccount = provider.getSigner(accountWithWithdrawableBond);
  const usdcWhaleAccount = provider.getSigner(usdcWhaleAddress);

  console.log("Manager address: ", managerAddress);
  console.log("Treasury address: ", namedTreasuryAddress);
  console.log("Receiver address:", receiverAddress);

  const manager = (await ethers.getContractAt("UbiquityAlgorithmicDollarManager", managerAddress, treasuryAccount)) as UbiquityAlgorithmicDollarManager;

  const uADToken = (await ethers.getContractAt("ERC20", await manager.dollarTokenAddress(), treasuryAccount)) as ERC20;

  const uARToken = (await ethers.getContractAt("ERC20", await manager.autoRedeemTokenAddress(), treasuryAccount)) as ERC20;

  const curveLPToken = (await ethers.getContractAt("ERC20", await manager.stableSwapMetaPoolAddress(), treasuryAccount)) as ERC20;

  const usdcToken = (await ethers.getContractAt("ERC20", usdcTokenAddress, usdcWhaleAccount)) as ERC20;

  const gelatoUadUsdcLpToken = (await ethers.getContractAt("ERC20", "0xA9514190cBBaD624c313Ea387a18Fd1dea576cbd", treasuryAccount)) as ERC20;

  // const crvToken = (await ethers.getContractAt(
  //   "ERC20",
  //   namedCurve3CrvAddress,
  //   treasuryAccount
  // )) as ERC20;
  const ubqToken = (await ethers.getContractAt("ERC20", await manager.governanceTokenAddress(), treasuryAccount)) as ERC20;

  const bondingShareToken = (await ethers.getContractAt(
    "BondingShareV2",
    await manager.bondingShareAddress(),
    accountWithWithdrawableBondAccount
  )) as BondingShareV2;

  const bondingShareId = (await bondingShareToken.holderTokens(accountWithWithdrawableBond))[0];

  const bondingShareBalance = +(await bondingShareToken.balanceOf(accountWithWithdrawableBond, bondingShareId)).toString(); // Either 1 or 0

  if (bondingShareBalance > 0) {
    await bondingShareToken.safeTransferFrom(accountWithWithdrawableBond, receiverAddress, bondingShareId, ethers.BigNumber.from(1), []);

    console.log(`Transferred withdrawable bonding share token from ${bondingShareId.toString()} from ${accountWithWithdrawableBond}`);
  } else {
    console.log("Tried to transfer a withdrawable bonding share token but couldn't");
  }

  const transfer = async (name: string, token: ERC20, amount: BigNumber) => {
    console.log(`${name}: ${token.address}`);
    const tx = await token.transfer(receiverAddress, amount);
    console.log(`  Transferred ${ethers.utils.formatEther(amount)} ${name} from ${tx.from}`);
  };

  await transfer("G-UNI uAD/USDC LP", gelatoUadUsdcLpToken, ethers.utils.parseEther("2"));
  await transfer("uAD", uADToken, ethers.utils.parseEther("1000"));
  await transfer("uAR", uARToken, ethers.utils.parseEther("1000"));
  // await transfer(
  //   "uAD3CRV-f",
  //   curveLPToken,
  //   ethers.utils.parseEther("1000")
  // );
  // await transfer("3CRV", crvToken, 1000);
  await transfer("UBQ", ubqToken, ethers.utils.parseEther("1000"));
  await transfer("USDC", usdcToken, ethers.utils.parseUnits("1000", 6));
}
