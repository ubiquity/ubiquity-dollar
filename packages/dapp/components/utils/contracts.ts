import AccessControl from "@ubiquity/contracts/out/AccessControl.sol/AccessControl.json";
import AccessControlInternal from "@ubiquity/contracts/out/AccessControlInternal.sol/AccessControlInternal.json";
import AddressUtils from "@ubiquity/contracts/out/AddressUtils.sol/AddressUtils.json";
import CollectableDust from "@ubiquity/contracts/out/CollectableDust.sol/CollectableDust.json";
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
import DirectGovernanceFarmer from "@ubiquity/contracts/out/DirectGovernanceFarmer.sol/DirectGovernanceFarmer.json";
import DollarMintCalculator from "@ubiquity/contracts/out/DollarMintCalculator.sol/DollarMintCalculator.json";
import DollarMintExcess from "@ubiquity/contracts/out/DollarMintExcess.sol/DollarMintExcess.json";
import EnumerableSet from "@ubiquity/contracts/out/EnumerableSet.sol/EnumerableSet.json";
import ERC1155 from "@ubiquity/contracts/out/ERC1155.sol/ERC1155.json";
import ERC1155Burnable from "@ubiquity/contracts/out/ERC1155Burnable.sol/ERC1155Burnable.json";
import ERC1155BurnableSetUri from "@ubiquity/contracts/out/ERC1155BurnableSetUri.sol/ERC1155BurnableSetUri.json";
import ERC1155Pausable from "@ubiquity/contracts/out/ERC1155Pausable.sol/ERC1155Pausable.json";
import ERC1155PausableSetUri from "@ubiquity/contracts/out/ERC1155PausableSetUri.sol/ERC1155PausableSetUri.json";
import ERC1155Receiver from "@ubiquity/contracts/out/ERC1155Receiver.sol/ERC1155Receiver.json";
import ERC1155SetUri from "@ubiquity/contracts/out/ERC1155SetUri.sol/ERC1155SetUri.json";
import ERC1155Ubiquity from "@ubiquity/contracts/out/ERC1155Ubiquity.sol/ERC1155Ubiquity.json";
import ERC165 from "@ubiquity/contracts/out/ERC165.sol/ERC165.json";
import ERC20 from "@ubiquity/contracts/out/ERC20.sol/ERC20.json";
import ERC20Burnable from "@ubiquity/contracts/out/ERC20Burnable.sol/ERC20Burnable.json";
import ERC20Pausable from "@ubiquity/contracts/out/ERC20Pausable.sol/ERC20Pausable.json";
import ERC20Ubiquity from "@ubiquity/contracts/out/ERC20Ubiquity.sol/ERC20Ubiquity.json";
import ERC4626 from "@ubiquity/contracts/out/ERC4626.sol/ERC4626.json";
import ERC721 from "@ubiquity/contracts/out/ERC721.sol/ERC721.json";
import ERC721Burnable from "@ubiquity/contracts/out/ERC721Burnable.sol/ERC721Burnable.json";
import ERC721Enumerable from "@ubiquity/contracts/out/ERC721Enumerable.sol/ERC721Enumerable.json";
import LibDiamond from "@ubiquity/contracts/out/LibDiamond.sol/LibDiamond.json";
import LiveTestHelper from "@ubiquity/contracts/out/LiveTestHelper.sol/LiveTestHelper.json";
import LP from "@ubiquity/contracts/out/LP.sol/LP.json";
import ManagerFacet from "@ubiquity/contracts/out/ManagerFacet.sol/ManagerFacet.json";
import MockCreditNft from "@ubiquity/contracts/out/MockCreditNft.sol/MockCreditNft.json";
import MockCreditToken from "@ubiquity/contracts/out/MockCreditToken.sol/MockCreditToken.json";
import MockDollarToken from "@ubiquity/contracts/out/MockDollarToken.sol/MockDollarToken.json";
import MockERC20 from "@ubiquity/contracts/out/MockERC20.sol/MockERC20.json";
import MockERC4626 from "@ubiquity/contracts/out/MockERC4626.sol/MockERC4626.json";
import MockIncentive from "@ubiquity/contracts/out/MockIncentive.sol/MockIncentive.json";
import MockMetaPool from "@ubiquity/contracts/out/MockMetaPool.sol/MockMetaPool.json";
import MockTWAPOracleDollar3pool from "@ubiquity/contracts/out/MockTWAPOracleDollar3pool.sol/MockTWAPOracleDollar3pool.json";
import MockUBQmanager from "@ubiquity/contracts/out/MockUBQmanager.sol/MockUBQmanager.json";
import OperatorFilterer from "@ubiquity/contracts/out/OperatorFilterer.sol/OperatorFilterer.json";
import OperatorFilterRegistryErrorsAndEvents from "@ubiquity/contracts/out/OperatorFilterRegistryErrorsAndEvents.sol/OperatorFilterRegistryErrorsAndEvents.json";
import Ownable from "@ubiquity/contracts/out/Ownable.sol/Ownable.json";
import OwnershipFacet from "@ubiquity/contracts/out/OwnershipFacet.sol/OwnershipFacet.json";
import Pausable from "@ubiquity/contracts/out/Pausable.sol/Pausable.json";
import SimpleBond from "@ubiquity/contracts/out/SimpleBond.sol/SimpleBond.json";
import Staking from "@ubiquity/contracts/out/Staking.sol/Staking.json";
import StakingFormulas from "@ubiquity/contracts/out/StakingFormulas.sol/StakingFormulas.json";
import StdAssertions from "@ubiquity/contracts/out/StdAssertions.sol/StdAssertions.json";
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
import ZozoVault from "@ubiquity/contracts/out/ZozoVault.sol/ZozoVault.json";
import { ContractInterface, ethers } from "ethers";

