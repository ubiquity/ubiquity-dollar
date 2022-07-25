import { expect } from "chai";
import { ContractTransaction, Signer, BigNumber } from "ethers";
import { ethers, getNamedAccounts, network } from "hardhat";
import { Bonding } from "../artifacts/types/Bonding";
import { BondingV2 } from "../artifacts/types/BondingV2";
import { BondingFormulas } from "../artifacts/types/BondingFormulas";
import { BondingShare } from "../artifacts/types/BondingShare";
import { BondingShareV2 } from "../artifacts/types/BondingShareV2";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { ERC20 } from "../artifacts/types/ERC20";
import { ICurveFactory } from "../artifacts/types/ICurveFactory";
import { UbiquityFormulas } from "../artifacts/types/UbiquityFormulas";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { MasterChefV2 } from "../artifacts/types/MasterChefV2";
import { MasterChef } from "../artifacts/types/MasterChef";
import { UARForDollarsCalculator } from "../artifacts/types/UARForDollarsCalculator";
import { CouponsForDollarsCalculator } from "../artifacts/types/CouponsForDollarsCalculator";
import { DollarMintingCalculator } from "../artifacts/types/DollarMintingCalculator";
import { DebtCoupon } from "../artifacts/types/DebtCoupon";
import { DebtCouponManager } from "../artifacts/types/DebtCouponManager";
import { UbiquityAutoRedeem } from "../artifacts/types/UbiquityAutoRedeem";
import { ExcessDollarsDistributor } from "../artifacts/types/ExcessDollarsDistributor";
import { IUniswapV2Router02 } from "../artifacts/types/IUniswapV2Router02";
import { SushiSwapPool } from "../artifacts/types/SushiSwapPool";

let couponsForDollarsCalculator: CouponsForDollarsCalculator;
let debtCoupon: DebtCoupon;
let debtCouponMgr: DebtCouponManager;
let fifthAccount: Signer;
let uAR: UbiquityAutoRedeem;
let dollarMintingCalculator: DollarMintingCalculator;
let uarForDollarsCalculator: UARForDollarsCalculator;
let excessDollarsDistributor: ExcessDollarsDistributor;
let twapOracle: TWAPOracle;
let metaPool: IMetaPool;
let bonding: Bonding;
let bondingShare: BondingShare;
let bondingV2: BondingV2;
let bondingShareV2: BondingShareV2;
let masterChef: MasterChef;
let masterChefV2: MasterChefV2;
let manager: UbiquityAlgorithmicDollarManager;
let bondingMaxBalance: BigNumber;
let bondingMinBalance: BigNumber;
let uAD: UbiquityAlgorithmicDollar;
let bondingFormulas: BondingFormulas;
let uGOV: UbiquityGovernance;
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
let fourthAccount: Signer;
let treasury: Signer;
let bondingZeroAccount: Signer;
let bondingMinAccount: Signer;
let bondingMaxAccount: Signer;
let adminAddress: string;
let secondAddress: string;
let ubiquityFormulas: UbiquityFormulas;
let blockCountInAWeek: BigNumber;
let sushiUGOVPool: SushiSwapPool;
const couponLengthBlocks = 100;
const routerAdr = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F"; // SushiV2Router02
let router: IUniswapV2Router02;

export type IdBond = {
  id: BigNumber;
  bsAmount: BigNumber;
  shares: BigNumber;
  creationBlock: number;
  endBlock: number;
};
interface IbondTokens {
  (signer: Signer, amount: BigNumber, duration: number): Promise<IdBond>;
}

