import { Provider } from "@ethersproject/providers";
import { Contract, ethers } from "ethers";

import latestDeployment from "@ubiquity/contracts/broadcast/05_StakingShare.s.sol/31337/run-latest.json";
import useWeb3 from "../use-web-3";
import { sushiSwapPoolAddress, dollar3poolMarketAddress, _3crvTokenAddress } from "@/lib/utils";

// contract build artifacts
// separately deployed contracts
import CreditNftArtifact from "@ubiquity/contracts/out/CreditNft.sol/CreditNft.json";
import StakingShareArtifact from "@ubiquity/contracts/out/StakingShare.sol/StakingShare.json";
import UbiquityCreditTokenArtifact from "@ubiquity/contracts/out/UbiquityCreditToken.sol/UbiquityCreditToken.json";
import UbiquityDollarTokenArtifact from "@ubiquity/contracts/out/UbiquityDollarToken.sol/UbiquityDollarToken.json";
import UbiquityGovernanceTokenArtifact from "@ubiquity/contracts/out/UbiquityGovernanceToken.sol/UbiquityGovernanceToken.json";
// diamond facets
import AccessControlFacetArtifact from "@ubiquity/contracts/out/AccessControlFacet.sol/AccessControlFacet.json";
import ChefFacetArtifact from "@ubiquity/contracts/out/ChefFacet.sol/ChefFacet.json";
import CollectableDustFacetArtifact from "@ubiquity/contracts/out/CollectableDustFacet.sol/CollectableDustFacet.json";
import CreditNftManagerFacetArtifact from "@ubiquity/contracts/out/CreditNftManagerFacet.sol/CreditNftManagerFacet.json";
import CreditNftRedemptionCalculatorFacetArtifact from "@ubiquity/contracts/out/CreditNftRedemptionCalculatorFacet.sol/CreditNftRedemptionCalculatorFacet.json";
import CreditRedemptionCalculatorFacetArtifact from "@ubiquity/contracts/out/CreditRedemptionCalculatorFacet.sol/CreditRedemptionCalculatorFacet.json";
import CurveDollarIncentiveFacetArtifact from "@ubiquity/contracts/out/CurveDollarIncentiveFacet.sol/CurveDollarIncentiveFacet.json";
import DollarMintCalculatorFacetArtifact from "@ubiquity/contracts/out/DollarMintCalculatorFacet.sol/DollarMintCalculatorFacet.json";
import DollarMintExcessFacetArtifact from "@ubiquity/contracts/out/DollarMintExcessFacet.sol/DollarMintExcessFacet.json";
import ManagerFacetArtifact from "@ubiquity/contracts/out/ManagerFacet.sol/ManagerFacet.json";
import OwnershipFacetArtifact from "@ubiquity/contracts/out/OwnershipFacet.sol/OwnershipFacet.json";
import StakingFacetArtifact from "@ubiquity/contracts/out/StakingFacet.sol/StakingFacet.json";
import StakingFormulasFacetArtifact from "@ubiquity/contracts/out/StakingFormulasFacet.sol/StakingFormulasFacet.json";
import TWAPOracleDollar3poolFacetArtifact from "@ubiquity/contracts/out/TWAPOracleDollar3poolFacet.sol/TWAPOracleDollar3poolFacet.json";
import UbiquityPoolFacetArtifact from "@ubiquity/contracts/out/UbiquityPoolFacet.sol/UbiquityPoolFacet.json";
// other related contracts
// import SushiSwapPoolArtifact from "@ubiquity/contracts/out/SushiSwapPool.sol/SushiSwapPool.json";
import IMetaPoolArtifact from "@ubiquity/contracts/out/IMetaPool.sol/IMetaPool.json";
import UniswapV2PairABI from "@/components/config/abis/uniswap-v-2-pair.json";
import ERC20ABI from "@/components/config/abis/erc-20.json";

