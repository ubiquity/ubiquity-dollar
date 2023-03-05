/* eslint-disable no-unused-vars */
import { ContractInterface, ethers } from "ethers";
import UniswapV2PairABI from "../config/abis/UniswapV2Pair.json";
import UniswapV3PoolABI from "../config/abis/UniswapV3Pool.json";
import UniswapV3RouterABI from "../config/abis/UniswapV3Router.json";
import ChainlinkPriceFeedABI from "../config/abis/ChainlinkPriceFeed.json";
import ERC20ABI from "../config/abis/ERC20.json";
import USDCTokenABI from "../config/abis/USDCToken.json";
import DAITokenABI from "../config/abis/DAIToken.json";
import USDTTokenABI from "../config/abis/USDTToken.json";
import YieldProxyABI from "../config/abis/YieldProxy.json";
import _SimpleBond from "@ubiquity/contracts/out/SimpleBond.sol/SimpleBond.json";
import _UbiquiStick from "@ubiquity/contracts/out/UbiquiStick.sol/UbiquiStick.json";
import _UbiquiStickSale from "@ubiquity/contracts/out/UbiquiStickSale.sol/UbiquiStickSale.json";
import _ERC1155Ubiquity from "@ubiquity/contracts/out/ERC1155Ubiquity.sol/ERC1155Ubiquity.json";
import _IJar from "@ubiquity/contracts/out/IJar.sol/IJar.json";
import _DebtCouponManager from "@ubiquity/contracts/out/CreditNftManager.sol/CreditNftManager.json";
import _ICurveFactory from "@ubiquity/contracts/out/ICurveFactory.sol/ICurveFactory.json";
import _StakingToken from "@ubiquity/contracts/out/StakingShare.sol/StakingShare.json";
import _Staking from "@ubiquity/contracts/out/Staking.sol/Staking.json";
import _DebtCoupon from "@ubiquity/contracts/out/CreditNft.sol/CreditNft.json";
import _DollarMintCalculator from "@ubiquity/contracts/out/DollarMintCalculator.sol/DollarMintCalculator.json";
import _ICouponsForDollarsCalculator from "@ubiquity/contracts/out/ICreditNftRedemptionCalculator.sol/ICreditNftRedemptionCalculator.json";
import _IMetaPool from "@ubiquity/contracts/out/IMetaPool.sol/IMetaPool.json";
import _IUARForDollarsCalculator from "@ubiquity/contracts/out/ICreditRedemptionCalculator.sol/ICreditRedemptionCalculator.json";
import _MasterChefV2 from "@ubiquity/contracts/out/UbiquityChef.sol/UbiquityChef.json";
import _SushiSwapPool from "@ubiquity/contracts/out/SushiSwapPool.sol/SushiSwapPool.json";
import _TWAPOracle from "@ubiquity/contracts/out/TWAPOracleDollar3pool.sol/TWAPOracleDollar3pool.json";
import _UbiquityManager from "@ubiquity/contracts/out/UbiquityDollarManager.sol/UbiquityDollarManager.json";
import _Dollar from "@ubiquity/contracts/out/UbiquityDollarToken.sol/UbiquityDollarToken.json";
import _Credit from "@ubiquity/contracts/out/UbiquityCreditToken.sol/UbiquityCreditToken.json";
import _UbiquityFormulas from "@ubiquity/contracts/out/UbiquityFormulas.sol/UbiquityFormulas.json";
import _Governance from "@ubiquity/contracts/out/UbiquityGovernanceToken.sol/UbiquityGovernanceToken.json";