const deployUADUGOVSushiPool = async (signer: Signer): Promise<SushiSwapPool> => {
  const signerAdr = await signer.getAddress();
  // need some uGOV to provide liquidity
  await uGOV.mint(signerAdr, ethers.utils.parseEther("1000"));
  // need some uGOV to provide liquidity
  await uAD.mint(signerAdr, ethers.utils.parseEther("10000"));
  // add liquidity to the pair uAD-UGOV 1 UGOV = 10 UAD
  const blockBefore = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
  // must allow to transfer token
  await uAD.connect(signer).approve(routerAdr, ethers.utils.parseEther("10000"));
  await uGOV.connect(signer).approve(routerAdr, ethers.utils.parseEther("1000"));
  await router
    .connect(signer)
    .addLiquidity(
      uAD.address,
      uGOV.address,
      ethers.utils.parseEther("10000"),
      ethers.utils.parseEther("1000"),
      ethers.utils.parseEther("9900"),
      ethers.utils.parseEther("990"),
      signerAdr,
      blockBefore.timestamp + 100
    );
  const sushiFactory = await ethers.getContractFactory("SushiSwapPool");
  sushiUGOVPool = (await sushiFactory.deploy(manager.address)) as SushiSwapPool;
  await manager.setSushiSwapPoolAddress(sushiUGOVPool.address);
  return sushiUGOVPool;
};

// First block 2020 = 9193266 https://etherscan.io/block/9193266
// First block 2021 = 11565019 https://etherscan.io/block/11565019
// 2020 = 2371753 block = 366 days
// 1 week = 45361 blocks = 2371753*7/366
// n = (block + duration * 45361)
// id = n - n / 100
const deposit: IbondTokens = async function (signer: Signer, amount: BigNumber, duration: number) {
  const signerAdr = await signer.getAddress();
  await metaPool.connect(signer).approve(bondingV2.address, amount);
  const signerLPBalanceBefore = await metaPool.balanceOf(signerAdr);
  const bondingLPBalanceBefore = await metaPool.balanceOf(bondingV2.address);
  const blockBefore = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
  const curBlockCountInAWeek = await bondingV2.blockCountInAWeek();
  const endBlock = blockBefore.number + 1 + duration * curBlockCountInAWeek.toNumber();
  const zz1 = await bondingV2.bondingDiscountMultiplier(); // zz1 = zerozero1 = 0.001 ether = 10^16
  const shares = BigNumber.from(await ubiquityFormulas.durationMultiply(amount, duration, zz1));
  const id = (await bondingShareV2.totalSupply()).add(1);
  const creationBlock = (await ethers.provider.getBlockNumber()) + 1;
  await expect(bondingV2.connect(signer).deposit(amount, duration))
    .to.emit(bondingShareV2, "TransferSingle")
    .withArgs(bondingV2.address, ethers.constants.AddressZero, signerAdr, id, 1)
    .and.to.emit(bondingV2, "Deposit")
    .withArgs(signerAdr, id, amount, shares, duration, endBlock);
  // 1 week = blockCountInAWeek blocks
  const signerLPBalanceAfter = await metaPool.balanceOf(signerAdr);
  const bondingLPBalanceAfter = await metaPool.balanceOf(bondingV2.address);
  expect(signerLPBalanceBefore).to.equal(signerLPBalanceAfter.add(amount));
  expect(bondingLPBalanceAfter).to.equal(bondingLPBalanceBefore.add(amount));
  const bsAmount: BigNumber = await bondingShareV2.balanceOf(signerAdr, id);
  return { id, bsAmount, shares, creationBlock, endBlock };
};

type Bond = [string, BigNumber, BigNumber, BigNumber, BigNumber, BigNumber] & {
  minter: string;
  lpFirstDeposited: BigNumber;
  creationBlock: BigNumber;
  lpRewardDebt: BigNumber;
  endBlock: BigNumber;
  lpAmount: BigNumber;
};

// withdraw bonding shares of ID belonging to the signer and return the
// bonding share balance of the signer
async function removeLiquidity(signer: Signer, id: BigNumber, amount: BigNumber): Promise<Bond> {
  const signerAdr = await signer.getAddress();
  const bondAmount: BigNumber = await bondingShareV2.balanceOf(signerAdr, id);
  expect(bondAmount).to.equal(1);
  const bondBefore = await bondingShareV2.getBond(id);
  await metaPool.connect(signer).approve(bondingV2.address, amount);
  const bs = await masterChefV2.getBondingShareInfo(id);
  const bond = await bondingShareV2.getBond(id);
  const sharesToRemove = await bondingFormulas.sharesForLP(bond, bs, amount);
  const pendingLpRewards = await bondingV2.pendingLpRewards(id);

  await expect(bondingV2.connect(signer).removeLiquidity(amount, id))
    .to.emit(bondingV2, "RemoveLiquidityFromBond")
    .withArgs(signerAdr, id, amount, amount, pendingLpRewards, sharesToRemove);

  const bsAfter = await masterChefV2.getBondingShareInfo(id);
  expect(bsAfter[0]).to.equal(bs[0].sub(sharesToRemove));
  const pendingLpRewardsAfter = await bondingV2.pendingLpRewards(id);
  const bondAfter = await bondingShareV2.getBond(id);
  expect(pendingLpRewardsAfter).to.equal(0);
  expect(bondAfter.lpAmount).to.equal(bondBefore.lpAmount.sub(amount));
  return bondAfter;
}