/**
 * Returns all of the available protocol contracts
 *
 * Right now the Ubiquity org uses:
 * - separately deployed contracts (https://github.com/ubiquity/ubiquity-dollar/tree/development/packages/contracts/src/dollar/core)
 * - contracts deployed as diamond proxy facets (https://github.com/ubiquity/ubiquity-dollar/tree/development/packages/contracts/src/dollar/facets)
 *
 * The following contracts are not exported for various reasons (but feel free
 * to export new contracts when you need them):
 *
 * Contracts not used in the UI (as far as I understand):
 * - https://github.com/ubiquity/ubiquity-dollar/blob/development/packages/contracts/src/dollar/core/ERC1155Ubiquity.sol
 * - https://github.com/ubiquity/ubiquity-dollar/blob/development/packages/contracts/src/dollar/core/ERC20Ubiquity.sol
 * - https://github.com/ubiquity/ubiquity-dollar/blob/development/packages/contracts/src/dollar/facets/DiamondCutFacet.sol
 * - https://github.com/ubiquity/ubiquity-dollar/blob/development/packages/contracts/src/dollar/facets/DiamondLoupeFacet.sol
 * - https://github.com/ubiquity/ubiquity-dollar/blob/development/packages/contracts/src/dollar/Diamond.sol
 * - https://github.com/ubiquity/ubiquity-dollar/blob/development/packages/contracts/src/dollar/DirectGovernanceFarmer.sol
 *
 * Contracts not yet integrated (i.e. not used in other solidity contracts):
 * - https://github.com/ubiquity/ubiquity-dollar/blob/development/packages/contracts/src/dollar/core/CreditClock.sol
 *
 * Contracts on hold (i.e. obsolete) until we find a better utility for them:
 * - https://github.com/ubiquity/ubiquity-dollar/tree/development/packages/contracts/src/ubiquistick
 */