import {
  accessControlFacetTSol,
  chefFacetTSol,
  collectableDustFacetTSol,
  creditClockTSol,
  creditNftManagerFacetSol,
  creditNftManagerFacetTSol,
  creditNftRedemptionCalculatorFacetSol,
  creditNftRedemptionCalculatorFacetTSol,
  creditNftTSol,
  creditNftManagerTSol,
  creditNftRedemptionCalculatorTSol,
  creditRedemptionCalculatorTSol,
  curveDollarIncentiveTSol,
  diamondTestTSol,
  diamondTestSetupSol,
  directGovernanceFarmerTSol,
  dollarMintCalculatorTSol,
  dollarMintCalculatorFacetTSol,
  dollarMintExcessTSol,
  dollarMintExcessFacetTSol,
  dollarTokenFacetTSol,
  erc20UbiquityDollarTestTSol,
  iPickleControllerSol,
  iUbiquityGovernanceSol,
  libCreditNftManagerSol,
  localTestHelperSol,
  managerFacetTSol,
  migrateMetapoolTSol,
  mockShareV1Sol,
  ownershipFacetTSol,
  simpleBondTSol,
  stakingTSol,
  stakingFacetTSol,
  stakingFormulasTSol,
  stakingFormulasFacetTSol,
  stakingShareTSol,
  structuredLinkedListSol,
  twapOracleDollar3PoolTSol,
  twapOracleFacetTSol,
  ubiquiStickTSol,
  ubiquiStickSaleTSol,
  ubiquityChefTSol,
  ubiquityCreditTokenTSol,
  ubiquityDollarTokenTSol,
  ubiquityFormulasTSol,
  access,
  draftIerc20PermitSol,
  AccessControl,
  AccessControlFacet,
  AddressUtils,
  ChefFacet,
  CollectableDust,
  CollectableDustFacet,
  CreditClock,
  CreditNft,
  CreditNftManager,
  CreditNftRedemptionCalculator,
  CreditRedemptionCalculator,
  CreditRedemptionCalculatorFacet,
  CurveDollarIncentive,
  DefaultOperatorFilterer,
  Diamond,
  DiamondCutFacet,
  DiamondInit,
  DiamondLoupeFacet,
  DiamondTestHelper,
  DirectGovernanceFarmer,
  DollarMintCalculator,
  DollarMintCalculatorFacet,
  DollarMintExcess,
  DollarMintExcessFacet,
  DollarTokenFacet,
  ERC1155,
  ERC1155Burnable,
  ERC1155BurnableSetUri,
  ERC1155Pausable,
  ERC1155PausableSetUri,
  ERC1155Receiver,
  ERC1155SetUri,
  ERC1155Ubiquity,
  ERC1155UbiquityForDiamond,
  ERC165,
  ERC20,
  ERC20Burnable,
  ERC20ForFacet,
  ERC20Pausable,
  ERC20Ubiquity,
  ERC20UbiquityForDiamond,
  ERC4626,
  ERC721,
  ERC721Burnable,
  ERC721Enumerable,
  EnumerableSet,
  IAccessControl,
  ICollectableDust,
  ICreditNft,
  ICreditNftManager,
  ICreditNftRedemptionCalculator,
  ICreditRedemptionCalculator,
  ICurveFactory,
  IDepositZap,
  IDiamondCut,
  IDiamondLoupe,
  IDollarMintCalculator,
  IDollarMintExcess,
  IERC1155,
  IERC1155MetadataURI,
  IERC1155Receiver,
  IERC1155Ubiquity,
  IERC165,
  IERC173,
  IERC20,
  IERC20Metadata,
  IERC20Ubiquity,
  IERC4626,
  IERC721,
  IERC721Enumerable,
  IERC721Metadata,
  IERC721Receiver,
  IIncentive,
  IJar,
  IMasterChef,
  IMetaPool,
  IOperatorFilterRegistry,
  ISablier,
  ISimpleBond,
  IStableSwap3Pool,
  IStaking,
  IStakingShare,
  ISushiBar,
  ISushiMaker,
  ISushiMasterChef,
  ISushiSwapPool,
  ITWAPOracleDollar3pool,
  IUAR,
  IUBQManager,
  IUbiquiStick,
  IUbiquityChef,
  IUbiquityDollarManager,
  IUbiquityDollarToken,
  IUbiquityFormulas,
  IUniswapV2Factory,
  IUniswapV2Pair,
  IUniswapV2Router01,
  IUniswapV2Router02,
  LP,
  LibAccessControl,
  LibChef,
  LibCollectableDust,
  LibDiamond,
  LibDollar,
  LibStaking,
  LibTWAPOracle,
  LiveTestHelper,
  ManagerFacet,
  MockBondingShareV1,
  MockBondingShareV2,
  MockBondingV1,
  MockCreditNft,
  MockCreditToken,
  MockCurveFactory,
  MockDollarToken,
  MockERC20,
  MockERC4626,
  MockIncentive,
  MockMetaPool,
  MockStakingShare,
  MockTWAPOracleDollar3pool,
  MockUBQmanager,
  OperatorFilterer,
  Ownable,
  OwnershipFacet,
  Pausable,
  Script,
  SimpleBond,
  Staking,
  StakingFacet,
  StakingFormulas,
  StakingFormulasFacet,
  StakingShare,
  StakingShareForDiamond,
  SushiSwapPool,
  TWAPOracleDollar3pool,
  TWAPOracleDollar3poolFacet,
  UbiquiStick,
  UbiquiStickSale,
  UbiquityChef,
  UbiquityCreditToken,
  UbiquityCreditTokenForDiamond,
  UbiquityDollarManager,
  UbiquityDollarToken,
  UbiquityDollarTokenForDiamond,
  UbiquityFormulas,
  UbiquityGovernanceToken,
  UbiquityGovernanceTokenForDiamond,
  UintUtils,
  Vm,
  ZozoVault,
  AccessControlFacetTest,
  DepositStateChef,
  DepositStateChefTest,
  ZeroStateChef,
  ZeroStateChefTest,
  CollectableDustFacetTest,
  CreditClockTest,
  CreditNftManagerFacet,
  CreditNFTManagerFacetTest,
  CreditNftRedemptionCalculatorFacet,
  CreditNFTRedemptionCalculatorFacetTest,
  CreditNftTest,
  CreditNftManagerTest,
  CreditNFTRedemptionCalculatorTest,
  CreditRedemptionCalculatorTest,
  CurveDollarIncentiveTest,
  TestDiamond,
  DiamondSetup,
  DirectGovernanceFarmerHarness,
  DirectGovernanceFarmerTest,
  DollarMintCalculatorTest,
  DollarMintCalculatorFacetTest,
  DollarMintExcessHarness,
  DollarMintExcessTest,
  DollarMintExcessFacetTest,
  DollarTokenFacetTest,
  ERC20UbiquityDollarTest,
  IController,
  IUbiquityGovernanceToken,
  LibCreditNftManager,
  LocalTestHelper,
  MockCreditNftRedemptionCalculator,
  RemoteTestManagerFacet,
  MigrateMetapool,
  BondingShareForDiamond,
  OwnershipFacetTest,
  BondedState,
  BondedStateTest,
  StickerState,
  StickerStateTest,
  ZeroState,
  ZeroStateTest,
  DepositState,
  RemoteDepositStateTest,
  RemoteZeroStateTest,
  DepositStateStaking,
  DepositStateTest,
  ZeroStateStaking,
  ZeroStateStakingTest,
  StakingFormulasTest,
  StakingFormulasFacetTest,
  IStructureInterface,
  TWAPOracleDollar3poolTest,
  TWAPOracleDollar3poolFacetTest,
  UbiquiStickHarness,
  UbiquiStickTest,
  UbiquiStickSaleTest,
  UbiquityCreditTokenTest,
  UbiquityDollarTokenTest,
  UbiquityFormulasTest,
  IERC20Permit,
} from "types";
import { IRouter } from "@uniswap/smart-order-router";
import { Provider } from "@ethersproject/providers";

