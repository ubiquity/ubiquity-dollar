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

import ABDKMath64x64 from "@ubiquity/contracts/out/ABDKMath64x64.sol/ABDKMath64x64.json";
import ABDKMathQuad from "@ubiquity/contracts/out/ABDKMathQuad.sol/ABDKMathQuad.json";
import AccessControl from "@ubiquity/contracts/out/AccessControl.sol/AccessControl.json";
import AccessControlInternal from "@ubiquity/contracts/out/AccessControlInternal.sol/AccessControlInternal.json";
import AccessControlStorage from "@ubiquity/contracts/out/AccessControlStorage.sol/AccessControlStorage.json";
import Address from "@ubiquity/contracts/out/Address.sol/Address.json";
import AddressUtils from "@ubiquity/contracts/out/AddressUtils.sol/AddressUtils.json";
import Base from "@ubiquity/contracts/out/Base.sol/Base.json";
import CollectableDust from "@ubiquity/contracts/out/CollectableDust.sol/CollectableDust.json";
import console from "@ubiquity/contracts/out/console.sol/console.json";
import console2 from "@ubiquity/contracts/out/console2.sol/console2.json";
import Context from "@ubiquity/contracts/out/Context.sol/Context.json";
import CreditClock from "@ubiquity/contracts/out/CreditClock.sol/CreditClock.json";
import CreditNft from "@ubiquity/contracts/out/CreditNft.sol/CreditNft.json";
import CreditNftManager from "@ubiquity/contracts/out/CreditNftManager.sol/CreditNftManager.json";
import CreditNftRedemptionCalculator from "@ubiquity/contracts/out/CreditNftRedemptionCalculator.sol/CreditNftRedemptionCalculator.json";
import CreditRedemptionCalculator from "@ubiquity/contracts/out/CreditRedemptionCalculator.sol/CreditRedemptionCalculator.json";
import CurveDollarIncentive from "@ubiquity/contracts/out/CurveDollarIncentive.sol/CurveDollarIncentive.json";
import DefaultOperatorFilterer from "@ubiquity/contracts/out/DefaultOperatorFilterer.sol/DefaultOperatorFilterer.json";
import Diamond from "@ubiquity/contracts/out/Diamond.sol/Diamond.json";
import DiamondCutFacet from "@ubiquity/contracts/out/DiamondCutFacet.sol/DiamondCutFacet.json";
import DiamondInit from "@ubiquity/contracts/out/DiamondInit.sol/DiamondInit.json";
import DiamondLoupeFacet from "@ubiquity/contracts/out/DiamondLoupeFacet.sol/DiamondLoupeFacet.json";
import DiamondTestHelper from "@ubiquity/contracts/out/DiamondTestHelper.sol/DiamondTestHelper.json";
import DiamondTestSetup from "@ubiquity/contracts/out/DiamondTestSetup.sol/DiamondTestSetup.json";
import DirectGovernanceFarmer from "@ubiquity/contracts/out/DirectGovernanceFarmer.sol/DirectGovernanceFarmer.json";
import DollarMintCalculator from "@ubiquity/contracts/out/DollarMintCalculator.sol/DollarMintCalculator.json";
import DollarMintExcess from "@ubiquity/contracts/out/DollarMintExcess.sol/DollarMintExcess.json";
import EnumerableSet from "@ubiquity/contracts/out/EnumerableSet.sol/EnumerableSet.json";
import ERC20 from "@ubiquity/contracts/out/ERC20.sol/ERC20.json";
import ERC20Burnable from "@ubiquity/contracts/out/ERC20Burnable.sol/ERC20Burnable.json";
import ERC20Pausable from "@ubiquity/contracts/out/ERC20Pausable.sol/ERC20Pausable.json";
import ERC20Ubiquity from "@ubiquity/contracts/out/ERC20Ubiquity.sol/ERC20Ubiquity.json";
import ERC165 from "@ubiquity/contracts/out/ERC165.sol/ERC165.json";
import ERC721 from "@ubiquity/contracts/out/ERC721.sol/ERC721.json";
import ERC721Burnable from "@ubiquity/contracts/out/ERC721Burnable.sol/ERC721Burnable.json";
import ERC721Enumerable from "@ubiquity/contracts/out/ERC721Enumerable.sol/ERC721Enumerable.json";
import ERC1155 from "@ubiquity/contracts/out/ERC1155.sol/ERC1155.json";
import ERC1155Burnable from "@ubiquity/contracts/out/ERC1155Burnable.sol/ERC1155Burnable.json";
import ERC1155BurnableSetUri from "@ubiquity/contracts/out/ERC1155BurnableSetUri.sol/ERC1155BurnableSetUri.json";
import ERC1155Pausable from "@ubiquity/contracts/out/ERC1155Pausable.sol/ERC1155Pausable.json";
import ERC1155PausableSetUri from "@ubiquity/contracts/out/ERC1155PausableSetUri.sol/ERC1155PausableSetUri.json";
import ERC1155Receiver from "@ubiquity/contracts/out/ERC1155Receiver.sol/ERC1155Receiver.json";
import ERC1155SetUri from "@ubiquity/contracts/out/ERC1155SetUri.sol/ERC1155SetUri.json";
import ERC1155Ubiquity from "@ubiquity/contracts/out/ERC1155Ubiquity.sol/ERC1155Ubiquity.json";
import ERC4626 from "@ubiquity/contracts/out/ERC4626.sol/ERC4626.json";
import IAccessControl from "@ubiquity/contracts/out/IAccessControl.sol/IAccessControl.json";
import IAccessControlInternal from "@ubiquity/contracts/out/IAccessControlInternal.sol/IAccessControlInternal.json";
import ICollectableDust from "@ubiquity/contracts/out/ICollectableDust.sol/ICollectableDust.json";
import ICreditNft from "@ubiquity/contracts/out/ICreditNft.sol/ICreditNft.json";
import ICreditNftManager from "@ubiquity/contracts/out/ICreditNftManager.sol/ICreditNftManager.json";
import ICreditNftRedemptionCalculator from "@ubiquity/contracts/out/ICreditNftRedemptionCalculator.sol/ICreditNftRedemptionCalculator.json";
import ICreditRedemptionCalculator from "@ubiquity/contracts/out/ICreditRedemptionCalculator.sol/ICreditRedemptionCalculator.json";
import ICurveFactory from "@ubiquity/contracts/out/ICurveFactory.sol/ICurveFactory.json";
import IDepositZap from "@ubiquity/contracts/out/IDepositZap.sol/IDepositZap.json";
import IDiamondCut from "@ubiquity/contracts/out/IDiamondCut.sol/IDiamondCut.json";
import IDiamondLoupe from "@ubiquity/contracts/out/IDiamondLoupe.sol/IDiamondLoupe.json";
import IDollarMintCalculator from "@ubiquity/contracts/out/IDollarMintCalculator.sol/IDollarMintCalculator.json";
import IDollarMintExcess from "@ubiquity/contracts/out/IDollarMintExcess.sol/IDollarMintExcess.json";
import IERC20 from "@ubiquity/contracts/out/IERC20.sol/IERC20.json";
import IERC20Metadata from "@ubiquity/contracts/out/IERC20Metadata.sol/IERC20Metadata.json";
import IERC20Permit from "@ubiquity/contracts/out/IERC20Permit.sol/IERC20Permit.json";
import IERC20Ubiquity from "@ubiquity/contracts/out/IERC20Ubiquity.sol/IERC20Ubiquity.json";
import IERC165 from "@ubiquity/contracts/out/IERC165.sol/IERC165.json";
import IERC173 from "@ubiquity/contracts/out/IERC173.sol/IERC173.json";
import IERC721 from "@ubiquity/contracts/out/IERC721.sol/IERC721.json";
import IERC721Enumerable from "@ubiquity/contracts/out/IERC721Enumerable.sol/IERC721Enumerable.json";
import IERC721Metadata from "@ubiquity/contracts/out/IERC721Metadata.sol/IERC721Metadata.json";
import IERC721Receiver from "@ubiquity/contracts/out/IERC721Receiver.sol/IERC721Receiver.json";
import IERC1155 from "@ubiquity/contracts/out/IERC1155.sol/IERC1155.json";
import IERC1155MetadataURI from "@ubiquity/contracts/out/IERC1155MetadataURI.sol/IERC1155MetadataURI.json";
import IERC1155Receiver from "@ubiquity/contracts/out/IERC1155Receiver.sol/IERC1155Receiver.json";
import IERC1155Ubiquity from "@ubiquity/contracts/out/IERC1155Ubiquity.sol/IERC1155Ubiquity.json";
import IERC4626 from "@ubiquity/contracts/out/IERC4626.sol/IERC4626.json";
import IIncentive from "@ubiquity/contracts/out/IIncentive.sol/IIncentive.json";
import IJar from "@ubiquity/contracts/out/IJar.sol/IJar.json";
import IMasterChef from "@ubiquity/contracts/out/IMasterChef.sol/IMasterChef.json";
import IMetaPool from "@ubiquity/contracts/out/IMetaPool.sol/IMetaPool.json";
import IMulticall3 from "@ubiquity/contracts/out/IMulticall3.sol/IMulticall3.json";
import IOperatorFilterRegistry from "@ubiquity/contracts/out/IOperatorFilterRegistry.sol/IOperatorFilterRegistry.json";
import IPickleController from "@ubiquity/contracts/out/IPickleController.sol/IPickleController.json";
import ISablier from "@ubiquity/contracts/out/ISablier.sol/ISablier.json";
import ISimpleBond from "@ubiquity/contracts/out/ISimpleBond.sol/ISimpleBond.json";
import IStableSwap3Pool from "@ubiquity/contracts/out/IStableSwap3Pool.sol/IStableSwap3Pool.json";
import IStaking from "@ubiquity/contracts/out/IStaking.sol/IStaking.json";
import IStakingShare from "@ubiquity/contracts/out/IStakingShare.sol/IStakingShare.json";
import ISushiBar from "@ubiquity/contracts/out/ISushiBar.sol/ISushiBar.json";
import ISushiMaker from "@ubiquity/contracts/out/ISushiMaker.sol/ISushiMaker.json";
import ISushiMasterChef from "@ubiquity/contracts/out/ISushiMasterChef.sol/ISushiMasterChef.json";
import ISushiSwapPool from "@ubiquity/contracts/out/ISushiSwapPool.sol/ISushiSwapPool.json";
import ITWAPOracleDollar3pool from "@ubiquity/contracts/out/ITWAPOracleDollar3pool.sol/ITWAPOracleDollar3pool.json";
import IUAR from "@ubiquity/contracts/out/IUAR.sol/IUAR.json";
import IUbiquiStick from "@ubiquity/contracts/out/IUbiquiStick.sol/IUbiquiStick.json";
import IUbiquityChef from "@ubiquity/contracts/out/IUbiquityChef.sol/IUbiquityChef.json";
import IUbiquityDollarManager from "@ubiquity/contracts/out/IUbiquityDollarManager.sol/IUbiquityDollarManager.json";
import IUbiquityDollarToken from "@ubiquity/contracts/out/IUbiquityDollarToken.sol/IUbiquityDollarToken.json";
import IUbiquityFormulas from "@ubiquity/contracts/out/IUbiquityFormulas.sol/IUbiquityFormulas.json";
import IUbiquityGovernance from "@ubiquity/contracts/out/IUbiquityGovernance.sol/IUbiquityGovernance.json";
import IUBQManager from "@ubiquity/contracts/out/IUBQManager.sol/IUBQManager.json";
import IUniswapV2Factory from "@ubiquity/contracts/out/IUniswapV2Factory.sol/IUniswapV2Factory.json";
import IUniswapV2Pair from "@ubiquity/contracts/out/IUniswapV2Pair.sol/IUniswapV2Pair.json";
import IUniswapV2Router01 from "@ubiquity/contracts/out/IUniswapV2Router01.sol/IUniswapV2Router01.json";
import IUniswapV2Router02 from "@ubiquity/contracts/out/IUniswapV2Router02.sol/IUniswapV2Router02.json";
import LibAppStorage from "@ubiquity/contracts/out/LibAppStorage.sol/LibAppStorage.json";
import LibDiamond from "@ubiquity/contracts/out/LibDiamond.sol/LibDiamond.json";
import LiveTestHelper from "@ubiquity/contracts/out/LiveTestHelper.sol/LiveTestHelper.json";
import LocalTestHelper from "@ubiquity/contracts/out/LocalTestHelper.sol/LocalTestHelper.json";
import LP from "@ubiquity/contracts/out/LP.sol/LP.json";
import ManagerFacet from "@ubiquity/contracts/out/ManagerFacet.sol/ManagerFacet.json";
import Math from "@ubiquity/contracts/out/Math.sol/Math.json";
import MockBondingV1 from "@ubiquity/contracts/out/MockBondingV1.sol/MockBondingV1.json";
import MockCreditNft from "@ubiquity/contracts/out/MockCreditNft.sol/MockCreditNft.json";
import MockCreditToken from "@ubiquity/contracts/out/MockCreditToken.sol/MockCreditToken.json";
import MockDollarToken from "@ubiquity/contracts/out/MockDollarToken.sol/MockDollarToken.json";
import MockERC20 from "@ubiquity/contracts/out/MockERC20.sol/MockERC20.json";
import MockERC4626 from "@ubiquity/contracts/out/MockERC4626.sol/MockERC4626.json";
import MockIncentive from "@ubiquity/contracts/out/MockIncentive.sol/MockIncentive.json";
import MockMetaPool from "@ubiquity/contracts/out/MockMetaPool.sol/MockMetaPool.json";
import MockShareV1 from "@ubiquity/contracts/out/MockShareV1.sol/MockShareV1.json";
import MockTWAPOracleDollar3pool from "@ubiquity/contracts/out/MockTWAPOracleDollar3pool.sol/MockTWAPOracleDollar3pool.json";
import MockUBQmanager from "@ubiquity/contracts/out/MockUBQmanager.sol/MockUBQmanager.json";
import OperatorFilterer from "@ubiquity/contracts/out/OperatorFilterer.sol/OperatorFilterer.json";
import OperatorFilterRegistryErrorsAndEvents from "@ubiquity/contracts/out/OperatorFilterRegistryErrorsAndEvents.sol/OperatorFilterRegistryErrorsAndEvents.json";
import Ownable from "@ubiquity/contracts/out/Ownable.sol/Ownable.json";
import OwnershipFacet from "@ubiquity/contracts/out/OwnershipFacet.sol/OwnershipFacet.json";
import Pausable from "@ubiquity/contracts/out/Pausable.sol/Pausable.json";
import ReentrancyGuard from "@ubiquity/contracts/out/ReentrancyGuard.sol/ReentrancyGuard.json";
import SafeAddArray from "@ubiquity/contracts/out/SafeAddArray.sol/SafeAddArray.json";
import SafeERC20 from "@ubiquity/contracts/out/SafeERC20.sol/SafeERC20.json";
import SignedMath from "@ubiquity/contracts/out/SignedMath.sol/SignedMath.json";
import SimpleBond from "@ubiquity/contracts/out/SimpleBond.sol/SimpleBond.json";
import Staking from "@ubiquity/contracts/out/Staking.sol/Staking.json";
import StakingFormulas from "@ubiquity/contracts/out/StakingFormulas.sol/StakingFormulas.json";
import StakingShare from "@ubiquity/contracts/out/StakingShare.sol/StakingShare.json";
import StdAssertions from "@ubiquity/contracts/out/StdAssertions.sol/StdAssertions.json";
import StdChains from "@ubiquity/contracts/out/StdChains.sol/StdChains.json";
import StdCheats from "@ubiquity/contracts/out/StdCheats.sol/StdCheats.json";
import StdError from "@ubiquity/contracts/out/StdError.sol/StdError.json";
import StdJson from "@ubiquity/contracts/out/StdJson.sol/StdJson.json";
import StdMath from "@ubiquity/contracts/out/StdMath.sol/StdMath.json";
import StdStorage from "@ubiquity/contracts/out/StdStorage.sol/StdStorage.json";
import StdUtils from "@ubiquity/contracts/out/StdUtils.sol/StdUtils.json";
import Strings from "@ubiquity/contracts/out/Strings.sol/Strings.json";
import StructuredLinkedList from "@ubiquity/contracts/out/StructuredLinkedList.sol/StructuredLinkedList.json";
import SushiSwapPool from "@ubiquity/contracts/out/SushiSwapPool.sol/SushiSwapPool.json";
// import test from "@ubiquity/contracts/out/test.sol/test.json";
import TWAPOracleDollar3pool from "@ubiquity/contracts/out/TWAPOracleDollar3pool.sol/TWAPOracleDollar3pool.json";
import UAR from "@ubiquity/contracts/out/UAR.sol/UAR.json";
import UbiquiStick from "@ubiquity/contracts/out/UbiquiStick.sol/UbiquiStick.json";
import UbiquiStickSale from "@ubiquity/contracts/out/UbiquiStickSale.sol/UbiquiStickSale.json";
import UbiquityChef from "@ubiquity/contracts/out/UbiquityChef.sol/UbiquityChef.json";
import UbiquityCreditToken from "@ubiquity/contracts/out/UbiquityCreditToken.sol/UbiquityCreditToken.json";
import UbiquityDollarManager from "@ubiquity/contracts/out/UbiquityDollarManager.sol/UbiquityDollarManager.json";
import UbiquityDollarToken from "@ubiquity/contracts/out/UbiquityDollarToken.sol/UbiquityDollarToken.json";
import UbiquityFormulas from "@ubiquity/contracts/out/UbiquityFormulas.sol/UbiquityFormulas.json";
import UbiquityGovernanceToken from "@ubiquity/contracts/out/UbiquityGovernanceToken.sol/UbiquityGovernanceToken.json";
import UintUtils from "@ubiquity/contracts/out/UintUtils.sol/UintUtils.json";
import Vm from "@ubiquity/contracts/out/Vm.sol/Vm.json";
import ZozoVault from "@ubiquity/contracts/out/ZozoVault.sol/ZozoVault.json";

