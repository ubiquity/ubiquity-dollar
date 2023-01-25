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

import type { AccessControl as IAccessControl } from "types/AccessControl";
import type { AccessControlInternal as IAccessControlInternal } from "types/AccessControlInternal";
import type { AddressUtils as IAddressUtils } from "types/AddressUtils";
import type { CollectableDust as ICollectableDust } from "types/CollectableDust";
import type { CreditClock as ICreditClock } from "types/CreditClock";
import type { CreditNft as ICreditNft } from "types/CreditNft";
import type { CreditNftManager as ICreditNftManager } from "types/CreditNftManager";
import type { CreditNftRedemptionCalculator as ICreditNftRedemptionCalculator } from "types/CreditNftRedemptionCalculator";
import type { CreditRedemptionCalculator as ICreditRedemptionCalculator } from "types/CreditRedemptionCalculator";
import type { CurveDollarIncentive as ICurveDollarIncentive } from "types/CurveDollarIncentive";
import type { DefaultOperatorFilterer as IDefaultOperatorFilterer } from "types/DefaultOperatorFilterer";
import type { Diamond as IDiamond } from "types/Diamond";
import type { DiamondCutFacet as IDiamondCutFacet } from "types/DiamondCutFacet";
import type { DiamondInit as IDiamondInit } from "types/DiamondInit";
import type { DiamondLoupeFacet as IDiamondLoupeFacet } from "types/DiamondLoupeFacet";
import type { DiamondTestHelper as IDiamondTestHelper } from "types/DiamondTestHelper";
import type { DirectGovernanceFarmer as IDirectGovernanceFarmer } from "types/DirectGovernanceFarmer";
import type { DollarMintCalculator as IDollarMintCalculator } from "types/DollarMintCalculator";
import type { DollarMintExcess as IDollarMintExcess } from "types/DollarMintExcess";
import type { EnumerableSet as IEnumerableSet } from "types/EnumerableSet";
import type { ERC1155 as IERC1155 } from "types/ERC1155";
import type { ERC1155Burnable as IERC1155Burnable } from "types/ERC1155Burnable";
import type { ERC1155BurnableSetUri as IERC1155BurnableSetUri } from "types/ERC1155BurnableSetUri";
import type { ERC1155Pausable as IERC1155Pausable } from "types/ERC1155Pausable";
import type { ERC1155PausableSetUri as IERC1155PausableSetUri } from "types/ERC1155PausableSetUri";
import type { ERC1155Receiver as IERC1155Receiver } from "types/ERC1155Receiver";
import type { ERC1155SetUri as IERC1155SetUri } from "types/ERC1155SetUri";
import type { ERC1155Ubiquity as IERC1155Ubiquity } from "types/ERC1155Ubiquity";
import type { ERC165 as IERC165 } from "types/ERC165";
import type { ERC20 as IERC20 } from "types/ERC20";
import type { ERC20Burnable as IERC20Burnable } from "types/ERC20Burnable";
import type { ERC20Pausable as IERC20Pausable } from "types/ERC20Pausable";
import type { ERC20Ubiquity as IERC20Ubiquity } from "types/ERC20Ubiquity";
import type { ERC4626 as IERC4626 } from "types/ERC4626";
import type { ERC721 as IERC721 } from "types/ERC721";
import type { ERC721Burnable as IERC721Burnable } from "types/ERC721Burnable";
import type { ERC721Enumerable as IERC721Enumerable } from "types/ERC721Enumerable";
import type { LibDiamond as ILibDiamond } from "types/LibDiamond";
import type { LiveTestHelper as ILiveTestHelper } from "types/LiveTestHelper";
import type { LP as ILP } from "types/LP";
import type { ManagerFacet as IManagerFacet } from "types/ManagerFacet";
import type { MockCreditNft as IMockCreditNft } from "types/MockCreditNft";
import type { MockCreditToken as IMockCreditToken } from "types/MockCreditToken";
import type { MockDollarToken as IMockDollarToken } from "types/MockDollarToken";
import type { MockERC20 as IMockERC20 } from "types/MockERC20";
import type { MockERC4626 as IMockERC4626 } from "types/MockERC4626";
import type { MockIncentive as IMockIncentive } from "types/MockIncentive";
import type { MockMetaPool as IMockMetaPool } from "types/MockMetaPool";
import type { MockTWAPOracleDollar3pool as IMockTWAPOracleDollar3pool } from "types/MockTWAPOracleDollar3pool";
import type { MockUBQmanager as IMockUBQmanager } from "types/MockUBQmanager";
import type { OperatorFilterer as IOperatorFilterer } from "types/OperatorFilterer";
import type { OperatorFilterRegistryErrorsAndEvents as IOperatorFilterRegistryErrorsAndEvents } from "types/OperatorFilterRegistryErrorsAndEvents";
import type { Ownable as IOwnable } from "types/Ownable";
import type { OwnershipFacet as IOwnershipFacet } from "types/OwnershipFacet";
import type { Pausable as IPausable } from "types/Pausable";

