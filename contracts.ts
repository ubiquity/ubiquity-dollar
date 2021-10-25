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
  SushiSwapPool,
  SushiSwapPool__factory,
  IUniswapV2Pair,
  IUniswapV2Pair__factory,
  UbiquityFormulas,
  UbiquityFormulas__factory,
  YieldProxy,
  YieldProxy__factory,
  IJar,
  IJar__factory,
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
  sushiSwapPool: SushiSwapPool__factory.connect,
  ugovUadPair: IUniswapV2Pair__factory.connect,
  ubiquityFormulas: UbiquityFormulas__factory.connect,
  yieldProxy: YieldProxy__factory.connect,
  usdc: ERC20__factory.connect,
  jarUsdc: IJar__factory.connect,
};

// 2
export type Contracts = {
  manager: UbiquityAlgorithmicDollarManager;
  debtCouponManager: DebtCouponManager;
  yieldProxy: YieldProxy;
  twapOracle: TWAPOracle;
  dollarMintCalc: DollarMintingCalculator;
  bonding: BondingV2;
  masterChef: MasterChefV2;
  sushiSwapPool: SushiSwapPool;
  ubiquityFormulas: UbiquityFormulas;

  // Third-party
  ugovUadPair: IUniswapV2Pair;
  curvePool: ICurveFactory;
  metaPool: IMetaPool;
  jarUsdc: IJar;

  // ERC20
  uad: UbiquityAlgorithmicDollar;
  uar: UbiquityAutoRedeem;
  ugov: UbiquityGovernance;
  crvToken: ERC20;
  usdc: ERC20;

  // ERC1155
  debtCouponToken: DebtCoupon;
  bondingToken: BondingShareV2;
};

// 3
type ManagerAddresses = {
  uad: string;
  metaPool: string;
  twapOracle: string;
  dollarMintCalc: string;
  uar: string;
  ugov: string;
  crvToken: string;
  bondingToken: string;
  debtCouponToken: string;
  bonding: string;
  masterChef: string;
  sushiSwapPool: string;
  ubiquityFormulas: string;
};

// Load all contract addresses on parallel
async function contractsAddresses(manager: UbiquityAlgorithmicDollarManager): Promise<ManagerAddresses> {
  // 4
  const [
    uad,
    metaPool,
    twapOracle,
    dollarMintCalc,
    uar,
    ugov,
    crvToken,
    bondingToken,
    debtCouponToken,
    bonding,
    masterChef,
    sushiSwapPool,
    ubiquityFormulas,
  ] = await Promise.all([
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
    manager.sushiSwapPoolAddress(),
    manager.formulasAddress(),
  ]);
  return {
    uad,
    metaPool,
    twapOracle,
    dollarMintCalc,
    uar,
    ugov,
    crvToken,
    bondingToken,
    debtCouponToken,
    bonding,
    masterChef,
    sushiSwapPool,
    ubiquityFormulas,
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

  const sushiSwapPool = contracts.sushiSwapPool(addr.sushiSwapPool, provider);
  const ugovUadPair = contracts.ugovUadPair(await sushiSwapPool.pair(), provider);

  // 5
  return {
    provider,
    contracts: {
      // Static-address contracts
      manager,
      curvePool: contracts.curvePool(ADDRESS.curveFactory, provider),
      yieldProxy: contracts.yieldProxy(namedAccounts.yieldProxy, provider),
      usdc: contracts.usdc(ADDRESS.USDC, provider),
      debtCouponManager: contracts.debtCouponManager(ADDRESS.DEBT_COUPON_MANAGER, provider),
      jarUsdc: contracts.jarUsdc(ADDRESS.jarUSDCAddr, provider),

      // Dynamic-address contracts
      uad: contracts.uad(addr.uad, provider),
      metaPool: contracts.metaPool(addr.metaPool, provider),
      twapOracle: contracts.twapOracle(addr.twapOracle, provider),
      dollarMintCalc: contracts.dollarMintCalc(addr.dollarMintCalc, provider),
      uar: contracts.uar(addr.uar, provider),
      ugov: contracts.ugov(addr.ugov, provider),
      crvToken: contracts.crvToken(addr.crvToken, provider),
      bondingToken: contracts.bondingToken(addr.bondingToken, provider),
      debtCouponToken: contracts.debtCouponToken(addr.debtCouponToken, provider),
      bonding: contracts.bonding(addr.bonding, provider),
      masterChef: contracts.masterChef(addr.masterChef, provider),
      sushiSwapPool,
      ugovUadPair,
      ubiquityFormulas: contracts.ubiquityFormulas(addr.ubiquityFormulas, provider),
    },
  };
}
