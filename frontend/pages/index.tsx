import { FC, useState } from "react";
import { ethers } from "ethers";
import FullDeployment from "../src/full_deployment.json";
import {
  _connect,
  _renderControls,
  //_getCurveTokenBalance,
  _renderTasklist,
} from "../components/common";

export const ADDRESS = {
  MANAGER: FullDeployment.contracts.UbiquityAlgorithmicDollarManager.address,
  DEBT_COUPON_MANAGER: FullDeployment.contracts.DebtCouponManager.address,
};

const Index: FC = (): JSX.Element => {
  // const [provider, setProvider] = useState<ethers.providers.Web3Provider>();
  // const [account, setAccount] = useState<string>();

  const renderControls = () =>
    _renderControls(/* {
      connect,
      getTokenBalance,
      tokenBalance,
      getLPTokenBalance,
      tokenLPBalance,
      depositBondingTokens,
      tokenBondingSharesBalance,
      setCurveTokenBalance,
      getCurveTokenBalance,
      curveTokenBalance,
    } */);

  return (
    <>
      {renderControls()}
      {_renderTasklist()}
    </>
  );
};

export default Index;
