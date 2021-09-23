import { ethers } from "ethers";
import {
  TWAPOracle,
  TWAPOracle__factory,
  ICurveFactory,
  ICurveFactory__factory,
  UbiquityAlgorithmicDollarManager,
  UbiquityAlgorithmicDollarManager__factory,
  UbiquityAlgorithmicDollar,
  UbiquityAlgorithmicDollar__factory,
  DollarMintingCalculator,
  DollarMintingCalculator__factory,
  UbiquityAutoRedeem,
  UbiquityAutoRedeem__factory,
  IMetaPool,
  IMetaPool__factory,
  UbiquityGovernance,
  UbiquityGovernance__factory,
  ERC20,
  ERC20__factory,
  ERC1155Ubiquity,
  ERC1155Ubiquity__factory,
  DebtCoupon,
  DebtCoupon__factory,
  DebtCouponManager,
  DebtCouponManager__factory,
  BondingV2,
  BondingV2__factory,
  MasterChefV2,
  MasterChefV2__factory,
  BondingShareV2,
  BondingShareV2__factory,
} from "./contracts/artifacts/types";
import namedAccounts from "./fixtures/named-accounts.json";
import FullDeployment from "./fixtures/full-deployment.json";

export const ADDRESS = {
  MANAGER: FullDeployment.contracts.UbiquityAlgorithmicDollarManager.address,
  DEBT_COUPON_MANAGER: FullDeployment.contracts.DebtCouponManager.address,
  ...namedAccounts,
};

// Want to add a contract? Add to 1, 2, 3, 4, 5

// 1
// These are the aliases we use for the contracts names
const contracts = {
  manager: UbiquityAlgorithmicDollarManager__factory.connect,
  uad: UbiquityAlgorithmicDollar__factory.connect,
  curvePool: ICurveFactory__factory.connect,
  metaPool: IMetaPool__factory.connect,
  twapOracle: TWAPOracle__factory.connect,
  dollarMintCalc: DollarMintingCalculator__factory.connect,
  uar: UbiquityAutoRedeem__factory.connect,
  ugov: UbiquityGovernance__factory.connect,
  crvToken: ERC20__factory.connect,
  bondingToken: BondingShareV2__factory.connect,
  debtCouponToken: DebtCoupon__factory.connect,
  debtCouponManager: DebtCouponManager__factory.connect,
  bonding: BondingV2__factory.connect,
  masterChef: MasterChefV2__factory.connect,
};

// 2
export type Contracts = {
  manager: UbiquityAlgorithmicDollarManager;
  uad: UbiquityAlgorithmicDollar;
  curvePool: ICurveFactory;
  metaPool: IMetaPool;
  twapOracle: TWAPOracle;
  dollarMintCalc: DollarMintingCalculator;
  uar: UbiquityAutoRedeem;
  ugov: UbiquityGovernance;
  crvToken: ERC20;
  bondingToken: BondingShareV2;
  debtCouponToken: DebtCoupon;
  debtCouponManager: DebtCouponManager;
  bonding: BondingV2;
  masterChef: MasterChefV2;
};

// 3
type ContractsAddresses = {
  manager: string;
  uad: string;
  curvePool: string;
  metaPool: string;
  twapOracle: string;
  dollarMintCalc: string;
  uar: string;
  ugov: string;
  crvToken: string;
  bondingToken: string;
  debtCouponToken: string;
  debtCouponManager: string;
  bonding: string;
  masterChef: string;
};

// Load all contract addresses on parallel
async function contractsAddresses(manager: UbiquityAlgorithmicDollarManager): Promise<ContractsAddresses> {
  // 4
  const [uad, metaPool, twapOracle, dollarMintCalc, uar, ugov, crvToken, bondingToken, debtCouponToken, bonding, masterChef] = await Promise.all([
    manager.dollarTokenAddress(),
    manager.stableSwapMetaPoolAddress(),
    manager.twapOracleAddress(),
    manager.dollarMintingCalculatorAddress(),
    manager.autoRedeemTokenAddress(),
    manager.governanceTokenAddress(),
    manager.curve3PoolTokenAddress(),
    manager.bondingShareAddress(),
    manager.debtCouponAddress(),
    manager.bondingContractAddress(),
    manager.masterChefAddress(),
  ]);
  return {
    manager: manager.address,
    uad,
    curvePool: ADDRESS.curveFactory,
    metaPool,
    twapOracle,
    dollarMintCalc,
    uar,
    ugov,
    crvToken,
    bondingToken,
    debtCouponToken,
    debtCouponManager: ADDRESS.DEBT_COUPON_MANAGER,
    bonding,
    masterChef,
  };
}

// Generates all the connected contracts used through the app and return them
export async function connectedContracts(): Promise<{
  provider: ethers.providers.Web3Provider;
  contracts: Contracts;
}> {
  if (!window.ethereum?.request) {
    console.log("Metamask is not insalled, cannot initialize contracts");
    return Promise.reject("Metamask is not installed");
  }

  const provider = new ethers.providers.Web3Provider(window.ethereum);

  const manager = contracts.manager(ADDRESS.MANAGER, provider);
  const addr = await contractsAddresses(manager);

  // const signer = provider.getSigner();

  // 5
  return {
    provider,
    contracts: {
      manager,
      uad: contracts.uad(addr.uad, provider),
      curvePool: contracts.curvePool(addr.curvePool, provider),
      metaPool: contracts.metaPool(addr.metaPool, provider),
      twapOracle: contracts.twapOracle(addr.twapOracle, provider),
      dollarMintCalc: contracts.dollarMintCalc(addr.dollarMintCalc, provider),
      uar: contracts.uar(addr.uar, provider),
      ugov: contracts.ugov(addr.ugov, provider),
      crvToken: contracts.crvToken(addr.crvToken, provider),
      bondingToken: contracts.bondingToken(addr.bondingToken, provider),
      debtCouponToken: contracts.debtCouponToken(addr.debtCouponToken, provider),
      debtCouponManager: contracts.debtCouponManager(addr.debtCouponManager, provider),
      bonding: contracts.bonding(addr.bonding, provider),
      masterChef: contracts.masterChef(addr.masterChef, provider),
    },
  };
}
