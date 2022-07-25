import { ContractTransaction, Signer } from "ethers";
import { ethers, getNamedAccounts, network } from "hardhat";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { ERC20 } from "../artifacts/types/ERC20";
import { UbiquityFormulas } from "../artifacts/types/UbiquityFormulas";
import { UbiquityAutoRedeem } from "../artifacts/types/UbiquityAutoRedeem";
import { resetFork } from "./utils/hardhatNode";
import { YieldProxy } from "../artifacts/types/YieldProxy";
import { IJar } from "../artifacts/types/IJar";

let fifthAccount: Signer;
let uAR: UbiquityAutoRedeem;
let yieldProxy: YieldProxy;
let manager: UbiquityAlgorithmicDollarManager;
let usdcWhaleAddress: string;
let uAD: UbiquityAlgorithmicDollar;
let uGOV: UbiquityGovernance;
let DAI: string;
let USDC: string;
let usdcToken: ERC20;
let admin: Signer;
let usdcWhale: Signer;
let secondAccount: Signer;
let thirdAccount: Signer;
let fourthAccount: Signer;
let treasury: Signer;
let jarUSDCAddr: string;
let jarYCRVLUSDaddr: string;
let adminAddress: string;
let secondAddress: string;
let ubiquityFormulas: UbiquityFormulas;
let jar: IJar;
let strategyYearnUsdcV2: string;
export default async function yieldProxySetup(): Promise<{
  usdcToken: ERC20;
  usdcWhale: Signer;
  admin: Signer;
  secondAccount: Signer;
  thirdAccount: Signer;
  fourthAccount: Signer;
  fifthAccount: Signer;
  treasury: Signer;
  usdcWhaleAddress: string;
  jarUSDCAddr: string;
  jarYCRVLUSDaddr: string;
  uAD: UbiquityAlgorithmicDollar;
  uAR: UbiquityAutoRedeem;
  uGOV: UbiquityGovernance;
  yieldProxy: YieldProxy;
  DAI: string;
  USDC: string;
  manager: UbiquityAlgorithmicDollarManager;
  jar: IJar;
  strategyYearnUsdcV2: string;
}> {
  await resetFork(13185077);
  // GET contracts adresses
  ({ DAI, USDC, usdcWhaleAddress, jarUSDCAddr, strategyYearnUsdcV2, jarYCRVLUSDaddr } = await getNamedAccounts());

  // GET first EOA account as admin Signer
  [admin, secondAccount, thirdAccount, treasury, fourthAccount, fifthAccount] = await ethers.getSigners();

  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [usdcWhaleAddress],
  });

  usdcWhale = ethers.provider.getSigner(usdcWhaleAddress);
  const amountToDeposit = ethers.utils.parseUnits("10000", 6);

  adminAddress = await admin.getAddress();
  secondAddress = await secondAccount.getAddress();
  const fourthAddress = await fourthAccount.getAddress();

  const UBQ_MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE"));

  // DEPLOY UbiquityAlgorithmicDollarManager Contract
  manager = (await (await ethers.getContractFactory("UbiquityAlgorithmicDollarManager")).deploy(adminAddress)) as UbiquityAlgorithmicDollarManager;

  // DEPLOY Ubiquity library
  ubiquityFormulas = (await (await ethers.getContractFactory("UbiquityFormulas")).deploy()) as UbiquityFormulas;
  await manager.setFormulasAddress(ubiquityFormulas.address);

  // DEPLOY UAD token Contract
  uAD = (await (await ethers.getContractFactory("UbiquityAlgorithmicDollar")).deploy(manager.address)) as UbiquityAlgorithmicDollar;
  await manager.setDollarTokenAddress(uAD.address);
  // set treasury,uGOVFund and lpReward address needed for excessDollarsDistributor
  await manager.connect(admin).setTreasuryAddress(await treasury.getAddress());
  // DEPLOY UGOV token Contract
  uGOV = (await (await ethers.getContractFactory("UbiquityGovernance")).deploy(manager.address)) as UbiquityGovernance;
  await manager.setGovernanceTokenAddress(uGOV.address);

  // GET USDC token contract
  usdcToken = (await ethers.getContractAt("ERC20", USDC)) as ERC20;
  await usdcToken.connect(usdcWhale).transfer(secondAddress, amountToDeposit);

  const mintingUAD = [adminAddress, secondAddress, manager.address, fourthAddress].map(
    async (signer: string): Promise<ContractTransaction> => uAD.mint(signer, ethers.utils.parseEther("20000"))
  );
  const mintingUBQ = [adminAddress, secondAddress, manager.address, fourthAddress].map(
    async (signer: string): Promise<ContractTransaction> => uGOV.mint(signer, ethers.utils.parseEther("20000"))
  );

  await Promise.all([mintingUAD, mintingUBQ]);
  // deploy yield proxy
  // _fees 10000 = 10% because feesMax = 100000 and 10000 / 100000 = 0.1
  // _UBQRate 10e18, if the UBQRate is 10 then 10/10000 = 0.001  1UBQ gives you 0.001% of fee reduction so 100000 UBQ gives you 100%
  // _bonusYield  5000 = 50% 100 = 1% 10 = 0.1% 1 = 0.01%
  jar = (await ethers.getContractAt("IJar", jarUSDCAddr)) as IJar;
  yieldProxy = (await (await ethers.getContractFactory("YieldProxy")).deploy(
    manager.address,
    jar.address,
    10000,
    ethers.utils.parseEther("100"),
    5000
  )) as YieldProxy;
  // bonding should have the UBQ_MINTER_ROLE to mint bonding shares
  await manager.connect(admin).grantRole(UBQ_MINTER_ROLE, yieldProxy.address);

  const uARFactory = await ethers.getContractFactory("UbiquityAutoRedeem");
  uAR = (await uARFactory.deploy(manager.address)) as UbiquityAutoRedeem;
  await manager.setuARTokenAddress(uAR.address);
  // set treasury,uGOVFund and lpReward address needed for excessDollarsDistributor
  await manager.connect(admin).setTreasuryAddress(await treasury.getAddress());
  return {
    usdcToken,
    usdcWhale,
    admin,
    secondAccount,
    thirdAccount,
    fourthAccount,
    fifthAccount,
    treasury,
    usdcWhaleAddress,
    jarUSDCAddr,
    jarYCRVLUSDaddr,
    uAD,
    uGOV,
    uAR,
    yieldProxy,
    DAI,
    USDC,
    manager,
    jar,
    strategyYearnUsdcV2,
  };
}
