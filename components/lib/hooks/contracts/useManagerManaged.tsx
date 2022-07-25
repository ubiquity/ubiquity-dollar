import {
  BondingShareV2__factory,
  BondingV2__factory,
  DebtCoupon__factory,
  DollarMintingCalculator__factory,
  ERC20__factory,
  ICouponsForDollarsCalculator__factory,
  IMetaPool__factory,
  IUARForDollarsCalculator__factory,
  IUniswapV2Pair__factory,
  MasterChefV2__factory,
  SushiSwapPool__factory,
  TWAPOracle__factory,
  UbiquityAlgorithmicDollarManager,
  UbiquityAlgorithmicDollar__factory,
  UbiquityAutoRedeem__factory,
  UbiquityFormulas__factory,
  UbiquityGovernance__factory,
} from "@/dollar-types";
import { useDeployedContracts } from "@/lib/hooks";
import { createContext, useContext, useEffect, useState } from "react";
import useWeb3, { PossibleProviders } from "../useWeb3";

export type ManagedContracts = Awaited<ReturnType<typeof connectManagerContracts>> | null;
export const ManagedContractsContext = createContext<ManagedContracts>(null);

export const ManagedContractsContextProvider: React.FC = ({ children }) => {
  const [{ provider }] = useWeb3();
  const deployedContracts = useDeployedContracts();
  const [managedContracts, setManagedContracts] = useState<ManagedContracts>(null);

  useEffect(() => {
    if (deployedContracts && provider) {
      (async () => {
        setManagedContracts(await connectManagerContracts(deployedContracts.manager, provider));
      })();
    }
  }, [deployedContracts, provider]);

  return <ManagedContractsContext.Provider value={managedContracts}>{children}</ManagedContractsContext.Provider>;
};

async function connectManagerContracts(manager: UbiquityAlgorithmicDollarManager, provider: NonNullable<PossibleProviders>) {
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
    coupon,
    uarCalc,
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
    manager.couponCalculatorAddress(),
    manager.uarCalculatorAddress(),
  ]);

  const sushiSwapPoolContract = SushiSwapPool__factory.connect(sushiSwapPool, provider);
  const ugovUadPairContract = IUniswapV2Pair__factory.connect(await sushiSwapPoolContract.pair(), provider);

  return {
    uad: UbiquityAlgorithmicDollar__factory.connect(uad, provider),
    metaPool: IMetaPool__factory.connect(metaPool, provider),
    twapOracle: TWAPOracle__factory.connect(twapOracle, provider),
    dollarMintCalc: DollarMintingCalculator__factory.connect(dollarMintCalc, provider),
    uar: UbiquityAutoRedeem__factory.connect(uar, provider),
    ugov: UbiquityGovernance__factory.connect(ugov, provider),
    crvToken: ERC20__factory.connect(crvToken, provider),
    bondingToken: BondingShareV2__factory.connect(bondingToken, provider),
    debtCouponToken: DebtCoupon__factory.connect(debtCouponToken, provider),
    bonding: BondingV2__factory.connect(bonding, provider),
    masterChef: MasterChefV2__factory.connect(masterChef, provider),
    sushiSwapPool: sushiSwapPoolContract,
    ugovUadPair: ugovUadPairContract,
    ubiquityFormulas: UbiquityFormulas__factory.connect(ubiquityFormulas, provider),
    coupon: ICouponsForDollarsCalculator__factory.connect(coupon, provider),
    uarCalc: IUARForDollarsCalculator__factory.connect(uarCalc, provider),
  };
}

export default () => useContext(ManagedContractsContext);