import type { SimpleBond as ISimpleBond } from "types/SimpleBond";
import type { Staking as IStaking } from "types/Staking";
import type { StakingFormulas as IStakingFormulas } from "types/StakingFormulas";
import type { StdAssertions as IStdAssertions } from "types/StdAssertions";

import type { SushiSwapPool as ISushiSwapPool } from "types/SushiSwapPool";
import type { TWAPOracleDollar3pool as ITWAPOracleDollar3pool } from "types/TWAPOracleDollar3pool";
import type { UAR as IUAR } from "types/UAR";
import type { UbiquiStick as IUbiquiStick } from "types/UbiquiStick";
import type { UbiquiStickSale as IUbiquiStickSale } from "types/UbiquiStickSale";
import type { UbiquityChef as IUbiquityChef } from "types/UbiquityChef";
import type { UbiquityCreditToken as IUbiquityCreditToken } from "types/UbiquityCreditToken";
import type { UbiquityDollarToken as IUbiquityDollarToken } from "types/UbiquityDollarToken";
import type { UbiquityFormulas as IUbiquityFormulas } from "types/UbiquityFormulas";
import type { UbiquityGovernanceToken as IUbiquityGovernanceToken } from "types/UbiquityGovernanceToken";
import type { UintUtils as IUintUtils } from "types/UintUtils";
import type { ZozoVault as IZozoVault } from "types/ZozoVault";

import type { UbiquityDollarManager as IUbiquityDollarManager } from "types/UbiquityDollarManager";

export const getUbiquityDollarManagerContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityDollarManager.abi, address, provider) as IUbiquityDollarManager["functions"]; // UbiquityDollarManager

