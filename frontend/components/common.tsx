/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import { ethers, BigNumber } from "ethers";

import { UbiquityAlgorithmicDollar__factory } from "../src/types/factories/UbiquityAlgorithmicDollar__factory";
import { IMetaPool__factory } from "../src/types/factories/IMetaPool__factory";
import { UbiquityAlgorithmicDollarManager__factory } from "../src/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { ERC20__factory } from "../src/types/factories/ERC20__factory";
import UadBalance from "./uad.balance";
import { ADDRESS } from "../pages/index";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction } from "react";
import { EthAccount } from "../utils/types";
import Account from "./account";
import CurveBalance from "./curve.balance";
import CurveLPBalance from "./curveLP.balance";
import DepositShareBalance from "./deposit.share.balance";
import DepositShare from "./deposit.share";
import UarBalance from "./uar.balance";
import ChefUgov from "./chefugov";
import { TWAPOracle__factory } from "../src/types";
import { UbiquityAutoRedeem__factory } from "../src/types/factories/UbiquityAutoRedeem__factory";
import { UbiquityGovernance__factory } from "../src/types/factories/UbiquityGovernance__factory";
import TwapPrice from "./twap.price";
import UarRedeem from "./uar.redeem";
import DebtCouponDeposit from "./debtCoupon.deposit";

export function _renderTasklist() {
  return (
    <>
      <h1>tasklist</h1>
      <ol>
        <li>pending ugov reward</li>
        <li>bonding shares inputs for weeks and LP token amount</li>
        <li>link to crv.finance</li>
        <li>convert all wei into ether values</li>
      </ol>
    </>
  );
}

export async function _connect(
  setProvider: Dispatch<
    SetStateAction<ethers.providers.Web3Provider | undefined>
  >,
  setAccount: Dispatch<SetStateAction<EthAccount | undefined>>,
  setManager: Dispatch<
    SetStateAction<UbiquityAlgorithmicDollarManager | undefined>
  >,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>,
  setTwapPrice: Dispatch<SetStateAction<BigNumber | undefined>>
): Promise<void> {
  if (!window.ethereum?.request) {
    alert("MetaMask is not installed!");
    return;
  }

  const provider = new ethers.providers.Web3Provider(window.ethereum);
  const accounts = await window.ethereum.request({
    method: "eth_requestAccounts",
  });
  setProvider(provider);
  setAccount({ address: accounts[0], balance: 0 });
  const manager = UbiquityAlgorithmicDollarManager__factory.connect(
    ADDRESS.MANAGER,
    provider
  );
  setManager(manager);
  const SIGNER = provider.getSigner();
  const TOKEN_ADDR = await manager.stableSwapMetaPoolAddress();
  const metapool = IMetaPool__factory.connect(TOKEN_ADDR, SIGNER);

  const uarAdr = await manager.autoRedeemTokenAddress();
  const uar = UbiquityAutoRedeem__factory.connect(uarAdr, SIGNER);
  //  setUAR(uar);
  const uGovAdr = await manager.governanceTokenAddress();
  const ugov = UbiquityGovernance__factory.connect(uGovAdr, SIGNER);
  //  setUGOV(ugov);
  const uadAdr = await manager.dollarTokenAddress();
  const uad = UbiquityAlgorithmicDollar__factory.connect(uadAdr, SIGNER);
  // setUAD(uad);
  const CRV_TOKEN_ADDR = await manager.curve3PoolTokenAddress();
  const crvToken = ERC20__factory.connect(CRV_TOKEN_ADDR, provider);

  setBalances({
    uad: await uad.balanceOf(accounts[0]),
    crv: await crvToken.balanceOf(accounts[0]),
    uad3crv: await metapool.balanceOf(accounts[0]),
    uar: await uar.balanceOf(accounts[0]),
    ubq: await ugov.balanceOf(accounts[0]),
    bondingShares: BigNumber.from(0),
  });

  const TWAP_ADDR = await manager.twapOracleAddress();
  const twap = TWAPOracle__factory.connect(TWAP_ADDR, provider);
  const twapPrice = await twap.consult(uadAdr);
  setTwapPrice(twapPrice);
}

export function _renderControls() {
  const {
    setProvider,
    setAccount,
    setManager,
    setBalances,
    balances,
    twapPrice,
    setTwapPrice,
  } = useConnectedContext();

  const connect = async (): Promise<void> =>
    _connect(setProvider, setAccount, setManager, setBalances, setTwapPrice);

  return (
    <>
      <div className="column-wrap">
        <button onClick={connect}>Connect Wallet</button>
        <Account />
      </div>
      <div className="balance">
        <UadBalance />
        <CurveBalance />
        <CurveLPBalance />
        <UarBalance />
      </div>
      <br />
      <div className="column-wrap">
        <DepositShareBalance />
        <DepositShare />
        <ChefUgov />
        <TwapPrice />
        {balances?.uar.gt(BigNumber.from(0)) &&
        twapPrice?.gte(ethers.utils.parseEther("1")) ? (
          <UarRedeem />
        ) : (
          ""
        )}
        {twapPrice?.lte(ethers.utils.parseEther("1")) ? (
          <DebtCouponDeposit />
        ) : (
          ""
        )}
      </div>
    </>
  );
}