const getContract = (abi: ContractInterface, address: string, provider: Provider) => {
  return new ethers.Contract(address, abi, provider);
};

export const getUniswapV2PairContract = (address: string, provider: Provider) => {
  return getContract(UniswapV2PairABI, address, provider) as IUniswapV2Pair;
};

export const getUniswapV3PoolContract = (address: string, provider: Provider) => {
  return getContract(UniswapV3PoolABI, address, provider); // as UniswapV3Pool;
};
export const getUniswapV3RouterContract = (address: string, provider: Provider) => {
  return getContract(UniswapV3RouterABI, address, provider); // as ISwapRouter;
};

export const getChainlinkPriceFeedContract = (address: string, provider: Provider): ethers.Contract => {
  return getContract(ChainlinkPriceFeedABI, address, provider); // as ChainlinkPriceFeed;
};

export const getERC20Contract = (address: string, provider: Provider) => {
  return getContract(ERC20ABI, address, provider) as ERC20;
};

export const getERC1155UbiquityContract = (address: string, provider: Provider) => {
  return getContract(_ERC1155Ubiquity.abi, address, provider) as ERC1155Ubiquity;
};

export const getSimpleBondContract = (address: string, provider: Provider) => {
  return getContract(_SimpleBond.abi, address, provider) as SimpleBond;
};

