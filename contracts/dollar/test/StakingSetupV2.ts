import { expect } from "chai";
import { ContractTransaction, Signer, BigNumber } from "ethers";
import { ethers, getNamedAccounts, network } from "hardhat";
import { Staking } from "../artifacts/types/Staking";
import { StakingV2 } from "../artifacts/types/StakingV2";
import { StakingFormulas } from "../artifacts/types/StakingFormulas";
import { StakingShare } from "../artifacts/types/StakingShare";
import { StakingShareV2 } from "../artifacts/types/StakingShareV2";
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
let staking: Staking;
let stakingShare: StakingShare;
let stakingV2: StakingV2;
let stakingShareV2: StakingShareV2;
let masterChef: MasterChef;
let masterChefV2: MasterChefV2;
let manager: UbiquityAlgorithmicDollarManager;
let stakingMaxBalance: BigNumber;
let stakingMinBalance: BigNumber;
let uAD: UbiquityAlgorithmicDollar;
let stakingFormulas: StakingFormulas;
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
let stakingZeroAccount: Signer;
let stakingMinAccount: Signer;
let stakingMaxAccount: Signer;
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

const deployUADUGOVSushiPool = async (
  signer: Signer
): Promise<SushiSwapPool> => {
  const signerAdr = await signer.getAddress();
  // need some uGOV to provide liquidity
  await uGOV.mint(signerAdr, ethers.utils.parseEther("1000"));
  // need some uGOV to provide liquidity
  await uAD.mint(signerAdr, ethers.utils.parseEther("10000"));
  // add liquidity to the pair uAD-UGOV 1 UGOV = 10 UAD
  const blockBefore = await ethers.provider.getBlock(
    await ethers.provider.getBlockNumber()
  );
  // must allow to transfer token
  await uAD
    .connect(signer)
    .approve(routerAdr, ethers.utils.parseEther("10000"));
  await uGOV
    .connect(signer)
    .approve(routerAdr, ethers.utils.parseEther("1000"));
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
const deposit: IbondTokens = async function (
  signer: Signer,
  amount: BigNumber,
  duration: number
) {
  const signerAdr = await signer.getAddress();
  await metaPool.connect(signer).approve(stakingV2.address, amount);
  const signerLPBalanceBefore = await metaPool.balanceOf(signerAdr);
  const stakingLPBalanceBefore = await metaPool.balanceOf(stakingV2.address);
  const blockBefore = await ethers.provider.getBlock(
    await ethers.provider.getBlockNumber()
  );
  const curBlockCountInAWeek = await stakingV2.blockCountInAWeek();
  const endBlock =
    blockBefore.number + 1 + duration * curBlockCountInAWeek.toNumber();
  const zz1 = await stakingV2.stakingDiscountMultiplier(); // zz1 = zerozero1 = 0.001 ether = 10^16
  const shares = BigNumber.from(
    await ubiquityFormulas.durationMultiply(amount, duration, zz1)
  );
  const id = (await stakingShareV2.totalSupply()).add(1);
  const creationBlock = (await ethers.provider.getBlockNumber()) + 1;
  await expect(stakingV2.connect(signer).deposit(amount, duration))
    .to.emit(stakingShareV2, "TransferSingle")
    .withArgs(stakingV2.address, ethers.constants.AddressZero, signerAdr, id, 1)
    .and.to.emit(stakingV2, "Deposit")
    .withArgs(signerAdr, id, amount, shares, duration, endBlock);
  // 1 week = blockCountInAWeek blocks
  const signerLPBalanceAfter = await metaPool.balanceOf(signerAdr);
  const stakingLPBalanceAfter = await metaPool.balanceOf(stakingV2.address);
  expect(signerLPBalanceBefore).to.equal(signerLPBalanceAfter.add(amount));
  expect(stakingLPBalanceAfter).to.equal(stakingLPBalanceBefore.add(amount));
  const bsAmount: BigNumber = await stakingShareV2.balanceOf(signerAdr, id);
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

// withdraw staking shares of ID belonging to the signer and return the
// staking share balance of the signer
async function removeLiquidity(
  signer: Signer,
  id: BigNumber,
  amount: BigNumber
): Promise<Bond> {
  const signerAdr = await signer.getAddress();
  const bondAmount: BigNumber = await stakingShareV2.balanceOf(signerAdr, id);
  expect(bondAmount).to.equal(1);
  const bondBefore = await stakingShareV2.getBond(id);
  await metaPool.connect(signer).approve(stakingV2.address, amount);
  const bs = await masterChefV2.getStakingShareInfo(id);
  const bond = await stakingShareV2.getBond(id);
  const sharesToRemove = await stakingFormulas.sharesForLP(bond, bs, amount);
  const pendingLpRewards = await stakingV2.pendingLpRewards(id);

  await expect(stakingV2.connect(signer).removeLiquidity(amount, id))
    .to.emit(stakingV2, "RemoveLiquidityFromBond")
    .withArgs(signerAdr, id, amount, amount, pendingLpRewards, sharesToRemove);

  const bsAfter = await masterChefV2.getStakingShareInfo(id);
  expect(bsAfter[0]).to.equal(bs[0].sub(sharesToRemove));
  const pendingLpRewardsAfter = await stakingV2.pendingLpRewards(id);
  const bondAfter = await stakingShareV2.getBond(id);
  expect(pendingLpRewardsAfter).to.equal(0);
  expect(bondAfter.lpAmount).to.equal(bondBefore.lpAmount.sub(amount));
  return bondAfter;
}

// withdraw staking shares of ID belonging to the signer and return the
// staking share balance of the signer
async function addLiquidity(
  signer: Signer,
  id: BigNumber,
  amount: BigNumber,
  duration: number
): Promise<Bond> {
  const signerAdr = await signer.getAddress();
  const bondAmount: BigNumber = await stakingShareV2.balanceOf(signerAdr, id);
  expect(bondAmount).to.equal(1);
  await metaPool.connect(signer).approve(stakingV2.address, amount);
  const bondBefore = await stakingShareV2.getBond(id);
  const zz1 = await stakingV2.stakingDiscountMultiplier(); // zz1 = zerozero1 = 0.001 ether = 10^16

  const pendingLpRewards = await stakingV2.pendingLpRewards(id);

  const totalLpAfter = bondBefore.lpAmount.add(amount).add(pendingLpRewards);
  const shares = BigNumber.from(
    await ubiquityFormulas.durationMultiply(totalLpAfter, duration, zz1)
  );
  await expect(stakingV2.connect(signer).addLiquidity(amount, id, duration))
    .to.emit(stakingV2, "AddLiquidityFromBond")
    .withArgs(signerAdr, id, totalLpAfter, shares);
  const bs = await masterChefV2.getStakingShareInfo(id);
  expect(bs[0]).to.equal(shares);
  const bondAfter = await stakingShareV2.getBond(id);
  const pendingLpRewardsAfter = await stakingV2.pendingLpRewards(id);
  expect(pendingLpRewardsAfter).to.equal(0);
  expect(bondAfter.lpAmount).to.equal(totalLpAfter);
  return bondAfter;
}

async function stakingSetupV2(): Promise<{
  crvToken: ERC20;
  curveWhale: Signer;
  admin: Signer;
  secondAccount: Signer;
  thirdAccount: Signer;
  fourthAccount: Signer;
  fifthAccount: Signer;
  treasury: Signer;
  stakingZeroAccount: Signer;
  stakingMinAccount: Signer;
  stakingMaxAccount: Signer;
  stakingMinBalance: BigNumber;
  stakingMaxBalance: BigNumber;
  stakingFormulas: StakingFormulas;
  curvePoolFactory: ICurveFactory;
  uAD: UbiquityAlgorithmicDollar;
  uAR: UbiquityAutoRedeem;
  uGOV: UbiquityGovernance;
  metaPool: IMetaPool;
  staking: Staking;
  masterChef: MasterChef;
  stakingV2: StakingV2;
  masterChefV2: MasterChefV2;
  stakingShare: StakingShare;
  stakingShareV2: StakingShareV2;
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
  ({
    DAI,
    USDC,
    curveFactory,
    curve3CrvBasePool,
    curve3CrvToken,
    curveWhaleAddress,
  } = await getNamedAccounts());

  // GET first EOA account as admin Signer
  [
    admin,
    secondAccount,
    thirdAccount,
    treasury,
    fourthAccount,
    stakingZeroAccount,
    stakingMaxAccount,
    stakingMinAccount,
    fifthAccount,
  ] = await ethers.getSigners();
  router = (await ethers.getContractAt(
    "IUniswapV2Router02",
    routerAdr
  )) as IUniswapV2Router02;
  adminAddress = await admin.getAddress();
  secondAddress = await secondAccount.getAddress();
  const fourthAddress = await fourthAccount.getAddress();
  const stakingZeroAccountAddress = await stakingZeroAccount.getAddress();
  const stakingMinAccountAddress = await stakingMinAccount.getAddress();
  const stakingMaxAccountAddress = await stakingMaxAccount.getAddress();

  const UBQ_MINTER_ROLE = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE")
  );
  const UBQ_BURNER_ROLE = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("UBQ_BURNER_ROLE")
  );
  const UBQ_TOKEN_MANAGER_ROLE = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("UBQ_TOKEN_MANAGER_ROLE")
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
  ).deploy(manager.address, ethers.constants.AddressZero)) as Staking;
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
    stakingZeroAccountAddress,
    stakingMinAccountAddress,
    stakingMaxAccountAddress,
  ].map(
    async (receiver: string): Promise<ContractTransaction> =>
      uAD.mint(receiver, ethers.utils.parseEther("10000"))
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
  await crvToken
    .connect(curveWhale)
    .transfer(stakingMaxAccountAddress, ethers.utils.parseEther("10000"));
  await crvToken
    .connect(curveWhale)
    .transfer(stakingMinAccountAddress, ethers.utils.parseEther("10000"));
  await crvToken
    .connect(curveWhale)
    .transfer(fourthAddress, ethers.utils.parseEther("100000"));

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

  // set uAR for dollar Calculator
  const UARForDollarsCalculatorFactory = await ethers.getContractFactory(
    "UARForDollarsCalculator"
  );
  uarForDollarsCalculator = (await UARForDollarsCalculatorFactory.deploy(
    manager.address
  )) as UARForDollarsCalculator;

  await manager
    .connect(admin)
    .setUARCalculatorAddress(uarForDollarsCalculator.address);
  // set coupon for dollar Calculator
  const couponsForDollarsCalculatorFactory = await ethers.getContractFactory(
    "CouponsForDollarsCalculator"
  );
  couponsForDollarsCalculator =
    (await couponsForDollarsCalculatorFactory.deploy(
      manager.address
    )) as CouponsForDollarsCalculator;
  await manager
    .connect(admin)
    .setCouponCalculatorAddress(couponsForDollarsCalculator.address);
  // set Dollar Minting Calculator
  const dollarMintingCalculatorFactory = await ethers.getContractFactory(
    "DollarMintingCalculator"
  );
  dollarMintingCalculator = (await dollarMintingCalculatorFactory.deploy(
    manager.address
  )) as DollarMintingCalculator;
  await manager
    .connect(admin)
    .setDollarMintingCalculatorAddress(dollarMintingCalculator.address);
  // set debt coupon token
  const dcManagerFactory = await ethers.getContractFactory("DebtCouponManager");
  const debtCouponFactory = await ethers.getContractFactory("DebtCoupon");
  debtCoupon = (await debtCouponFactory.deploy(manager.address)) as DebtCoupon;

  await manager.connect(admin).setDebtCouponAddress(debtCoupon.address);
  debtCouponMgr = (await dcManagerFactory.deploy(
    manager.address,
    couponLengthBlocks
  )) as DebtCouponManager;

  // debtCouponMgr should have the COUPON_MANAGER role to mint debtCoupon
  const COUPON_MANAGER_ROLE = ethers.utils.keccak256(
    ethers.utils.toUtf8Bytes("COUPON_MANAGER")
  );

  await manager
    .connect(admin)
    .grantRole(COUPON_MANAGER_ROLE, debtCouponMgr.address);
  await manager
    .connect(admin)
    .grantRole(UBQ_MINTER_ROLE, debtCouponMgr.address);
  await manager
    .connect(admin)
    .grantRole(UBQ_BURNER_ROLE, debtCouponMgr.address);

  // to calculate the totalOutstanding debt we need to take into account autoRedeemToken.totalSupply
  const uARFactory = await ethers.getContractFactory("UbiquityAutoRedeem");
  uAR = (await uARFactory.deploy(manager.address)) as UbiquityAutoRedeem;
  await manager.setuARTokenAddress(uAR.address);

  // when the debtManager mint uAD it there is too much it distribute the excess to
  const excessDollarsDistributorFactory = await ethers.getContractFactory(
    "ExcessDollarsDistributor"
  );
  excessDollarsDistributor = (await excessDollarsDistributorFactory.deploy(
    manager.address
  )) as ExcessDollarsDistributor;
  await manager
    .connect(admin)
    .setExcessDollarsDistributor(
      debtCouponMgr.address,
      excessDollarsDistributor.address
    );

  // set treasury,uGOVFund and lpReward address needed for excessDollarsDistributor
  await manager.connect(admin).setTreasuryAddress(await treasury.getAddress());

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

  // add liquidity to the metapool
  // accounts need to approve metaPool for sending its uAD and 3CRV
  await uAD
    .connect(stakingMinAccount)
    .approve(metaPool.address, ethers.utils.parseEther("10000"));
  await crvToken
    .connect(stakingMinAccount)
    .approve(metaPool.address, ethers.utils.parseEther("10000"));
  await uAD
    .connect(stakingMaxAccount)
    .approve(metaPool.address, ethers.utils.parseEther("10000"));
  await crvToken
    .connect(stakingMaxAccount)
    .approve(metaPool.address, ethers.utils.parseEther("10000"));
  await uAD
    .connect(fourthAccount)
    .approve(metaPool.address, ethers.utils.parseEther("10000"));
  await crvToken
    .connect(fourthAccount)
    .approve(metaPool.address, ethers.utils.parseEther("10000"));

  const dyuAD2LP = await metaPool["calc_token_amount(uint256[2],bool)"](
    [ethers.utils.parseEther("100"), ethers.utils.parseEther("100")],
    true
  );
  await metaPool
    .connect(stakingMinAccount)
  ["add_liquidity(uint256[2],uint256)"](
    [ethers.utils.parseEther("100"), ethers.utils.parseEther("100")],
    dyuAD2LP.mul(99).div(100)
  );
  await metaPool
    .connect(stakingMaxAccount)
  ["add_liquidity(uint256[2],uint256)"](
    [ethers.utils.parseEther("100"), ethers.utils.parseEther("100")],
    dyuAD2LP.mul(99).div(100)
  );
  await metaPool
    .connect(fourthAccount)
  ["add_liquidity(uint256[2],uint256)"](
    [ethers.utils.parseEther("100"), ethers.utils.parseEther("100")],
    dyuAD2LP.mul(99).div(100)
  );
  stakingMinBalance = await metaPool.balanceOf(stakingMinAccountAddress);
  await metaPool
    .connect(stakingMinAccount)
    .approve(staking.address, stakingMinBalance);
  await staking.connect(stakingMinAccount).deposit(stakingMinBalance, 1);
  stakingMaxBalance = await metaPool.balanceOf(stakingMaxAccountAddress);
  await metaPool
    .connect(stakingMaxAccount)
    .approve(staking.address, stakingMaxBalance);
  await staking.connect(stakingMaxAccount).deposit(stakingMaxBalance, 208);
  const stakingMaxIds = await stakingShare.holderTokens(
    stakingMaxAccountAddress
  );
  expect(stakingMaxIds.length).to.equal(1);
  const bsMaxAmount = await stakingShare.balanceOf(
    stakingMaxAccountAddress,
    stakingMaxIds[0]
  );
  const stakingMinIds = await stakingShare.holderTokens(
    stakingMinAccountAddress
  );
  expect(stakingMinIds.length).to.equal(1);
  const bsMinAmount = await stakingShare.balanceOf(
    stakingMinAccountAddress,
    stakingMinIds[0]
  );
  expect(bsMinAmount).to.be.lt(bsMaxAmount);
  // DEPLOY MasterChefV2
  masterChefV2 = (await (
    await ethers.getContractFactory("MasterChefV2")
  ).deploy(manager.address, [], [], [])) as MasterChefV2;
  await manager.setMasterChefAddress(masterChefV2.address);
  await manager.grantRole(UBQ_MINTER_ROLE, masterChefV2.address);
  await manager.grantRole(UBQ_TOKEN_MANAGER_ROLE, adminAddress);
  await masterChefV2.setUGOVPerBlock(BigNumber.from(10).pow(18));
  const managerMasterChefV2Address = await manager.masterChefAddress();
  expect(masterChefV2.address).to.be.equal(managerMasterChefV2Address);

  // DEPLOY StakingShareV2 Contract
  const uri = `{
    "name": "Staking Share",
    "description": "Ubiquity Staking Share V2",
    "image": "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/"
  }`;
  stakingShareV2 = (await (
    await ethers.getContractFactory("StakingShareV2")
  ).deploy(manager.address, uri)) as StakingShareV2;

  await manager.setStakingShareAddress(stakingShareV2.address);
  const managerStakingShareAddress = await manager.stakingShareAddress();
  expect(stakingShareV2.address).to.be.equal(managerStakingShareAddress);

  // DEPLOY Staking Contract
  stakingFormulas = (await (
    await ethers.getContractFactory("StakingFormulas")
  ).deploy()) as StakingFormulas;

  stakingV2 = (await (
    await ethers.getContractFactory("StakingV2")
  ).deploy(
    manager.address,
    stakingFormulas.address,
    [
      stakingZeroAccountAddress,
      stakingMinAccountAddress,
      stakingMaxAccountAddress,
    ],
    [0, stakingMinBalance, stakingMaxBalance],
    [1, 1, 208]
  )) as StakingV2;
  // send the LP token from staking V1 to V2 to prepare the migration
  await staking.sendDust(
    stakingV2.address,
    metaPool.address,
    stakingMinBalance.add(stakingMaxBalance)
  );
  // set migrating state
  await stakingV2.setMigrating(true);
  // stakingV2 should have the UBQ_MINTER_ROLE to mint staking shares
  await manager.connect(admin).grantRole(UBQ_MINTER_ROLE, stakingV2.address);
  await stakingV2.setBlockCountInAWeek(420);
  blockCountInAWeek = await stakingV2.blockCountInAWeek();
  await manager.setStakingContractAddress(stakingV2.address);

  await manager.connect(admin).revokeRole(UBQ_MINTER_ROLE, masterChef.address);
  await manager.connect(admin).revokeRole(UBQ_MINTER_ROLE, staking.address);
  // staking should have the UBQ_BURNER_ROLE to burn staking shares
  await manager.connect(admin).revokeRole(UBQ_BURNER_ROLE, staking.address);
  expect(await manager.connect(admin).hasRole(UBQ_MINTER_ROLE, staking.address))
    .to.be.false;
  expect(
    await manager.connect(admin).hasRole(UBQ_MINTER_ROLE, masterChef.address)
  ).to.be.false;

  return {
    curveWhale,
    masterChef,
    masterChefV2,
    stakingShareV2,
    stakingFormulas,
    stakingMaxBalance,
    stakingMinBalance,
    stakingV2,
    admin,
    crvToken,
    secondAccount,
    thirdAccount,
    fourthAccount,
    stakingZeroAccount,
    stakingMinAccount,
    stakingMaxAccount,
    fifthAccount,
    treasury,
    curvePoolFactory,
    uAD,
    uGOV,
    uAR,
    metaPool,
    staking,
    stakingShare,
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
export { stakingSetupV2, deposit, removeLiquidity, addLiquidity };
