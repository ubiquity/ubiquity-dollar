import { ContractInterface, ethers } from "ethers";

import IMetaPool from "@ubiquity/contracts/out/IMetaPool.sol/IMetaPool.json";

import UniswapV2PairABI from "../config/abis/UniswapV2Pair.json";
import UniswapV3RouterABI from "../config/abis/UniswapV3Router.json";
import UniswapV3PoolABI from "../config/abis/UniswapV3Pool.json";

import IJar from "@ubiquity/contracts/out/IJar.sol/IJar.json";
import ICurveFactory from "@ubiquity/contracts/out/ICurveFactory.sol/ICurveFactory.json";

// import UniswapV3RouterABI from "../config/abis/UniswapV3Router.json";
import ChainlinkPriceFeedABI from "../config/abis/ChainlinkPriceFeed.json";
import ERC20ABI from "../config/abis/ERC20.json";
import USDCTokenABI from "../config/abis/USDCToken.json";
import DAITokenABI from "../config/abis/DAIToken.json";
import USDTTokenABI from "../config/abis/USDTToken.json";

import YieldProxyABI from "../config/abis/YieldProxy.json";

import ABDKMath64x64 from "@ubiquity/contracts/out/ABDKMath64x64.sol/ABDKMath64x64.json";
// import ABDKMathQuad from "@ubiquity/contracts/out/ABDKMathQuad.sol/ABDKMathQuad.json";
import AccessControl from "@ubiquity/contracts/out/AccessControl.sol/AccessControl.json";
import AccessControlInternal from "@ubiquity/contracts/out/AccessControlInternal.sol/AccessControlInternal.json";
import AccessControlStorage from "@ubiquity/contracts/out/AccessControlStorage.sol/AccessControlStorage.json";
import Address from "@ubiquity/contracts/out/Address.sol/Address.json";
import AddressUtils from "@ubiquity/contracts/out/AddressUtils.sol/AddressUtils.json";
// import Base from "@ubiquity/contracts/out/Base.sol/Base.json";
import CollectableDust from "@ubiquity/contracts/out/CollectableDust.sol/CollectableDust.json";
// import console from "@ubiquity/contracts/out/console.sol/console.json";
// import console2 from "@ubiquity/contracts/out/console2.sol/console2.json";
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
// import DiamondTestSetup from "@ubiquity/contracts/out/DiamondTestSetup.sol/DiamondTestSetup.json";
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

import LibAppStorage from "@ubiquity/contracts/out/LibAppStorage.sol/LibAppStorage.json";
import LibDiamond from "@ubiquity/contracts/out/LibDiamond.sol/LibDiamond.json";
import LiveTestHelper from "@ubiquity/contracts/out/LiveTestHelper.sol/LiveTestHelper.json";
import LocalTestHelper from "@ubiquity/contracts/out/LocalTestHelper.sol/LocalTestHelper.json";
import LP from "@ubiquity/contracts/out/LP.sol/LP.json";
import ManagerFacet from "@ubiquity/contracts/out/ManagerFacet.sol/ManagerFacet.json";
import Math from "@ubiquity/contracts/out/Math.sol/Math.json";
// import MockBondingV1 from "@ubiquity/contracts/out/MockBondingV1.sol/MockBondingV1.json";
import MockCreditNft from "@ubiquity/contracts/out/MockCreditNft.sol/MockCreditNft.json";
import MockCreditToken from "@ubiquity/contracts/out/MockCreditToken.sol/MockCreditToken.json";
import MockDollarToken from "@ubiquity/contracts/out/MockDollarToken.sol/MockDollarToken.json";
import MockERC20 from "@ubiquity/contracts/out/MockERC20.sol/MockERC20.json";
import MockERC4626 from "@ubiquity/contracts/out/MockERC4626.sol/MockERC4626.json";
import MockIncentive from "@ubiquity/contracts/out/MockIncentive.sol/MockIncentive.json";
import MockMetaPool from "@ubiquity/contracts/out/MockMetaPool.sol/MockMetaPool.json";
// import MockShareV1 from "@ubiquity/contracts/out/MockShareV1.sol/MockShareV1.json";
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

const getContract = (abi: ContractInterface, address: string, provider: ethers.providers.Provider) => new ethers.Contract(address, abi, provider);