export const getAccessControlContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(AccessControl.abi, address, provider) as IAccessControl["functions"]; // AccessControl
export const getAccessControlInternalContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(AccessControlInternal.abi, address, provider) as IAccessControlInternal["functions"]; // AccessControlInternal
export const getAddressUtilsContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(AddressUtils.abi, address, provider) as IAddressUtils["functions"]; // AddressUtils
export const getCollectableDustContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CollectableDust.abi, address, provider) as ICollectableDust["functions"]; // CollectableDust
export const getCreditClockContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CreditClock.abi, address, provider) as ICreditClock["functions"]; // CreditClock
export const getCreditNftContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CreditNft.abi, address, provider) as ICreditNft["functions"]; // CreditNft
export const getCreditNftManagerContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CreditNftManager.abi, address, provider) as ICreditNftManager["functions"]; // CreditNftManager
export const getCreditNftRedemptionCalculatorContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CreditNftRedemptionCalculator.abi, address, provider) as ICreditNftRedemptionCalculator["functions"]; // CreditNftRedemptionCalculator
export const getCreditRedemptionCalculatorContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CreditRedemptionCalculator.abi, address, provider) as ICreditRedemptionCalculator["functions"]; // CreditRedemptionCalculator
export const getCurveDollarIncentiveContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(CurveDollarIncentive.abi, address, provider) as ICurveDollarIncentive["functions"]; // CurveDollarIncentive
export const getDefaultOperatorFiltererContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DefaultOperatorFilterer.abi, address, provider) as IDefaultOperatorFilterer["functions"]; // DefaultOperatorFilterer
export const getDiamondContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(Diamond.abi, address, provider) as IDiamond["functions"]; // Diamond
export const getDiamondCutFacetContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DiamondCutFacet.abi, address, provider) as IDiamondCutFacet["functions"]; // DiamondCutFacet
export const getDiamondInitContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DiamondInit.abi, address, provider) as IDiamondInit["functions"]; // DiamondInit
export const getDiamondLoupeFacetContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DiamondLoupeFacet.abi, address, provider) as IDiamondLoupeFacet["functions"]; // DiamondLoupeFacet
export const getDiamondTestHelperContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DiamondTestHelper.abi, address, provider) as IDiamondTestHelper["functions"]; // DiamondTestHelper
export const getDirectGovernanceFarmerContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DirectGovernanceFarmer.abi, address, provider) as IDirectGovernanceFarmer["functions"]; // DirectGovernanceFarmer
export const getDollarMintCalculatorContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DollarMintCalculator.abi, address, provider) as IDollarMintCalculator["functions"]; // DollarMintCalculator
export const getDollarMintExcessContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(DollarMintExcess.abi, address, provider) as IDollarMintExcess["functions"]; // DollarMintExcess
export const getEnumerableSetContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(EnumerableSet.abi, address, provider) as IEnumerableSet["functions"]; // EnumerableSet
export const getERC20Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC20.abi, address, provider) as IERC20["functions"]; // ERC20
export const getERC20BurnableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC20Burnable.abi, address, provider) as IERC20Burnable["functions"]; // ERC20Burnable
export const getERC20PausableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC20Pausable.abi, address, provider) as IERC20Pausable["functions"]; // ERC20Pausable
export const getERC20UbiquityContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC20Ubiquity.abi, address, provider) as IERC20Ubiquity["functions"]; // ERC20Ubiquity
export const getERC165Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC165.abi, address, provider) as IERC165["functions"]; // ERC165
export const getERC721Contract = (address: string, provider: ethers.providers.Provider) => getContract(ERC721.abi, address, provider) as IERC721["functions"]; // ERC721
export const getERC721BurnableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC721Burnable.abi, address, provider) as IERC721Burnable["functions"]; // ERC721Burnable
export const getERC721EnumerableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC721Enumerable.abi, address, provider) as IERC721Enumerable["functions"]; // ERC721Enumerable
export const getERC1155Contract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155.abi, address, provider) as IERC1155["functions"]; // ERC1155
export const getERC1155BurnableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155Burnable.abi, address, provider) as IERC1155Burnable["functions"]; // ERC1155Burnable
export const getERC1155BurnableSetUriContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155BurnableSetUri.abi, address, provider) as IERC1155BurnableSetUri["functions"]; // ERC1155BurnableSetUri
export const getERC1155PausableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155Pausable.abi, address, provider) as IERC1155Pausable["functions"]; // ERC1155Pausable
export const getERC1155PausableSetUriContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155PausableSetUri.abi, address, provider) as IERC1155PausableSetUri["functions"]; // ERC1155PausableSetUri
export const getERC1155ReceiverContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155Receiver.abi, address, provider) as IERC1155Receiver["functions"]; // ERC1155Receiver
export const getERC1155SetUriContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155SetUri.abi, address, provider) as IERC1155SetUri["functions"]; // ERC1155SetUri
export const getERC1155UbiquityContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC1155Ubiquity.abi, address, provider) as IERC1155Ubiquity["functions"]; // ERC1155Ubiquity
export const getERC4626Contract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ERC4626.abi, address, provider) as IERC4626["functions"]; // ERC4626
export const getLibDiamondContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(LibDiamond.abi, address, provider) as ILibDiamond["functions"]; // LibDiamond
export const getLiveTestHelperContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(LiveTestHelper.abi, address, provider) as ILiveTestHelper["functions"]; // LiveTestHelper
export const getLPContract = (address: string, provider: ethers.providers.Provider) => getContract(LP.abi, address, provider) as ILP["functions"]; // LP
export const getManagerFacetContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ManagerFacet.abi, address, provider) as IManagerFacet["functions"]; // ManagerFacet
export const getMockCreditNftContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockCreditNft.abi, address, provider) as IMockCreditNft["functions"]; // MockCreditNft
export const getMockCreditTokenContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockCreditToken.abi, address, provider) as IMockCreditToken["functions"]; // MockCreditToken
export const getMockDollarTokenContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockDollarToken.abi, address, provider) as IMockDollarToken["functions"]; // MockDollarToken
export const getMockERC20Contract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockERC20.abi, address, provider) as IMockERC20["functions"]; // MockERC20
export const getMockERC4626Contract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockERC4626.abi, address, provider) as IMockERC4626["functions"]; // MockERC4626
export const getMockIncentiveContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockIncentive.abi, address, provider) as IMockIncentive["functions"]; // MockIncentive
export const getMockMetaPoolContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockMetaPool.abi, address, provider) as IMockMetaPool["functions"]; // MockMetaPool
export const getMockTWAPOracleDollar3poolContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockTWAPOracleDollar3pool.abi, address, provider) as IMockTWAPOracleDollar3pool["functions"]; // MockTWAPOracleDollar3pool
export const getMockUBQmanagerContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(MockUBQmanager.abi, address, provider) as IMockUBQmanager["functions"]; // MockUBQmanager
export const getOperatorFiltererContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(OperatorFilterer.abi, address, provider) as IOperatorFilterer["functions"]; // OperatorFilterer
export const getOperatorFilterRegistryErrorsAndEventsContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(OperatorFilterRegistryErrorsAndEvents.abi, address, provider) as IOperatorFilterRegistryErrorsAndEvents["functions"]; // OperatorFilterRegistryErrorsAndEvents
export const getOwnableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(Ownable.abi, address, provider) as IOwnable["functions"]; // Ownable
export const getOwnershipFacetContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(OwnershipFacet.abi, address, provider) as IOwnershipFacet["functions"]; // OwnershipFacet
export const getPausableContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(Pausable.abi, address, provider) as IPausable["functions"]; // Pausable
export const getSimpleBondContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(SimpleBond.abi, address, provider) as ISimpleBond["functions"]; // SimpleBond
export const getStakingContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(Staking.abi, address, provider) as IStaking["functions"]; // Staking
export const getStakingFormulasContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(StakingFormulas.abi, address, provider) as IStakingFormulas["functions"]; // StakingFormulas
export const getStdAssertionsContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(StdAssertions.abi, address, provider) as IStdAssertions["functions"]; // StdAssertions
export const getSushiSwapPoolContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(SushiSwapPool.abi, address, provider) as ISushiSwapPool["functions"]; // SushiSwapPool
export const getTWAPOracleDollar3poolContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(TWAPOracleDollar3pool.abi, address, provider) as ITWAPOracleDollar3pool["functions"]; // TWAPOracleDollar3pool
export const getUARContract = (address: string, provider: ethers.providers.Provider) => getContract(UAR.abi, address, provider) as IUAR["functions"]; // UAR
export const getUbiquiStickContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquiStick.abi, address, provider) as IUbiquiStick["functions"]; // UbiquiStick
export const getUbiquiStickSaleContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquiStickSale.abi, address, provider) as IUbiquiStickSale["functions"]; // UbiquiStickSale
export const getUbiquityChefContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityChef.abi, address, provider) as IUbiquityChef["functions"]; // UbiquityChef
export const getUbiquityCreditTokenContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityCreditToken.abi, address, provider) as IUbiquityCreditToken["functions"]; // UbiquityCreditToken
export const getUbiquityDollarTokenContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityDollarToken.abi, address, provider) as IUbiquityDollarToken["functions"]; // UbiquityDollarToken
export const getUbiquityFormulasContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityFormulas.abi, address, provider) as IUbiquityFormulas["functions"]; // UbiquityFormulas
export const getUbiquityGovernanceTokenContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UbiquityGovernanceToken.abi, address, provider) as IUbiquityGovernanceToken["functions"]; // UbiquityGovernanceToken
export const getUintUtilsContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UintUtils.abi, address, provider) as IUintUtils["functions"]; // UintUtils
export const getZozoVaultContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ZozoVault.abi, address, provider) as IZozoVault["functions"]; // ZozoVault
