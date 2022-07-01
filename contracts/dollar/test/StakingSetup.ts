import { expect } from "chai";
import { ContractTransaction, Signer, BigNumber } from "ethers";
import { ethers, getNamedAccounts, network } from "hardhat";
import { Staking } from "../artifacts/types/Staking";
import { StakingShare } from "../artifacts/types/StakingShare";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { ERC20 } from "../artifacts/types/ERC20";
import { ICurveFactory } from "../artifacts/types/ICurveFactory";
import { UbiquityFormulas } from "../artifacts/types/UbiquityFormulas";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { MasterChef } from "../artifacts/types/MasterChef";
import { resetFork } from "./utils/hardhatNode";

let twapOracle: TWAPOracle;
let metaPool: IMetaPool;
let staking: Staking;
let stakingShare: StakingShare;
let masterChef: MasterChef;
let manager: UbiquityAlgorithmicDollarManager;
let uAD: UbiquityAlgorithmicDollar;
let uGOV: UbiquityGovernance;
let sablier: string;
let DAI: string;
let USDC: string;
let curvePoolFactory: ICurveFactory;
let curveFactory: string;
let curve3CrvBasePool: string;
let curve3CrvToken: string;
let crvToken: ERC20;
let curveWhaleAddress: string;
let metaPoolAddr: string;
let admin: Signer;
let curveWhale: Signer;
let secondAccount: Signer;
let thirdAccount: Signer;
let treasury: Signer;
let adminAddress: string;
let secondAddress: string;
let ubiquityFormulas: UbiquityFormulas;
let blockCountInAWeek: BigNumber;

type IdBond = {
  id: number;
  bond: BigNumber;
};
interface IbondTokens {
  (signer: Signer, amount: BigNumber, duration: number): Promise<IdBond>;
}

// First block 2020 = 9193266 https://etherscan.io/block/9193266
// First block 2021 = 11565019 https://etherscan.io/block/11565019
// 2020 = 2371753 block = 366 days
// 1 week = 45361 blocks = 2371753*7/366
// n = (block + duration * 45361)
// id = n - n / 100
const deposit: IbondTokens = async function (
  signer: Signer,
  amount: BigNumber,
  duration: number
) {
  const signerAdr = await signer.getAddress();
  await metaPool.connect(signer).approve(staking.address, amount);
  const blockBefore = await ethers.provider.getBlock(
    await ethers.provider.getBlockNumber()
  );
  const n = blockBefore.number + 1 + duration * blockCountInAWeek.toNumber();
  const id = n - (n % 100);
  const zz1 = await staking.stakingDiscountMultiplier(); // zz1 = zerozero1 = 0.001 ether = 10^16
  const mult = BigNumber.from(
    await ubiquityFormulas.durationMultiply(amount, duration, zz1)
  );

  await expect(staking.connect(signer).deposit(amount, duration))
    .to.emit(stakingShare, "TransferSingle")
    .withArgs(
      staking.address,
      ethers.constants.AddressZero,
      signerAdr,
      id,
      mult
    );
  // 1 week = blockCountInAWeek blocks

  const bond: BigNumber = await stakingShare.balanceOf(signerAdr, id);

  return { id, bond };
};

// withdraw staking shares of ID belonging to the signer and return the
// staking share balance of the signer
async function withdraw(signer: Signer, id: number): Promise<BigNumber> {
  const signerAdr = await signer.getAddress();
  const bond: BigNumber = await stakingShare.balanceOf(signerAdr, id);
  await expect(staking.connect(signer).withdraw(bond, id))
    .to.emit(stakingShare, "TransferSingle")
    .withArgs(
      staking.address,
      signerAdr,
      ethers.constants.AddressZero,
      id,
      bond
    );
  return metaPool.balanceOf(signerAdr);
}

