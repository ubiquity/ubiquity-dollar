import { FC, useState } from "react";
import { ethers } from "ethers";
import FullDeployment from "../src/uad-contracts-deployment.json";

import {
  _connect,
  _depositBondingTokens,
  _getTokenBalance,
  _getLPTokenBalance,
  _renderControls,
  _getCurveTokenBalance,
  _renderTasklist,
} from "./common";
import { UbiquityAlgorithmicDollarManager } from "../src/contracts/types";
import { UbiquityAlgorithmicDollarManager__factory } from "../src/types/factories/UbiquityAlgorithmicDollarManager__factory";

export const ADDRESS = {
  MANAGER: FullDeployment.contracts.UbiquityAlgorithmicDollarManager.address,
  UAD: FullDeployment.contracts.UbiquityAlgorithmicDollar.address,
  BONDING: FullDeployment.contracts.Bonding.address,
  BONDING_SHARE: FullDeployment.contracts.BondingShare.address,
};

const Index: FC = (): JSX.Element => {
  console.log("---render");
  const [provider, setProvider] = useState<ethers.providers.Web3Provider>();
  const [account, setAccount] = useState<string>();
  const [tokenBalance, setTokenBalance] = useState<string>();
  const [tokenLPBalance, setLPTokenBalance] = useState<string>();
  const [curveTokenBalance, setCurveTokenBalance] = useState<string>();
  const [
    tokenBondingSharesBalance,
    setBondingSharesBalance,
  ] = useState<string>();
  //const [manager, setManager] = useState<UbiquityAlgorithmicDollarManager>();

  const connect = async (): Promise<void> => _connect(setProvider, setAccount);

  // const depositBondingToken = async () => _depositBondingToken();
  const getTokenBalance = async () =>
    _getTokenBalance(provider, account ?? "", setTokenBalance);
  const depositBondingTokens = () =>
    _depositBondingTokens(provider, account, setBondingSharesBalance);

  const getLPTokenBalance = async () =>
    _getLPTokenBalance(provider, account ?? "", setLPTokenBalance);

  const getCurveTokenBalance = async () =>
    _getCurveTokenBalance(provider, account ?? "", setCurveTokenBalance);
  /* if (provider)
    setManager(
      UbiquityAlgorithmicDollarManager__factory.connect(
        ADDRESS.MANAGER,
        provider
      )
    ); */
  const renderControls = () =>
    _renderControls({
      connect,
      account,
      getTokenBalance,
      tokenBalance,
      getLPTokenBalance,
      tokenLPBalance,
      depositBondingTokens,
      tokenBondingSharesBalance,
      setCurveTokenBalance,
      getCurveTokenBalance,
      curveTokenBalance,
      // setManager,
      //  manager,
    });

  return (
    <>
      {renderControls()}
      {_renderTasklist()}
    </>
  );
};

export default Index;