export const getUbiquiStickContract = (address: string, provider: Provider) => {
  return getContract(_UbiquiStick.abi, address, provider) as UbiquiStick;
};

export const getUbiquiStickSaleContract = (address: string, provider: Provider) => {
  return getContract(_UbiquiStickSale.abi, address, provider) as UbiquiStickSale;
};

export const getIJarContract = (address: string, provider: Provider) => {
  return getContract(_IJar.abi, address, provider) as IJar;
};

export const getDebtCouponManagerContract = (address: string, provider: Provider) => {
  return getContract(_DebtCouponManager.abi, address, provider) as CreditNftManager;
};

export const getCurveFactoryContract = (address: string, provider: Provider) => {
  return getContract(_ICurveFactory.abi, address, provider) as ICurveFactory;
};

export const getYieldProxyContract = (address: string, provider: Provider) => {
  return getContract(YieldProxyABI, address, provider); // as YieldProxy;
};

export const getStakingShareContract = (address: string, provider: Provider) => {
  return getContract(_StakingToken.abi, address, provider) as StakingShare;
};

export const getBondingV2Contract = (address: string, provider: Provider) => {
  return getContract(_Staking.abi, address, provider) as Staking;
};

export const getDebtCouponContract = (address: string, provider: Provider) => {
  return getContract(_DebtCoupon.abi, address, provider) as CreditNft;
};

export const getTWAPOracleContract = (address: string, provider: Provider) => {
  return getContract(_TWAPOracle.abi, address, provider) as ITWAPOracleDollar3pool;
};

export const getDollarMintCalculatorContract = (address: string, provider: Provider) => {
  return getContract(_DollarMintCalculator.abi, address, provider) as DollarMintCalculator;
};

export const getICouponsForDollarsCalculatorContract = (address: string, provider: Provider) => {
  return getContract(_ICouponsForDollarsCalculator.abi, address, provider) as CreditNftRedemptionCalculator;
};

export const getIUARForDollarsCalculatorContract = (address: string, provider: Provider) => {
  return getContract(_IUARForDollarsCalculator.abi, address, provider) as CreditRedemptionCalculator;
};

export const getIMetaPoolContract = (address: string, provider: Provider) => {
  return getContract(_IMetaPool.abi, address, provider) as IMetaPool;
};

export const getMasterChefV2Contract = (address: string, provider: Provider) => {
  return getContract(_MasterChefV2.abi, address, provider) as UbiquityChef;
};

export const getSushiSwapPoolContract = (address: string, provider: Provider) => {
  return getContract(_SushiSwapPool.abi, address, provider) as SushiSwapPool;
};

export const getUbiquityManagerContract = (address: string, provider: Provider) => {
  return getContract(_UbiquityManager.abi, address, provider) as UbiquityDollarManager;
};

export const getDollarContract = (address: string, provider: Provider) => {
  return getContract(_Dollar.abi, address, provider) as UbiquityDollarToken;
};

export const getCreditContract = (address: string, provider: Provider) => {
  return getContract(_Credit.abi, address, provider) as UbiquityCreditToken;
};

export const getUbiquityFormulasContract = (address: string, provider: Provider) => {
  return getContract(_UbiquityFormulas.abi, address, provider) as UbiquityFormulas;
};

export const getGovernanceContract = (address: string, provider: Provider) => {
  return getContract(_Governance.abi, address, provider) as UbiquityGovernanceToken;
};

export const getUSDCTokenContract = (address: string, provider: Provider) => {
  return getContract(USDCTokenABI, address, provider) as ERC20;
};

export const getDAITokenContract = (address: string, provider: Provider) => {
  return getContract(DAITokenABI, address, provider) as ERC20;
};

export const getUSDTTokenContract = (address: string, provider: Provider) => {
  return getContract(USDTTokenABI, address, provider) as ERC20;
};
