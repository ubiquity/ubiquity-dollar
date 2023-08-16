import {
  getStakingShareContract,
  getBondingV2Contract,
  getDebtCouponContract,
  getDollarMintCalculatorContract,
  getERC20Contract,
  getICouponsForDollarsCalculatorContract,
  getIMetaPoolContract,
  getIUARForDollarsCalculatorContract,
  getMasterChefV2Contract,
  getSushiSwapPoolContract,
  getTWAPOracleContract,
  getDollarContract,
  getCreditContract,
  getUbiquityFormulasContract,
  getGovernanceContract,
  getUniswapV2PairContract,
} from "@/components/utils/contracts";
import { ManagerFacet } from "types";
import { createContext, useContext, useEffect, useState } from "react";
import { ChildrenShim } from "../children-shim-d";
import useWeb3, { PossibleProviders } from "../use-web-3";
import useDeployedContracts from "./use-deployed-contracts";

export type ManagedContracts = Awaited<ReturnType<typeof connectManagerContracts>> | null;
export const ManagedContractsContext = createContext<ManagedContracts>(null);

export const ManagedContractsContextProvider: React.FC<ChildrenShim> = ({ children }) => {
  const { provider } = useWeb3();
  const deployedContracts = useDeployedContracts();
  const [managedContracts, setManagedContracts] = useState<ManagedContracts>(null);
  const NETWORK_ANVIL_ID = 31337;
  const PROVIDER_ID = provider?.network.chainId;

  useEffect(() => {
    if (deployedContracts && provider && PROVIDER_ID === NETWORK_ANVIL_ID) {
      (async () => {
        setManagedContracts(await connectManagerContracts(deployedContracts.manager, provider));
      })();
    }
  }, [deployedContracts, provider]);

  return <ManagedContractsContext.Provider value={managedContracts}>{children}</ManagedContractsContext.Provider>;
};

async function connectManagerContracts(manager: ManagerFacet, provider: NonNullable<PossibleProviders>) {
  // 4
  const [
    dollarToken,
    dollar3poolMarket,
    twapOracle,
    dollarMintCalc,
    creditToken,
    governanceToken,
    _3crvToken,
    stakingToken,
    creditNft,
    staking,
    masterChef,
    sushiSwapPool,
    ubiquityFormulas,
    creditCalculator,
  ] = await Promise.all([
    manager.dollarTokenAddress(),
    manager.stableSwapMetaPoolAddress(),
    manager.twapOracleAddress(),
    manager.dollarMintCalculatorAddress(),
    manager.creditTokenAddress(),
    manager.governanceTokenAddress(),
    manager.curve3PoolTokenAddress(),
    manager.stakingShareAddress(),
    manager.creditNftAddress(),
    manager.stakingContractAddress(),
    manager.masterChefAddress(),
    manager.sushiSwapPoolAddress(),
    manager.formulasAddress(),
    manager.creditCalculatorAddress(),
  ]);
  const creditNftCalculator = manager.address;
  const sushiSwapPoolContract = getSushiSwapPoolContract(sushiSwapPool, provider);

  const governanceMarket = getUniswapV2PairContract(await sushiSwapPoolContract.pair(), provider);

  return {
    dollarToken: getDollarContract(dollarToken, provider),
    dollarMetapool: getIMetaPoolContract(dollar3poolMarket, provider),
    dollarTwapOracle: getTWAPOracleContract(twapOracle, provider),
    dollarMintCalculator: getDollarMintCalculatorContract(dollarMintCalc, provider),
    creditToken: getCreditContract(creditToken, provider),
    governanceToken: getGovernanceContract(governanceToken, provider),
    _3crvToken: getERC20Contract(_3crvToken, provider),
    stakingToken: getStakingShareContract(stakingToken, provider),
    creditNft: getDebtCouponContract(creditNft, provider),
    staking: getBondingV2Contract(staking, provider),
    masterChef: getMasterChefV2Contract(masterChef, provider),
    sushiSwapPool: sushiSwapPoolContract,
    governanceMarket: governanceMarket,
    ubiquityFormulas: getUbiquityFormulasContract(ubiquityFormulas, provider),
    creditNftCalculator: getICouponsForDollarsCalculatorContract(creditNftCalculator, provider),
    creditCalculator: getIUARForDollarsCalculatorContract(creditCalculator, provider),
  };
}


export default () => useContext(ManagedContractsContext);
