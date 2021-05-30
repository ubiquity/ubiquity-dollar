import { FC, useState } from "react";
import { ethers } from "ethers";

import {
  _connect,
  _depositBondingTokens,
  _getTokenBalance,
  _getLPTokenBalance,
  _renderControls,
  renderTasklist,
} from "./common";

export const ADDRESS = {
  UAD: "0x8b01F55C4D57d9678dB76b7082D9270d11616F78",
  METAPOOL: "0x152d13e62952a7c74c536bb3C8b7BD91853F076A",
  BONDING: "0x8a777acb51217cd8d8f5d05d05df334989ea976c",
  BONDING_SHARE: "0x07860015449240D2f20c63AF68b64cB0a2EA91Ee",
};

const Index: FC = (): JSX.Element => {
  const [provider, setProvider] = useState<ethers.providers.Web3Provider>(),
    [account, setAccount] = useState<string>(),
    [tokenBalance, setTokenBalance] = useState<string>(),
    [tokenLPBalance, setLPTokenBalance] = useState<string>(),
    [tokenBondingBalance, setBondingTokenBalance] = useState<string>();

  const connect = async () => _connect(setProvider, setAccount);
  // const depositBondingToken = async () => _depositBondingToken();
  const getTokenBalance = async () =>
    _getTokenBalance(provider, account, setTokenBalance);
  const depositBondingTokens = () =>
    _depositBondingTokens(provider, account, setBondingTokenBalance);
  const getLPTokenBalance = async () =>
    _getLPTokenBalance(provider, account, setLPTokenBalance);
  const renderControls = () =>
    _renderControls({
      connect,
      account,
      getTokenBalance,
      tokenBalance,
      getLPTokenBalance,
      tokenLPBalance,
      depositBondingTokens,
      tokenBondingBalance,
    });

  return (
    <>
      {renderControls()}
      {renderTasklist()}
    </>
  );
};

export default Index;