// export const getUniswapV2PairABIContract = (address: string, provider: ethers.providers.Provider) =>
// getContract(getUniswapV2PairABIContract, address, provider);
// export const getUniswapV3PoolABIContract = (address: string, provider: ethers.providers.Provider) =>
// getContract(getUniswapV3PoolABIContract, address, provider);
export const getUniswapV3RouterABIContract = (address: string, provider: ethers.providers.Provider) => getContract(UniswapV3RouterABI, address, provider);
export const getChainlinkPriceFeedABIContract = (address: string, provider: ethers.providers.Provider) => getContract(ChainlinkPriceFeedABI, address, provider);
export const getERC20ABIContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC20ABI, address, provider);
export const getUSDCTokenABIContract = (address: string, provider: ethers.providers.Provider) => getContract(USDCTokenABI, address, provider);
export const getDAITokenABIContract = (address: string, provider: ethers.providers.Provider) => getContract(DAITokenABI, address, provider);
export const getUSDTTokenABIContract = (address: string, provider: ethers.providers.Provider) => getContract(USDTTokenABI, address, provider);
export const getYieldProxyABIContract = (address: string, provider: ethers.providers.Provider) => getContract(YieldProxyABI, address, provider);
export const getABDKMath64x64Contract = (address: string, provider: ethers.providers.Provider) => getContract(ABDKMath64x64.abi, address, provider);
// export const getABDKMathQuadContract = (address: string, provider: ethers.providers.Provider) => getContract(ABDKMathQuad, address, provider);
export const getAccessControlContract = (address: string, provider: ethers.providers.Provider) => getContract(AccessControl.abi, address, provider);
export const getAccessControlInternalContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(AccessControlInternal.abi, address, provider);
export const getAccessControlStorageContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(AccessControlStorage.abi, address, provider);
export const getAddressContract = (address: string, provider: ethers.providers.Provider) => getContract(Address.abi, address, provider);
export const getAddressUtilsContract = (address: string, provider: ethers.providers.Provider) => getContract(AddressUtils.abi, address, provider);
// export const getBaseContract = (address: string, provider: ethers.providers.Provider) => getContract(Base, address, provider);
export const getCollectableDustContract = (address: string, provider: ethers.providers.Provider) => getContract(CollectableDust.abi, address, provider);
export const getContextContract = (address: string, provider: ethers.providers.Provider) => getContract(Context.abi, address, provider);
export const getCreditClockContract = (address: string, provider: ethers.providers.Provider) => getContract(CreditClock.abi, address, provider);
export const getCreditNftContract = (address: string, provider: ethers.providers.Provider) => getContract(CreditNft.abi, address, provider);
export const getCreditNftManagerContract = (address: string, provider: ethers.providers.Provider) => getContract(CreditNftManager.abi, address, provider);
export const getCreditNftRedemptionCalculatorContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CreditNftRedemptionCalculator.abi, address, provider);
export const getCreditRedemptionCalculatorContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CreditRedemptionCalculator.abi, address, provider);
export const getCurveDollarIncentiveContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CurveDollarIncentive.abi, address, provider);
export const getDefaultOperatorFiltererContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DefaultOperatorFilterer.abi, address, provider);
export const getDiamondContract = (address: string, provider: ethers.providers.Provider) => getContract(Diamond.abi, address, provider);
export const getDiamondCutFacetContract = (address: string, provider: ethers.providers.Provider) => getContract(DiamondCutFacet.abi, address, provider);
export const getDiamondInitContract = (address: string, provider: ethers.providers.Provider) => getContract(DiamondInit.abi, address, provider);
export const getDiamondLoupeFacetContract = (address: string, provider: ethers.providers.Provider) => getContract(DiamondLoupeFacet.abi, address, provider);
export const getDiamondTestHelperContract = (address: string, provider: ethers.providers.Provider) => getContract(DiamondTestHelper.abi, address, provider);
// export const getDiamondTestSetupContract = (address: string, provider: ethers.providers.Provider) => getContract(DiamondTestSetup, address, provider);
export const getDirectGovernanceFarmerContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DirectGovernanceFarmer.abi, address, provider);
export const getDollarMintCalculatorContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DollarMintCalculator.abi, address, provider);
export const getDollarMintExcessContract = (address: string, provider: ethers.providers.Provider) => getContract(DollarMintExcess.abi, address, provider);
export const getEnumerableSetContract = (address: string, provider: ethers.providers.Provider) => getContract(EnumerableSet.abi, address, provider);
export const getERC20Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC20.abi, address, provider);
export const getERC20BurnableContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC20Burnable.abi, address, provider);
export const getERC20PausableContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC20Pausable.abi, address, provider);
export const getERC20UbiquityContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC20Ubiquity.abi, address, provider);
export const getERC165Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC165.abi, address, provider);
export const getERC721Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC721.abi, address, provider);
export const getERC721BurnableContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC721Burnable.abi, address, provider);
export const getERC721EnumerableContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC721Enumerable.abi, address, provider);
export const getERC1155Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC1155.abi, address, provider);
export const getERC1155BurnableContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC1155Burnable.abi, address, provider);
export const getERC1155BurnableSetUriContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155BurnableSetUri.abi, address, provider);
export const getERC1155PausableContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC1155Pausable.abi, address, provider);
export const getERC1155PausableSetUriContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155PausableSetUri.abi, address, provider);
export const getERC1155ReceiverContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC1155Receiver.abi, address, provider);
export const getERC1155SetUriContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC1155SetUri.abi, address, provider);
export const getERC1155UbiquityContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC1155Ubiquity.abi, address, provider);
export const getERC4626Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC4626.abi, address, provider);
export const getLibAppStorageContract = (address: string, provider: ethers.providers.Provider) => getContract(LibAppStorage.abi, address, provider);
export const getLibDiamondContract = (address: string, provider: ethers.providers.Provider) => getContract(LibDiamond.abi, address, provider);
export const getLiveTestHelperContract = (address: string, provider: ethers.providers.Provider) => getContract(LiveTestHelper.abi, address, provider);
export const getLocalTestHelperContract = (address: string, provider: ethers.providers.Provider) => getContract(LocalTestHelper.abi, address, provider);
export const getLPContract = (address: string, provider: ethers.providers.Provider) => getContract(LP.abi, address, provider);
export const getManagerFacetContract = (address: string, provider: ethers.providers.Provider) => getContract(ManagerFacet.abi, address, provider);
export const getMathContract = (address: string, provider: ethers.providers.Provider) => getContract(Math.abi, address, provider);
// export const getMockBondingV1Contract = (address: string, provider: ethers.providers.Provider) => getContract(MockBondingV1, address, provider);
export const getMockCreditNftContract = (address: string, provider: ethers.providers.Provider) => getContract(MockCreditNft.abi, address, provider);
export const getMockCreditTokenContract = (address: string, provider: ethers.providers.Provider) => getContract(MockCreditToken.abi, address, provider);
export const getMockDollarTokenContract = (address: string, provider: ethers.providers.Provider) => getContract(MockDollarToken.abi, address, provider);
export const getMockERC20Contract = (address: string, provider: ethers.providers.Provider) => getContract(MockERC20.abi, address, provider);
export const getMockERC4626Contract = (address: string, provider: ethers.providers.Provider) => getContract(MockERC4626.abi, address, provider);
export const getMockIncentiveContract = (address: string, provider: ethers.providers.Provider) => getContract(MockIncentive.abi, address, provider);
export const getMockMetaPoolContract = (address: string, provider: ethers.providers.Provider) => getContract(MockMetaPool.abi, address, provider);
// export const getMockShareV1Contract = (address: string, provider: ethers.providers.Provider) => getContract(MockShareV1, address, provider);
export const getMockTWAPOracleDollar3poolContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockTWAPOracleDollar3pool.abi, address, provider);
export const getMockUBQmanagerContract = (address: string, provider: ethers.providers.Provider) => getContract(MockUBQmanager.abi, address, provider);
export const getOperatorFiltererContract = (address: string, provider: ethers.providers.Provider) => getContract(OperatorFilterer.abi, address, provider);
export const getOperatorFilterRegistryErrorsAndEventsContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(OperatorFilterRegistryErrorsAndEvents.abi, address, provider);
export const getOwnableContract = (address: string, provider: ethers.providers.Provider) => getContract(Ownable.abi, address, provider);
export const getOwnershipFacetContract = (address: string, provider: ethers.providers.Provider) => getContract(OwnershipFacet.abi, address, provider);
export const getPausableContract = (address: string, provider: ethers.providers.Provider) => getContract(Pausable.abi, address, provider);
export const getReentrancyGuardContract = (address: string, provider: ethers.providers.Provider) => getContract(ReentrancyGuard.abi, address, provider);
export const getSafeAddArrayContract = (address: string, provider: ethers.providers.Provider) => getContract(SafeAddArray.abi, address, provider);
export const getSafeERC20Contract = (address: string, provider: ethers.providers.Provider) => getContract(SafeERC20.abi, address, provider);
export const getSignedMathContract = (address: string, provider: ethers.providers.Provider) => getContract(SignedMath.abi, address, provider);
export const getSimpleBondContract = (address: string, provider: ethers.providers.Provider) => getContract(SimpleBond.abi, address, provider);
export const getStakingContract = (address: string, provider: ethers.providers.Provider) => getContract(Staking.abi, address, provider);
export const getStakingFormulasContract = (address: string, provider: ethers.providers.Provider) => getContract(StakingFormulas.abi, address, provider);
export const getStakingTokenContract = (address: string, provider: ethers.providers.Provider) => getContract(StakingShare.abi, address, provider);
export const getStdAssertionsContract = (address: string, provider: ethers.providers.Provider) => getContract(StdAssertions.abi, address, provider);
export const getStdChainsContract = (address: string, provider: ethers.providers.Provider) => getContract(StdChains.abi, address, provider);
export const getStdCheatsContract = (address: string, provider: ethers.providers.Provider) => getContract(StdCheats.abi, address, provider);
export const getStdErrorContract = (address: string, provider: ethers.providers.Provider) => getContract(StdError.abi, address, provider);
export const getStdJsonContract = (address: string, provider: ethers.providers.Provider) => getContract(StdJson.abi, address, provider);
export const getStdMathContract = (address: string, provider: ethers.providers.Provider) => getContract(StdMath.abi, address, provider);
export const getStdStorageContract = (address: string, provider: ethers.providers.Provider) => getContract(StdStorage.abi, address, provider);
export const getStdUtilsContract = (address: string, provider: ethers.providers.Provider) => getContract(StdUtils.abi, address, provider);
export const getStringsContract = (address: string, provider: ethers.providers.Provider) => getContract(Strings.abi, address, provider);
export const getStructuredLinkedListContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(StructuredLinkedList.abi, address, provider);
export const getSushiSwapPoolContract = (address: string, provider: ethers.providers.Provider) => getContract(SushiSwapPool.abi, address, provider);
export const getTWAPOracleDollar3poolContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(TWAPOracleDollar3pool.abi, address, provider);
export const getUARContract = (address: string, provider: ethers.providers.Provider) => getContract(UAR.abi, address, provider);
export const getUbiquiStickContract = (address: string, provider: ethers.providers.Provider) => getContract(UbiquiStick.abi, address, provider);
export const getUbiquiStickSaleContract = (address: string, provider: ethers.providers.Provider) => getContract(UbiquiStickSale.abi, address, provider);
export const getUbiquityChefContract = (address: string, provider: ethers.providers.Provider) => getContract(UbiquityChef.abi, address, provider);
export const getUbiquityCreditTokenContract = (address: string, provider: ethers.providers.Provider) => getContract(UbiquityCreditToken.abi, address, provider);
export const getUbiquityDollarManagerContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityDollarManager.abi, address, provider);
export const getUbiquityDollarTokenContract = (address: string, provider: ethers.providers.Provider) => getContract(UbiquityDollarToken.abi, address, provider);
export const getUbiquityFormulasContract = (address: string, provider: ethers.providers.Provider) => getContract(UbiquityFormulas.abi, address, provider);
export const getUbiquityGovernanceTokenContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityGovernanceToken.abi, address, provider);
export const getUintUtilsContract = (address: string, provider: ethers.providers.Provider) => getContract(UintUtils.abi, address, provider);
export const getVmContract = (address: string, provider: ethers.providers.Provider) => getContract(Vm.abi, address, provider);
export const getZozoVaultContract = (address: string, provider: ethers.providers.Provider) => getContract(ZozoVault.abi, address, provider);

export const getDollar3poolMarketContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(IMetaPool.abi, address, provider);
};
export const getUniswapV2PairABIContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UniswapV2PairABI, address, provider);
};
export const getUniswapV3PoolContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UniswapV3PoolABI, address, provider);
};
export const getUniswapV3RouterContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UniswapV3RouterABI, address, provider);
};
export const getCurveFactoryContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(ICurveFactory.abi, address, provider);
};
export const getIJarContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(IJar.abi, address, provider);
};
export const getYieldProxyContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(YieldProxyABI, address, provider);
};