const getContract = (abi: ContractInterface, address: string, provider: ethers.providers.Provider) => {
  return new ethers.Contract(address, abi, provider);
};

export const getUniswapV2FactoryContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UniswapV2PairABI, address, provider);
};

export const getUniswapV3PoolContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UniswapV3PoolABI, address, provider);
};

export const getUniswapV3RouterContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UniswapV3RouterABI, address, provider);
};

export const getChainlinkPriceFeedContract = (address: string, provider: ethers.providers.Provider): ethers.Contract => {
  return getContract(ChainlinkPriceFeedABI, address, provider);
};

export const getERC20Contract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(ERC20ABI, address, provider);
};

export const getERC1155UbiquityContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(ERC1155Ubiquity.abi, address, provider);
};

export const getSimpleBondContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(SimpleBond.abi, address, provider);
};

export const getUbiquiStickContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquiStick.abi, address, provider);
};

export const getUbiquiStickSaleContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquiStickSale.abi, address, provider);
};

export const getIJarContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(IJar.abi, address, provider);
};

export const getDebtCouponManagerContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(DebtCouponManager.abi, address, provider);
};

export const getCurveFactoryContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(ICurveFactory.abi, address, provider);
};

export const getYieldProxyContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(YieldProxyABI, address, provider);
};