export type ProtocolContracts = ReturnType<typeof useProtocolContracts> | null;
const useProtocolContracts = async () => {
  // get current web3 provider
  const { provider } = useWeb3();

  // all protocol contracts
  const protocolContracts: {
    // separately deployed contracts (i.e. not part of the diamond)
    creditNft: Contract | null;
    creditToken: Contract | null;
    dollarToken: Contract | null;
    governanceToken: Contract | null;
    stakingShare: Contract | null;
    // diamond facets
    accessControlFacet: Contract | null;
    chefFacet: Contract | null;
    collectableDustFacet: Contract | null;
    creditNftManagerFacet: Contract | null;
    creditNftRedemptionCalculatorFacet: Contract | null;
    creditRedemptionCalculatorFacet: Contract | null;
    curveDollarIncentiveFacet: Contract | null;
    dollarMintCalculatorFacet: Contract | null;
    dollarMintExcessFacet: Contract | null;
    managerFacet: Contract | null;
    ownershipFacet: Contract | null;
    stakingFacet: Contract | null;
    stakingFormulasFacet: Contract | null;
    twapOracleDollar3poolFacet: Contract | null;
    ubiquityPoolFacet: Contract | null;
    sushiPoolGovernanceDollarLp: Contract | null;
    curveMetaPoolDollarTriPoolLp: Contract | null;
    _3crvToken: Contract | null;
  } = {
    // separately deployed contracts (i.e. not part of the diamond)
    creditNft: null,
    creditToken: null,
    dollarToken: null,
    governanceToken: null,
    stakingShare: null,
    // diamond facets
    accessControlFacet: null,
    chefFacet: null,
    collectableDustFacet: null,
    creditNftManagerFacet: null,
    creditNftRedemptionCalculatorFacet: null,
    creditRedemptionCalculatorFacet: null,
    curveDollarIncentiveFacet: null,
    dollarMintCalculatorFacet: null,
    dollarMintExcessFacet: null,
    managerFacet: null,
    ownershipFacet: null,
    stakingFacet: null,
    stakingFormulasFacet: null,
    twapOracleDollar3poolFacet: null,
    ubiquityPoolFacet: null,
    // related contracts
    sushiPoolGovernanceDollarLp: null,
    curveMetaPoolDollarTriPoolLp: null,
    _3crvToken: null,
  };
  let diamondAddress = "";

  // for all of the deployment transactions
  latestDeployment.transactions.map((tx) => {
    if (tx.transactionType === "CREATE") {
      // find contracts that deployed separately (i.e. not part of the diamond)
      if (tx.contractName === "CreditNft") {
        protocolContracts.creditNft = new ethers.Contract(tx.contractAddress, CreditNftArtifact.abi, <Provider>provider);
      }
      if (tx.contractName === "UbiquityCreditToken") {
        protocolContracts.creditToken = new ethers.Contract(tx.contractAddress, UbiquityCreditTokenArtifact.abi, <Provider>provider);
      }
      if (tx.contractName === "UbiquityDollarToken") {
        protocolContracts.dollarToken = new ethers.Contract(tx.contractAddress, UbiquityDollarTokenArtifact.abi, <Provider>provider);
      }
      if (tx.contractName === "UbiquityGovernanceToken") {
        protocolContracts.governanceToken = new ethers.Contract(tx.contractAddress, UbiquityGovernanceTokenArtifact.abi, <Provider>provider);
      }
      if (tx.contractName === "StakingShare") {
        protocolContracts.stakingShare = new ethers.Contract(tx.contractAddress, StakingShareArtifact.abi, <Provider>provider);
      }
      // find the diamond address
      if (tx.contractName === "Diamond") diamondAddress = tx.contractAddress;
    }
  });

  // assign diamond facets
  protocolContracts.accessControlFacet = new ethers.Contract(diamondAddress, AccessControlFacetArtifact.abi, <Provider>provider);
  protocolContracts.chefFacet = new ethers.Contract(diamondAddress, ChefFacetArtifact.abi, <Provider>provider);
  protocolContracts.collectableDustFacet = new ethers.Contract(diamondAddress, CollectableDustFacetArtifact.abi, <Provider>provider);
  protocolContracts.creditNftManagerFacet = new ethers.Contract(diamondAddress, CreditNftManagerFacetArtifact.abi, <Provider>provider);
  protocolContracts.creditNftRedemptionCalculatorFacet = new ethers.Contract(diamondAddress, CreditNftRedemptionCalculatorFacetArtifact.abi, <Provider>provider);
  protocolContracts.creditRedemptionCalculatorFacet = new ethers.Contract(diamondAddress, CreditRedemptionCalculatorFacetArtifact.abi, <Provider>provider);
  protocolContracts.curveDollarIncentiveFacet = new ethers.Contract(diamondAddress, CurveDollarIncentiveFacetArtifact.abi, <Provider>provider);
  protocolContracts.dollarMintCalculatorFacet = new ethers.Contract(diamondAddress, DollarMintCalculatorFacetArtifact.abi, <Provider>provider);
  protocolContracts.dollarMintExcessFacet = new ethers.Contract(diamondAddress, DollarMintExcessFacetArtifact.abi, <Provider>provider);
  protocolContracts.managerFacet = new ethers.Contract(diamondAddress, ManagerFacetArtifact.abi, <Provider>provider);
  protocolContracts.ownershipFacet = new ethers.Contract(diamondAddress, OwnershipFacetArtifact.abi, <Provider>provider);
  protocolContracts.stakingFacet = new ethers.Contract(diamondAddress, StakingFacetArtifact.abi, <Provider>provider);
  protocolContracts.stakingFormulasFacet = new ethers.Contract(diamondAddress, StakingFormulasFacetArtifact.abi, <Provider>provider);
  protocolContracts.twapOracleDollar3poolFacet = new ethers.Contract(diamondAddress, TWAPOracleDollar3poolFacetArtifact.abi, <Provider>provider);
  protocolContracts.ubiquityPoolFacet = new ethers.Contract(diamondAddress, UbiquityPoolFacetArtifact.abi, <Provider>provider);

  // other related contracts
  // const sushiSwapPool = await protocolContracts.managerFacet.sushiSwapPoolAddress();
  // const sushiSwapPoolContract = new ethers.Contract(sushiSwapPool, SushiSwapPoolArtifact.abi, <Provider>provider);
  // const UniswapV2PairContract = new ethers.Contract(await sushiSwapPoolContract.pair(), UniswapV2PairABI, <Provider>provider);
  const UniswapV2PairContract = new ethers.Contract(sushiSwapPoolAddress, UniswapV2PairABI, <Provider>provider);
  protocolContracts.sushiPoolGovernanceDollarLp = UniswapV2PairContract;

  // const dollar3poolMarket = await protocolContracts.managerFacet.stableSwapMetaPoolAddress();
  // const metaPoolContract = new ethers.Contract(dollar3poolMarket, IMetaPoolArtifact.abi, <Provider>provider);
  const metaPoolContract = new ethers.Contract(dollar3poolMarketAddress, IMetaPoolArtifact.abi, <Provider>provider);
  protocolContracts.curveMetaPoolDollarTriPoolLp = metaPoolContract;

  // const _3crvTokenAddress = await protocolContracts.managerFacet.curve3PoolTokenAddress();
  const _3crvTokenContract = new ethers.Contract(_3crvTokenAddress, ERC20ABI, <Provider>provider);
  protocolContracts._3crvToken = _3crvTokenContract;

  return protocolContracts;
};

export default useProtocolContracts;