export const getContract = (abi: ContractInterface, address: string, provider: ethers.providers.Provider) =>
  new ethers.Contract(address, abi, provider) as unknown;

import { AccessControlInterface } from "types/AccessControl";
import { AccessControlInternalInterface } from "types/AccessControlInternal";
import { AddressUtilsInterface } from "types/AddressUtils";
import { CollectableDustInterface } from "types/CollectableDust";
import { CreditClockInterface } from "types/CreditClock";
import { CreditNftInterface } from "types/CreditNft";
import { CreditNftManagerInterface } from "types/CreditNftManager";
import { CreditNftRedemptionCalculatorInterface } from "types/CreditNftRedemptionCalculator";
import { CreditRedemptionCalculatorInterface } from "types/CreditRedemptionCalculator";
import { CurveDollarIncentiveInterface } from "types/CurveDollarIncentive";
import { DefaultOperatorFiltererInterface } from "types/DefaultOperatorFilterer";
import { DiamondInterface } from "types/Diamond";
import { DiamondCutFacetInterface } from "types/DiamondCutFacet";
import { DiamondInitInterface } from "types/DiamondInit";
import { DiamondLoupeFacetInterface } from "types/DiamondLoupeFacet";
import { DiamondTestHelperInterface } from "types/DiamondTestHelper";
import { DirectGovernanceFarmerInterface } from "types/DirectGovernanceFarmer";
import { DollarMintCalculatorInterface } from "types/DollarMintCalculator";
import { DollarMintExcessInterface } from "types/DollarMintExcess";
import { EnumerableSetInterface } from "types/EnumerableSet";
import { ERC1155Interface } from "types/ERC1155";
import { ERC1155BurnableInterface } from "types/ERC1155Burnable";
import { ERC1155BurnableSetUriInterface } from "types/ERC1155BurnableSetUri";
import { ERC1155PausableInterface } from "types/ERC1155Pausable";
import { ERC1155PausableSetUriInterface } from "types/ERC1155PausableSetUri";
import { ERC1155ReceiverInterface } from "types/ERC1155Receiver";
import { ERC1155SetUriInterface } from "types/ERC1155SetUri";
import { ERC1155UbiquityInterface } from "types/ERC1155Ubiquity";
import { ERC165Interface } from "types/ERC165";
import { ERC20Interface } from "types/ERC20";
import { ERC20BurnableInterface } from "types/ERC20Burnable";
import { ERC20PausableInterface } from "types/ERC20Pausable";
import { ERC20UbiquityInterface } from "types/ERC20Ubiquity";
import { ERC4626Interface } from "types/ERC4626";
import { ERC721Interface } from "types/ERC721";
import { ERC721BurnableInterface } from "types/ERC721Burnable";
import { ERC721EnumerableInterface } from "types/ERC721Enumerable";
import { LibDiamondInterface } from "types/LibDiamond";
import { LiveTestHelperInterface } from "types/LiveTestHelper";
import { LPInterface } from "types/LP";
import { ManagerFacetInterface } from "types/ManagerFacet";
import { MockCreditNftInterface } from "types/MockCreditNft";
import { MockCreditTokenInterface } from "types/MockCreditToken";
import { MockDollarTokenInterface } from "types/MockDollarToken";
import { MockERC20Interface } from "types/MockERC20";
import { MockERC4626Interface } from "types/MockERC4626";
import { MockIncentiveInterface } from "types/MockIncentive";
import { MockMetaPoolInterface } from "types/MockMetaPool";
import { MockTWAPOracleDollar3poolInterface } from "types/MockTWAPOracleDollar3pool";
import { MockUBQmanagerInterface } from "types/MockUBQmanager";
import { OperatorFiltererInterface } from "types/OperatorFilterer";
import { OperatorFilterRegistryErrorsAndEventsInterface } from "types/OperatorFilterRegistryErrorsAndEvents";
import { OwnableInterface } from "types/Ownable";
import { OwnershipFacetInterface } from "types/OwnershipFacet";
import { PausableInterface } from "types/Pausable";