export const getBondingShareV2Contract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(BondingShareV2.abi, address, provider);
};

export const getBondingV2Contract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(BondingV2.abi, address, provider);
};

export const getDebtCouponContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(DebtCoupon.abi, address, provider);
};

export const getTWAPOracleContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(TWAPOracle.abi, address, provider);
};

export const getDollarMintCalculatorContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(DollarMintCalculator.abi, address, provider);
};

export const getICouponsForDollarsCalculatorContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(ICouponsForDollarsCalculator.abi, address, provider);
};

export const getIUARForDollarsCalculatorContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(IUARForDollarsCalculator.abi, address, provider);
};

export const getIMetaPoolContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(IMetaPool.abi, address, provider);
};

export const getMasterChefV2Contract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(MasterChefV2.abi, address, provider);
};

export const getSushiSwapPoolContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(SushiSwapPool.abi, address, provider);
};

export const getUbiquityAlgorithmicDollarManagerContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquityAlgorithmicDollarManager.abi, address, provider);
};

export const getUbiquityAlgorithmicDollarContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquityAlgorithmicDollar.abi, address, provider);
};

export const getUbiquityCreditContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquityCredit.abi, address, provider);
};

export const getUbiquityFormulasContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquityFormulas.abi, address, provider);
};

export const getUbqContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UBQ.abi, address, provider);
};

export const getUSDCTokenContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(USDCTokenABI, address, provider);
};

export const getDAITokenContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(DAITokenABI, address, provider);
};

export const getUSDTTokenContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(USDTTokenABI, address, provider);
};