async function stakingSetup(): Promise<{
  crvToken: ERC20;
  curveWhale: Signer;
  admin: Signer;
  secondAccount: Signer;
  thirdAccount: Signer;
  treasury: Signer;
  curvePoolFactory: ICurveFactory;
  uAD: UbiquityAlgorithmicDollar;
  uGOV: UbiquityGovernance;
  metaPool: IMetaPool;
  staking: Staking;
  masterChef: MasterChef;
  stakingShare: StakingShare;
  twapOracle: TWAPOracle;
  ubiquityFormulas: UbiquityFormulas;
  sablier: string;
  DAI: string;
  USDC: string;
  manager: UbiquityAlgorithmicDollarManager;
  blockCountInAWeek: BigNumber;
}> {
  await resetFork(12592661);
  // GET contracts adresses
  ({
    sablier,
    DAI,
    USDC,
    curveFactory,
    curve3CrvBasePool,
    curve3CrvToken,
    curveWhaleAddress,
  } = await getNamedAccounts());

  // GET first EOA account as admin Signer
  [admin, secondAccount, thirdAccount, treasury] = await ethers.getSigners();
  adminAddress = await admin.getAddress();
  secondAddress = await secondAccount.getAddress();
  const UBQ_MINTER_ROLE = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE")
  );
  const UBQ_BURNER_ROLE = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("UBQ_BURNER_ROLE")
  );
  // DEPLOY UbiquityAlgorithmicDollarManager Contract
  manager = (await (
    await ethers.getContractFactory("UbiquityAlgorithmicDollarManager")
  ).deploy(adminAddress)) as UbiquityAlgorithmicDollarManager;

  // DEPLOY Ubiquity library
  ubiquityFormulas = (await (
    await ethers.getContractFactory("UbiquityFormulas")
  ).deploy()) as UbiquityFormulas;
  await manager.setFormulasAddress(ubiquityFormulas.address);

  // DEPLOY Staking Contract
  staking = (await (
    await ethers.getContractFactory("Staking")
  ).deploy(manager.address, sablier)) as Staking;

  await staking.setBlockCountInAWeek(420);
  blockCountInAWeek = await staking.blockCountInAWeek();
  await manager.setStakingContractAddress(staking.address);

  // DEPLOY StakingShare Contract
  stakingShare = (await (
    await ethers.getContractFactory("StakingShare")
  ).deploy(manager.address)) as StakingShare;
  await manager.setStakingShareAddress(stakingShare.address);
  // set staking as operator for second account so that it can burn its staking shares
  await stakingShare
    .connect(secondAccount)
    .setApprovalForAll(staking.address, true);
  // set staking as operator for admin account so that it can burn its staking shares
  await stakingShare.setApprovalForAll(staking.address, true);
  // set staking as operator for third account so that it can burn its staking shares
  await stakingShare
    .connect(thirdAccount)
    .setApprovalForAll(staking.address, true);

  // DEPLOY UAD token Contract
  uAD = (await (
    await ethers.getContractFactory("UbiquityAlgorithmicDollar")
  ).deploy(manager.address)) as UbiquityAlgorithmicDollar;
  await manager.setDollarTokenAddress(uAD.address);
  // set treasury,uGOVFund and lpReward address needed for excessDollarsDistributor
  await manager.connect(admin).setTreasuryAddress(await treasury.getAddress());
  // DEPLOY UGOV token Contract
  uGOV = (await (
    await ethers.getContractFactory("UbiquityGovernance")
  ).deploy(manager.address)) as UbiquityGovernance;
  await manager.setGovernanceTokenAddress(uGOV.address);

  // GET 3CRV token contract
  crvToken = (await ethers.getContractAt("ERC20", curve3CrvToken)) as ERC20;

  // GET curve factory contract
  // curvePoolFactory = (await ethers.getContractAt(
  //   "ICurveFactory",
  //   curveFactory
  // )) as ICurveFactory;

  // Mint 10000 uAD each for admin, second account and manager
  const mintings = [adminAddress, secondAddress, manager.address].map(
    async (signer: string): Promise<ContractTransaction> =>
      uAD.mint(signer, ethers.utils.parseEther("10000"))
  );
  await Promise.all(mintings);

  // Impersonate curve whale account
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [curveWhaleAddress],
  });
  curveWhale = ethers.provider.getSigner(curveWhaleAddress);

  // staking should have the UBQ_MINTER_ROLE to mint staking shares
  await manager.connect(admin).grantRole(UBQ_MINTER_ROLE, staking.address);
  // staking should have the UBQ_BURNER_ROLE to burn staking shares
  await manager.connect(admin).grantRole(UBQ_BURNER_ROLE, staking.address);

  // Mint uAD for whale
  await uAD.mint(curveWhaleAddress, ethers.utils.parseEther("10"));
  await crvToken
    .connect(curveWhale)
    .transfer(manager.address, ethers.utils.parseEther("10000"));
  await manager.deployStableSwapPool(
    curveFactory,
    curve3CrvBasePool,
    crvToken.address,
    10,
    4000000
  );
  metaPoolAddr = await manager.stableSwapMetaPoolAddress();

  // GET curve meta pool contract
  metaPool = (await ethers.getContractAt(
    "IMetaPool",
    metaPoolAddr
  )) as IMetaPool;

  // TRANSFER some uLP tokens to staking contract to simulate
  // the 80% premium from inflation
  await metaPool
    .connect(admin)
    .transfer(staking.address, ethers.utils.parseEther("100"));

  // TRANSFER some uLP tokens to second account
  await metaPool
    .connect(admin)
    .transfer(secondAddress, ethers.utils.parseEther("1000"));

  // DEPLOY TWAPOracle Contract
  twapOracle = (await (
    await ethers.getContractFactory("TWAPOracle")
  ).deploy(metaPoolAddr, uAD.address, curve3CrvToken)) as TWAPOracle;
  await manager.setTwapOracleAddress(twapOracle.address);

  // DEPLOY MasterChef
  masterChef = (await (
    await ethers.getContractFactory("MasterChef")
  ).deploy(manager.address)) as MasterChef;
  await manager.setMasterChefAddress(masterChef.address);
  await manager.grantRole(UBQ_MINTER_ROLE, masterChef.address);

  const managerMasterChefAddress = await manager.masterChefAddress();
  expect(masterChef.address).to.be.equal(managerMasterChefAddress);

  curvePoolFactory = (await ethers.getContractAt(
    "ICurveFactory",
    curveFactory
  )) as ICurveFactory;

  return {
    curveWhale,
    masterChef,
    admin,
    crvToken,
    secondAccount,
    thirdAccount,
    treasury,
    curvePoolFactory,
    uAD,
    uGOV,
    metaPool,
    staking,
    stakingShare,
    twapOracle,
    ubiquityFormulas,
    sablier,
    DAI,
    USDC,
    manager,
    blockCountInAWeek,
  };
}

export { stakingSetup, deposit, withdraw };