import { SimpleBondInterface } from "types/SimpleBond";
import { StakingInterface } from "types/Staking";
import { StakingFormulasInterface } from "types/StakingFormulas";
import { StdAssertionsInterface } from "types/StdAssertions";

import { SushiSwapPoolInterface } from "types/SushiSwapPool";
import { TWAPOracleDollar3poolInterface } from "types/TWAPOracleDollar3pool";
import { UARInterface } from "types/UAR";
import { UbiquiStickInterface } from "types/UbiquiStick";
import { UbiquiStickSaleInterface } from "types/UbiquiStickSale";
import { UbiquityChefInterface } from "types/UbiquityChef";
import { UbiquityCreditTokenInterface } from "types/UbiquityCreditToken";
import { UbiquityDollarTokenInterface } from "types/UbiquityDollarToken";
import { UbiquityFormulasInterface } from "types/UbiquityFormulas";
import { UbiquityGovernanceTokenInterface } from "types/UbiquityGovernanceToken";
import { UintUtilsInterface } from "types/UintUtils";
import { ZozoVaultInterface } from "types/ZozoVault";

import { UbiquityDollarManagerInterface } from "types/UbiquityDollarManager";

export const getUbiquityDollarManagerContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityDollarManager.abi, address, provider) as UbiquityDollarManagerInterface; // UbiquityDollarManager