// withdraw bonding shares of ID belonging to the signer and return the
// bonding share balance of the signer
async function addLiquidity(signer: Signer, id: BigNumber, amount: BigNumber, duration: number): Promise<Bond> {
  const signerAdr = await signer.getAddress();
  const bondAmount: BigNumber = await bondingShareV2.balanceOf(signerAdr, id);
  expect(bondAmount).to.equal(1);
  await metaPool.connect(signer).approve(bondingV2.address, amount);
  const bondBefore = await bondingShareV2.getBond(id);
  const zz1 = await bondingV2.bondingDiscountMultiplier(); // zz1 = zerozero1 = 0.001 ether = 10^16

  const pendingLpRewards = await bondingV2.pendingLpRewards(id);

  const totalLpAfter = bondBefore.lpAmount.add(amount).add(pendingLpRewards);
  const shares = BigNumber.from(await ubiquityFormulas.durationMultiply(totalLpAfter, duration, zz1));
  await expect(bondingV2.connect(signer).addLiquidity(amount, id, duration))
    .to.emit(bondingV2, "AddLiquidityFromBond")
    .withArgs(signerAdr, id, totalLpAfter, shares);
  const bs = await masterChefV2.getBondingShareInfo(id);
  expect(bs[0]).to.equal(shares);
  const bondAfter = await bondingShareV2.getBond(id);
  const pendingLpRewardsAfter = await bondingV2.pendingLpRewards(id);
  expect(pendingLpRewardsAfter).to.equal(0);
  expect(bondAfter.lpAmount).to.equal(totalLpAfter);
  return bondAfter;
}

