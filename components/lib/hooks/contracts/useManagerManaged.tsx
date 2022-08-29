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
import { createContext, useContext, useEffect, useState } from "react";
import { ChildrenShim } from "../children-shim";
import useWeb3, { PossibleProviders } from "../useWeb3";
import useDeployedContracts from "./useDeployedContracts";

export type ManagedContracts = Awaited<ReturnType<typeof connectManagerContracts>> | null;
export const ManagedContractsContext = createContext<ManagedContracts>(null);

export const ManagedContractsContextProvider: React.FC<ChildrenShim> = ({ children }) => {
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
    dollarToken,
    dollar3poolMarket,
    twapOracle,
    dollarMintCalc,
    creditToken,
    governanceToken,
    crvToken,
    stakingToken,
    creditNft,
    staking,
    masterChef,
    sushiSwapPool,
    ubiquityFormulas,
    creditNftCalculator,
    creditCalculator,
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
    dollarToken: UbiquityAlgorithmicDollar__factory.connect(dollarToken, provider),
    dollarMetapool: IMetaPool__factory.connect(dollar3poolMarket, provider),
    dollarTwapOracle: TWAPOracle__factory.connect(twapOracle, provider),
    dollarMintingCalculator: DollarMintingCalculator__factory.connect(dollarMintCalc, provider),
    creditToken: UbiquityAutoRedeem__factory.connect(creditToken, provider),
    governanceToken: UbiquityGovernance__factory.connect(governanceToken, provider),
    crvToken: ERC20__factory.connect(crvToken, provider),
    stakingToken: BondingShareV2__factory.connect(stakingToken, provider),
    creditNft: DebtCoupon__factory.connect(creditNft, provider),
    staking: BondingV2__factory.connect(staking, provider),
    masterChef: MasterChefV2__factory.connect(masterChef, provider),
    sushiSwapPool: sushiSwapPoolContract,
    governanceMarket: ugovUadPairContract,
    ubiquityFormulas: UbiquityFormulas__factory.connect(ubiquityFormulas, provider),
    creditNftCalculator: ICouponsForDollarsCalculator__factory.connect(creditNftCalculator, provider),
    creditCalculator: IUARForDollarsCalculator__factory.connect(creditCalculator, provider),
  };
}

export default () => useContext(ManagedContractsContext);