export const getAccessControlContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(AccessControl.abi, address, provider) as AccessControlInterface; // AccessControl
export const getAccessControlInternalContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(AccessControlInternal.abi, address, provider) as AccessControlInternalInterface; // AccessControlInternal
export const getAddressUtilsContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(AddressUtils.abi, address, provider) as AddressUtilsInterface; // AddressUtils
export const getCollectableDustContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CollectableDust.abi, address, provider) as CollectableDustInterface; // CollectableDust
export const getCreditClockContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CreditClock.abi, address, provider) as CreditClockInterface; // CreditClock
export const getCreditNftContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CreditNft.abi, address, provider) as CreditNftInterface; // CreditNft
export const getCreditNftManagerContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CreditNftManager.abi, address, provider) as CreditNftManagerInterface; // CreditNftManager
export const getCreditNftRedemptionCalculatorContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CreditNftRedemptionCalculator.abi, address, provider) as CreditNftRedemptionCalculatorInterface; // CreditNftRedemptionCalculator
export const getCreditRedemptionCalculatorContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CreditRedemptionCalculator.abi, address, provider) as CreditRedemptionCalculatorInterface; // CreditRedemptionCalculator
export const getCurveDollarIncentiveContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CurveDollarIncentive.abi, address, provider) as CurveDollarIncentiveInterface; // CurveDollarIncentive
export const getDefaultOperatorFiltererContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DefaultOperatorFilterer.abi, address, provider) as DefaultOperatorFiltererInterface; // DefaultOperatorFilterer
export const getDiamondContract = (address: string, provider: ethers.providers.Provider) => getContract(Diamond.abi, address, provider) as DiamondInterface; // Diamond
export const getDiamondCutFacetContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DiamondCutFacet.abi, address, provider) as DiamondCutFacetInterface; // DiamondCutFacet
export const getDiamondInitContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DiamondInit.abi, address, provider) as DiamondInitInterface; // DiamondInit
export const getDiamondLoupeFacetContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DiamondLoupeFacet.abi, address, provider) as DiamondLoupeFacetInterface; // DiamondLoupeFacet
export const getDiamondTestHelperContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DiamondTestHelper.abi, address, provider) as DiamondTestHelperInterface; // DiamondTestHelper
export const getDirectGovernanceFarmerContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DirectGovernanceFarmer.abi, address, provider) as DirectGovernanceFarmerInterface; // DirectGovernanceFarmer
export const getDollarMintCalculatorContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DollarMintCalculator.abi, address, provider) as DollarMintCalculatorInterface; // DollarMintCalculator
export const getDollarMintExcessContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DollarMintExcess.abi, address, provider) as DollarMintExcessInterface; // DollarMintExcess
export const getEnumerableSetContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(EnumerableSet.abi, address, provider) as EnumerableSetInterface; // EnumerableSet
export const getERC20Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC20.abi, address, provider) as ERC20Interface; // ERC20
export const getERC20BurnableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC20Burnable.abi, address, provider) as ERC20BurnableInterface; // ERC20Burnable
export const getERC20PausableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC20Pausable.abi, address, provider) as ERC20PausableInterface; // ERC20Pausable
export const getERC20UbiquityContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC20Ubiquity.abi, address, provider) as ERC20UbiquityInterface; // ERC20Ubiquity
export const getERC165Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC165.abi, address, provider) as ERC165Interface; // ERC165
export const getERC721Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC721.abi, address, provider) as ERC721Interface; // ERC721
export const getERC721BurnableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC721Burnable.abi, address, provider) as ERC721BurnableInterface; // ERC721Burnable
export const getERC721EnumerableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC721Enumerable.abi, address, provider) as ERC721EnumerableInterface; // ERC721Enumerable
export const getERC1155Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC1155.abi, address, provider) as ERC1155Interface; // ERC1155
export const getERC1155BurnableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155Burnable.abi, address, provider) as ERC1155BurnableInterface; // ERC1155Burnable
export const getERC1155BurnableSetUriContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155BurnableSetUri.abi, address, provider) as ERC1155BurnableSetUriInterface; // ERC1155BurnableSetUri
export const getERC1155PausableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155Pausable.abi, address, provider) as ERC1155PausableInterface; // ERC1155Pausable
export const getERC1155PausableSetUriContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155PausableSetUri.abi, address, provider) as ERC1155PausableSetUriInterface; // ERC1155PausableSetUri
export const getERC1155ReceiverContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155Receiver.abi, address, provider) as ERC1155ReceiverInterface; // ERC1155Receiver
export const getERC1155SetUriContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155SetUri.abi, address, provider) as ERC1155SetUriInterface; // ERC1155SetUri
export const getERC1155UbiquityContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155Ubiquity.abi, address, provider) as ERC1155UbiquityInterface; // ERC1155Ubiquity
export const getERC4626Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC4626.abi, address, provider) as ERC4626Interface; // ERC4626
export const getLibDiamondContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(LibDiamond.abi, address, provider) as LibDiamondInterface; // LibDiamond
export const getLiveTestHelperContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(LiveTestHelper.abi, address, provider) as LiveTestHelperInterface; // LiveTestHelper
export const getLPContract = (address: string, provider: ethers.providers.Provider) => getContract(LP.abi, address, provider) as LPInterface; // LP
export const getManagerFacetContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ManagerFacet.abi, address, provider) as ManagerFacetInterface; // ManagerFacet
export const getMockCreditNftContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockCreditNft.abi, address, provider) as MockCreditNftInterface; // MockCreditNft
export const getMockCreditTokenContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockCreditToken.abi, address, provider) as MockCreditTokenInterface; // MockCreditToken
export const getMockDollarTokenContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockDollarToken.abi, address, provider) as MockDollarTokenInterface; // MockDollarToken
export const getMockERC20Contract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockERC20.abi, address, provider) as MockERC20Interface; // MockERC20
export const getMockERC4626Contract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockERC4626.abi, address, provider) as MockERC4626Interface; // MockERC4626
export const getMockIncentiveContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockIncentive.abi, address, provider) as MockIncentiveInterface; // MockIncentive
export const getMockMetaPoolContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockMetaPool.abi, address, provider) as MockMetaPoolInterface; // MockMetaPool
export const getMockTWAPOracleDollar3poolContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockTWAPOracleDollar3pool.abi, address, provider) as MockTWAPOracleDollar3poolInterface; // MockTWAPOracleDollar3pool
export const getMockUBQmanagerContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockUBQmanager.abi, address, provider) as MockUBQmanagerInterface; // MockUBQmanager
export const getOperatorFiltererContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(OperatorFilterer.abi, address, provider) as OperatorFiltererInterface; // OperatorFilterer
export const getOperatorFilterRegistryErrorsAndEventsContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(OperatorFilterRegistryErrorsAndEvents.abi, address, provider) as OperatorFilterRegistryErrorsAndEventsInterface; // OperatorFilterRegistryErrorsAndEvents
export const getOwnableContract = (address: string, provider: ethers.providers.Provider) => getContract(Ownable.abi, address, provider) as OwnableInterface; // Ownable
export const getOwnershipFacetContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(OwnershipFacet.abi, address, provider) as OwnershipFacetInterface; // OwnershipFacet
export const getPausableContract = (address: string, provider: ethers.providers.Provider) => getContract(Pausable.abi, address, provider) as PausableInterface; // Pausable
export const getSimpleBondContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(SimpleBond.abi, address, provider) as SimpleBondInterface; // SimpleBond
export const getStakingContract = (address: string, provider: ethers.providers.Provider) => getContract(Staking.abi, address, provider) as StakingInterface; // Staking
export const getStakingFormulasContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(StakingFormulas.abi, address, provider) as StakingFormulasInterface; // StakingFormulas
export const getStdAssertionsContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(StdAssertions.abi, address, provider) as StdAssertionsInterface; // StdAssertions
export const getSushiSwapPoolContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(SushiSwapPool.abi, address, provider) as SushiSwapPoolInterface; // SushiSwapPool
export const getTWAPOracleDollar3poolContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(TWAPOracleDollar3pool.abi, address, provider) as TWAPOracleDollar3poolInterface; // TWAPOracleDollar3pool
export const getUARContract = (address: string, provider: ethers.providers.Provider) => getContract(UAR.abi, address, provider) as UARInterface; // UAR
export const getUbiquiStickContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquiStick.abi, address, provider) as UbiquiStickInterface; // UbiquiStick
export const getUbiquiStickSaleContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquiStickSale.abi, address, provider) as UbiquiStickSaleInterface; // UbiquiStickSale
export const getUbiquityChefContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityChef.abi, address, provider) as UbiquityChefInterface; // UbiquityChef
export const getUbiquityCreditTokenContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityCreditToken.abi, address, provider) as UbiquityCreditTokenInterface; // UbiquityCreditToken
export const getUbiquityDollarTokenContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityDollarToken.abi, address, provider) as UbiquityDollarTokenInterface; // UbiquityDollarToken
export const getUbiquityFormulasContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityFormulas.abi, address, provider) as UbiquityFormulasInterface; // UbiquityFormulas
export const getUbiquityGovernanceTokenContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityGovernanceToken.abi, address, provider) as UbiquityGovernanceTokenInterface; // UbiquityGovernanceToken
export const getUintUtilsContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UintUtils.abi, address, provider) as UintUtilsInterface; // UintUtils
export const getZozoVaultContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ZozoVault.abi, address, provider) as ZozoVaultInterface; // ZozoVault