async function bondingSetupV2(): Promise<{
  crvToken: ERC20;
  curveWhale: Signer;
  admin: Signer;
  secondAccount: Signer;
  thirdAccount: Signer;
  fourthAccount: Signer;
  fifthAccount: Signer;
  treasury: Signer;
  bondingZeroAccount: Signer;
  bondingMinAccount: Signer;
  bondingMaxAccount: Signer;
  bondingMinBalance: BigNumber;
  bondingMaxBalance: BigNumber;
  bondingFormulas: BondingFormulas;
  curvePoolFactory: ICurveFactory;
  uAD: UbiquityAlgorithmicDollar;
  uAR: UbiquityAutoRedeem;
  uGOV: UbiquityGovernance;
  metaPool: IMetaPool;
  bonding: Bonding;
  masterChef: MasterChef;
  bondingV2: BondingV2;
  masterChefV2: MasterChefV2;
  bondingShare: BondingShare;
  bondingShareV2: BondingShareV2;
  couponsForDollarsCalculator: CouponsForDollarsCalculator;
  dollarMintingCalculator: DollarMintingCalculator;
  debtCoupon: DebtCoupon;
  debtCouponMgr: DebtCouponManager;
  twapOracle: TWAPOracle;
  ubiquityFormulas: UbiquityFormulas;
  DAI: string;
  USDC: string;
  manager: UbiquityAlgorithmicDollarManager;
  blockCountInAWeek: BigNumber;
  sushiUGOVPool: SushiSwapPool;
  excessDollarsDistributor: ExcessDollarsDistributor;
}> {
  // GET contracts adresses
  ({ DAI, USDC, curveFactory, curve3CrvBasePool, curve3CrvToken, curveWhaleAddress } = await getNamedAccounts());

  // GET first EOA account as admin Signer
  [
    admin,
    secondAccount,
    thirdAccount,
    treasury,
    fourthAccount,
    bondingZeroAccount,
    bondingMaxAccount,
    bondingMinAccount,
    fifthAccount,
  ] = await ethers.getSigners();
  router = (await ethers.getContractAt("IUniswapV2Router02", routerAdr)) as IUniswapV2Router02;
  adminAddress = await admin.getAddress();
  secondAddress = await secondAccount.getAddress();
  const fourthAddress = await fourthAccount.getAddress();
  const bondingZeroAccountAddress = await bondingZeroAccount.getAddress();
  const bondingMinAccountAddress = await bondingMinAccount.getAddress();
  const bondingMaxAccountAddress = await bondingMaxAccount.getAddress();

  const UBQ_MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE"));
  const UBQ_BURNER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_BURNER_ROLE"));
  const UBQ_TOKEN_MANAGER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_TOKEN_MANAGER_ROLE"));
  // DEPLOY UbiquityAlgorithmicDollarManager Contract
  manager = (await (await ethers.getContractFactory("UbiquityAlgorithmicDollarManager")).deploy(adminAddress)) as UbiquityAlgorithmicDollarManager;

  // DEPLOY Ubiquity library
  ubiquityFormulas = (await (await ethers.getContractFactory("UbiquityFormulas")).deploy()) as UbiquityFormulas;
  await manager.setFormulasAddress(ubiquityFormulas.address);

  // DEPLOY Bonding Contract
  bonding = (await (await ethers.getContractFactory("Bonding")).deploy(manager.address, ethers.constants.AddressZero)) as Bonding;
  await bonding.setBlockCountInAWeek(420);
  blockCountInAWeek = await bonding.blockCountInAWeek();
  await manager.setBondingContractAddress(bonding.address);
  // DEPLOY BondingShare Contract
  bondingShare = (await (await ethers.getContractFactory("BondingShare")).deploy(manager.address)) as BondingShare;
  await manager.setBondingShareAddress(bondingShare.address);
  // set bonding as operator for second account so that it can burn its bonding shares
  await bondingShare.connect(secondAccount).setApprovalForAll(bonding.address, true);
  // set bonding as operator for admin account so that it can burn its bonding shares
  await bondingShare.setApprovalForAll(bonding.address, true);
  // set bonding as operator for third account so that it can burn its bonding shares
  await bondingShare.connect(thirdAccount).setApprovalForAll(bonding.address, true);
  // DEPLOY UAD token Contract
  uAD = (await (await ethers.getContractFactory("UbiquityAlgorithmicDollar")).deploy(manager.address)) as UbiquityAlgorithmicDollar;
  await manager.setDollarTokenAddress(uAD.address);
  // set treasury,uGOVFund and lpReward address needed for excessDollarsDistributor
  await manager.connect(admin).setTreasuryAddress(await treasury.getAddress());
  // DEPLOY UGOV token Contract
  uGOV = (await (await ethers.getContractFactory("UbiquityGovernance")).deploy(manager.address)) as UbiquityGovernance;
  await manager.setGovernanceTokenAddress(uGOV.address);
  sushiUGOVPool = await deployUADUGOVSushiPool(thirdAccount);
  // GET 3CRV token contract
  crvToken = (await ethers.getContractAt("ERC20", curve3CrvToken)) as ERC20;

  // GET curve factory contract
  // curvePoolFactory = (await ethers.getContractAt(
  //   "ICurveFactory",
  //   curveFactory
  // )) as ICurveFactory;

  // Mint 10000 uAD each for admin, second account and manager
  const mintings = [
    adminAddress,
    secondAddress,
    manager.address,
    fourthAddress,
    bondingZeroAccountAddress,
    bondingMinAccountAddress,
    bondingMaxAccountAddress,
  ].map(async (receiver: string): Promise<ContractTransaction> => uAD.mint(receiver, ethers.utils.parseEther("10000")));
  await Promise.all(mintings);
  // Impersonate curve whale account
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [curveWhaleAddress],
  });
  curveWhale = ethers.provider.getSigner(curveWhaleAddress);

  // bonding should have the UBQ_MINTER_ROLE to mint bonding shares
  await manager.connect(admin).grantRole(UBQ_MINTER_ROLE, bonding.address);
  // bonding should have the UBQ_BURNER_ROLE to burn bonding shares
  await manager.connect(admin).grantRole(UBQ_BURNER_ROLE, bonding.address);

  // Mint uAD for whale
  await uAD.mint(curveWhaleAddress, ethers.utils.parseEther("10"));
  await crvToken.connect(curveWhale).transfer(manager.address, ethers.utils.parseEther("10000"));
  await crvToken.connect(curveWhale).transfer(bondingMaxAccountAddress, ethers.utils.parseEther("10000"));
  await crvToken.connect(curveWhale).transfer(bondingMinAccountAddress, ethers.utils.parseEther("10000"));
  await crvToken.connect(curveWhale).transfer(fourthAddress, ethers.utils.parseEther("100000"));

  await manager.deployStableSwapPool(curveFactory, curve3CrvBasePool, crvToken.address, 10, 4000000);
  metaPoolAddr = await manager.stableSwapMetaPoolAddress();
  // GET curve meta pool contract
  metaPool = (await ethers.getContractAt("IMetaPool", metaPoolAddr)) as IMetaPool;

  // TRANSFER some uLP tokens to bonding contract to simulate
  // the 80% premium from inflation
  await metaPool.connect(admin).transfer(bonding.address, ethers.utils.parseEther("100"));

  // TRANSFER some uLP tokens to second account
  await metaPool.connect(admin).transfer(secondAddress, ethers.utils.parseEther("1000"));

  // DEPLOY TWAPOracle Contract
  twapOracle = (await (await ethers.getContractFactory("TWAPOracle")).deploy(metaPoolAddr, uAD.address, curve3CrvToken)) as TWAPOracle;
  await manager.setTwapOracleAddress(twapOracle.address);

  // set uAR for dollar Calculator
  const UARForDollarsCalculatorFactory = await ethers.getContractFactory("UARForDollarsCalculator");
  uarForDollarsCalculator = (await UARForDollarsCalculatorFactory.deploy(manager.address)) as UARForDollarsCalculator;

  await manager.connect(admin).setUARCalculatorAddress(uarForDollarsCalculator.address);
  // set coupon for dollar Calculator
  const couponsForDollarsCalculatorFactory = await ethers.getContractFactory("CouponsForDollarsCalculator");
  couponsForDollarsCalculator = (await couponsForDollarsCalculatorFactory.deploy(manager.address)) as CouponsForDollarsCalculator;
  await manager.connect(admin).setCouponCalculatorAddress(couponsForDollarsCalculator.address);
  // set Dollar Minting Calculator
  const dollarMintingCalculatorFactory = await ethers.getContractFactory("DollarMintingCalculator");
  dollarMintingCalculator = (await dollarMintingCalculatorFactory.deploy(manager.address)) as DollarMintingCalculator;
  await manager.connect(admin).setDollarMintingCalculatorAddress(dollarMintingCalculator.address);
  // set debt coupon token
  const dcManagerFactory = await ethers.getContractFactory("DebtCouponManager");
  const debtCouponFactory = await ethers.getContractFactory("DebtCoupon");
  debtCoupon = (await debtCouponFactory.deploy(manager.address)) as DebtCoupon;

  await manager.connect(admin).setDebtCouponAddress(debtCoupon.address);
  debtCouponMgr = (await dcManagerFactory.deploy(manager.address, couponLengthBlocks)) as DebtCouponManager;

  // debtCouponMgr should have the COUPON_MANAGER role to mint debtCoupon
  const COUPON_MANAGER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("COUPON_MANAGER"));

  await manager.connect(admin).grantRole(COUPON_MANAGER_ROLE, debtCouponMgr.address);
  await manager.connect(admin).grantRole(UBQ_MINTER_ROLE, debtCouponMgr.address);
  await manager.connect(admin).grantRole(UBQ_BURNER_ROLE, debtCouponMgr.address);

  // to calculate the totalOutstanding debt we need to take into account autoRedeemToken.totalSupply
  const uARFactory = await ethers.getContractFactory("UbiquityAutoRedeem");
  uAR = (await uARFactory.deploy(manager.address)) as UbiquityAutoRedeem;
  await manager.setuARTokenAddress(uAR.address);

  // when the debtManager mint uAD it there is too much it distribute the excess to
  const excessDollarsDistributorFactory = await ethers.getContractFactory("ExcessDollarsDistributor");
  excessDollarsDistributor = (await excessDollarsDistributorFactory.deploy(manager.address)) as ExcessDollarsDistributor;
  await manager.connect(admin).setExcessDollarsDistributor(debtCouponMgr.address, excessDollarsDistributor.address);

  // set treasury,uGOVFund and lpReward address needed for excessDollarsDistributor
  await manager.connect(admin).setTreasuryAddress(await treasury.getAddress());

  // DEPLOY MasterChef
  masterChef = (await (await ethers.getContractFactory("MasterChef")).deploy(manager.address)) as MasterChef;
  await manager.setMasterChefAddress(masterChef.address);
  await manager.grantRole(UBQ_MINTER_ROLE, masterChef.address);

  const managerMasterChefAddress = await manager.masterChefAddress();
  expect(masterChef.address).to.be.equal(managerMasterChefAddress);
  curvePoolFactory = (await ethers.getContractAt("ICurveFactory", curveFactory)) as ICurveFactory;

  // add liquidity to the metapool
  // accounts need to approve metaPool for sending its uAD and 3CRV
  await uAD.connect(bondingMinAccount).approve(metaPool.address, ethers.utils.parseEther("10000"));
  await crvToken.connect(bondingMinAccount).approve(metaPool.address, ethers.utils.parseEther("10000"));
  await uAD.connect(bondingMaxAccount).approve(metaPool.address, ethers.utils.parseEther("10000"));
  await crvToken.connect(bondingMaxAccount).approve(metaPool.address, ethers.utils.parseEther("10000"));
  await uAD.connect(fourthAccount).approve(metaPool.address, ethers.utils.parseEther("10000"));
  await crvToken.connect(fourthAccount).approve(metaPool.address, ethers.utils.parseEther("10000"));

  const dyuAD2LP = await metaPool["calc_token_amount(uint256[2],bool)"]([ethers.utils.parseEther("100"), ethers.utils.parseEther("100")], true);
  await metaPool
    .connect(bondingMinAccount)
    ["add_liquidity(uint256[2],uint256)"]([ethers.utils.parseEther("100"), ethers.utils.parseEther("100")], dyuAD2LP.mul(99).div(100));
  await metaPool
    .connect(bondingMaxAccount)
    ["add_liquidity(uint256[2],uint256)"]([ethers.utils.parseEther("100"), ethers.utils.parseEther("100")], dyuAD2LP.mul(99).div(100));
  await metaPool
    .connect(fourthAccount)
    ["add_liquidity(uint256[2],uint256)"]([ethers.utils.parseEther("100"), ethers.utils.parseEther("100")], dyuAD2LP.mul(99).div(100));
  bondingMinBalance = await metaPool.balanceOf(bondingMinAccountAddress);
  await metaPool.connect(bondingMinAccount).approve(bonding.address, bondingMinBalance);
  await bonding.connect(bondingMinAccount).deposit(bondingMinBalance, 1);
  bondingMaxBalance = await metaPool.balanceOf(bondingMaxAccountAddress);
  await metaPool.connect(bondingMaxAccount).approve(bonding.address, bondingMaxBalance);
  await bonding.connect(bondingMaxAccount).deposit(bondingMaxBalance, 208);
  const bondingMaxIds = await bondingShare.holderTokens(bondingMaxAccountAddress);
  expect(bondingMaxIds.length).to.equal(1);
  const bsMaxAmount = await bondingShare.balanceOf(bondingMaxAccountAddress, bondingMaxIds[0]);
  const bondingMinIds = await bondingShare.holderTokens(bondingMinAccountAddress);
  expect(bondingMinIds.length).to.equal(1);
  const bsMinAmount = await bondingShare.balanceOf(bondingMinAccountAddress, bondingMinIds[0]);
  expect(bsMinAmount).to.be.lt(bsMaxAmount);
  // DEPLOY MasterChefV2
  masterChefV2 = (await (await ethers.getContractFactory("MasterChefV2")).deploy(manager.address, [], [], [])) as MasterChefV2;
  await manager.setMasterChefAddress(masterChefV2.address);
  await manager.grantRole(UBQ_MINTER_ROLE, masterChefV2.address);
  await manager.grantRole(UBQ_TOKEN_MANAGER_ROLE, adminAddress);
  await masterChefV2.setUGOVPerBlock(BigNumber.from(10).pow(18));
  const managerMasterChefV2Address = await manager.masterChefAddress();
  expect(masterChefV2.address).to.be.equal(managerMasterChefV2Address);

  // DEPLOY BondingShareV2 Contract
  const uri = `{
    "name": "Bonding Share",
    "description": "Ubiquity Bonding Share V2",
    "image": "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/"
  }`;
  bondingShareV2 = (await (await ethers.getContractFactory("BondingShareV2")).deploy(manager.address, uri)) as BondingShareV2;

  await manager.setBondingShareAddress(bondingShareV2.address);
  const managerBondingShareAddress = await manager.bondingShareAddress();
  expect(bondingShareV2.address).to.be.equal(managerBondingShareAddress);

  // DEPLOY Bonding Contract
  bondingFormulas = (await (await ethers.getContractFactory("BondingFormulas")).deploy()) as BondingFormulas;

  bondingV2 = (await (await ethers.getContractFactory("BondingV2")).deploy(
    manager.address,
    bondingFormulas.address,
    [bondingZeroAccountAddress, bondingMinAccountAddress, bondingMaxAccountAddress],
    [0, bondingMinBalance, bondingMaxBalance],
    [1, 1, 208]
  )) as BondingV2;
  // send the LP token from bonding V1 to V2 to prepare the migration
  await bonding.sendDust(bondingV2.address, metaPool.address, bondingMinBalance.add(bondingMaxBalance));
  // set migrating state
  await bondingV2.setMigrating(true);
  // bondingV2 should have the UBQ_MINTER_ROLE to mint bonding shares
  await manager.connect(admin).grantRole(UBQ_MINTER_ROLE, bondingV2.address);
  await bondingV2.setBlockCountInAWeek(420);
  blockCountInAWeek = await bondingV2.blockCountInAWeek();
  await manager.setBondingContractAddress(bondingV2.address);

  await manager.connect(admin).revokeRole(UBQ_MINTER_ROLE, masterChef.address);
  await manager.connect(admin).revokeRole(UBQ_MINTER_ROLE, bonding.address);
  // bonding should have the UBQ_BURNER_ROLE to burn bonding shares
  await manager.connect(admin).revokeRole(UBQ_BURNER_ROLE, bonding.address);
  expect(await manager.connect(admin).hasRole(UBQ_MINTER_ROLE, bonding.address)).to.be.false;
  expect(await manager.connect(admin).hasRole(UBQ_MINTER_ROLE, masterChef.address)).to.be.false;

  return {
    curveWhale,
    masterChef,
    masterChefV2,
    bondingShareV2,
    bondingFormulas,
    bondingMaxBalance,
    bondingMinBalance,
    bondingV2,
    admin,
    crvToken,
    secondAccount,
    thirdAccount,
    fourthAccount,
    bondingZeroAccount,
    bondingMinAccount,
    bondingMaxAccount,
    fifthAccount,
    treasury,
    curvePoolFactory,
    uAD,
    uGOV,
    uAR,
    metaPool,
    bonding,
    bondingShare,
    couponsForDollarsCalculator,
    dollarMintingCalculator,
    debtCoupon,
    debtCouponMgr,
    twapOracle,
    ubiquityFormulas,
    DAI,
    USDC,
    manager,
    blockCountInAWeek,
    sushiUGOVPool,
    excessDollarsDistributor,
  };
}
export { bondingSetupV2, deposit, removeLiquidity, addLiquidity };
