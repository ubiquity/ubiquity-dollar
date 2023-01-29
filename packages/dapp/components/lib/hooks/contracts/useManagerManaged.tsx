import {
  getCreditNftContract,
  getCreditNftRedemptionCalculatorContract,
  getCreditRedemptionCalculatorContract,
  getDollarMintCalculatorContract,
  getERC20Contract,
  getStakingContract,
  getUbiquityChefContract,
  getStakingTokenContract,
  getSushiSwapPoolContract,
  getTWAPOracleDollar3poolContract,
  getUbiquityCreditTokenContract,
  getUbiquityDollarTokenContract,
  getUbiquityFormulasContract,
  getUbiquityGovernanceTokenContract,
} from "@/components/utils/contracts";
import { getDollar3poolMarketContract, getUniswapV2PairABIContract } from "@/components/utils/contracts-external";
import { Contract } from "ethers";

import { createContext, useAtom, useEffect, useState } from "react";

import { UbiquityDollarManager } from "types/UbiquityDollarManager";

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
        console.trace({ globalManager: deployedContracts.globalManager });
        const connectedManagerContracts = await connectManagerContracts(deployedContracts.globalManager, provider);
        setManagedContracts(connectedManagerContracts);
      })();
    }
  }, [deployedContracts, provider]);

  return <ManagedContractsContext.Provider value={managedContracts}>{children}</ManagedContractsContext.Provider>;
};

async function connectManagerContracts(manager: UbiquityDollarManager & Contract, provider: NonNullable<PossibleProviders>) {
  // 4
  const [
    dollarToken,
    dollar3poolMarket,
    twapOracle,
    dollarMintCalculator,
    creditToken,
    governanceToken,
    _3crvToken,
    stakingToken,
    creditNft,
    staking,
    ubiquityChef,
    sushiSwapPool,
    ubiquityFormulas,
    creditNftCalculator,
    creditCalculator,
  ] = await Promise.all([
    // manager.dollarTokenAddress(),
    // manager.stableSwapMetaPoolAddress(),
    // manager.twapOracleAddress(),
    // manager.dollarMintCalculatorAddress(),
    // manager.creditTokenAddress(),
    // manager.governanceTokenAddress(),
    // manager.curve3PoolTokenAddress(),
    // manager.stakingAddress(),
    // manager.creditNftAddress(),
    // manager.stakingTokenAddress(),
    // manager.masterChefAddress(),
    // manager.sushiSwapPoolAddress(),
    // manager.formulasAddress(),
    // manager.creditNftCalculatorAddress(),
    // manager.creditCalculatorAddress(),
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

  const sushiSwapPoolContract = getSushiSwapPoolContract(sushiSwapPool, provider);
  const pair = await sushiSwapPoolContract.pair();
  const governanceMarketPairContract = getUniswapV2PairABIContract(pair, provider);

  return {
    dollarToken: getUbiquityDollarTokenContract(dollarToken, provider),
    dollarMetapool: getDollar3poolMarketContract(dollar3poolMarket, provider),
    dollarTwapOracle: getTWAPOracleDollar3poolContract(twapOracle, provider),
    dollarMintCalculator: getDollarMintCalculatorContract(dollarMintCalculator, provider),
    creditToken: getUbiquityCreditTokenContract(creditToken, provider),
    governanceToken: getUbiquityGovernanceTokenContract(governanceToken, provider),
    _3crvToken: getERC20Contract(_3crvToken, provider),
    stakingToken: getStakingTokenContract(stakingToken, provider),
    creditNft: getCreditNftContract(creditNft, provider),
    staking: getStakingContract(staking, provider),
    ubiquityChef: getUbiquityChefContract(ubiquityChef, provider),
    sushiSwapPool: sushiSwapPoolContract,
    governanceMarket: governanceMarketPairContract,
    ubiquityFormulas: getUbiquityFormulasContract(ubiquityFormulas, provider),
    creditNftCalculator: getCreditNftRedemptionCalculatorContract(creditNftCalculator, provider),
    creditCalculator: getCreditRedemptionCalculatorContract(creditCalculator, provider),
  };
}

export default () => useAtom(ManagedContractsContext);
