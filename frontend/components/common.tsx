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
import {
  ERC1155Ubiquity,
  ERC1155Ubiquity__factory,
  TWAPOracle__factory,
} from "../src/types";
import { UbiquityAutoRedeem__factory } from "../src/types/factories/UbiquityAutoRedeem__factory";
import { UbiquityGovernance__factory } from "../src/types/factories/UbiquityGovernance__factory";
import TwapPrice from "./twap.price";
import UarRedeem from "./uar.redeem";
import DebtCouponDeposit from "./debtCoupon.deposit";
import DebtCouponBalance from "./debtCoupon.balance";
import DebtCouponRedeem from "./debtCoupon.redeem";

async function erc1155BalanceOf(
  addr: string,
  erc1155UbiquityCtr: ERC1155Ubiquity
): Promise<BigNumber> {
  const treasuryIds = await erc1155UbiquityCtr.holderTokens(addr);

  const balanceOfs = treasuryIds.map((id) => {
    return erc1155UbiquityCtr.balanceOf(addr, id);
  });
  const balances = await Promise.all(balanceOfs);
  let fullBalance = BigNumber.from(0);
  if (balances.length > 0) {
    fullBalance = balances.reduce((prev, cur) => {
      return prev.add(cur);
    });
  }
  return fullBalance;
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

  const BONDING_TOKEN_ADDR = await manager.bondingShareAddress();
  const bondingToken = ERC1155Ubiquity__factory.connect(
    BONDING_TOKEN_ADDR,
    provider
  );

  const DEBT_COUPON_TOKEN_ADDR = await manager.debtCouponAddress();
  const debtCouponToken = ERC1155Ubiquity__factory.connect(
    DEBT_COUPON_TOKEN_ADDR,
    provider
  );

  setBalances({
    uad: await uad.balanceOf(accounts[0]),
    crv: await crvToken.balanceOf(accounts[0]),
    uad3crv: await metapool.balanceOf(accounts[0]),
    uar: await uar.balanceOf(accounts[0]),
    ubq: await ugov.balanceOf(accounts[0]),
    debtCoupon: await erc1155BalanceOf(accounts[0], debtCouponToken),
    bondingShares: await erc1155BalanceOf(accounts[0], bondingToken),
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

  const connect = async (el: React.BaseSyntheticEvent): Promise<void> => {
    const button = el.target as HTMLButtonElement;
    button.disabled = true;
    return _connect(
      setProvider,
      setAccount,
      setManager,
      setBalances,
      setTwapPrice
    );
  };

  return (
    <>
      <div id="common">
        <header>
          <div id="logo">
            <span>Ubiquity Dollar</span>
          </div>
          <div>
            <input
              type="button"
              value="Connect Wallet"
              onClick={(el) => connect(el)}
            />
          </div>
        <Account />
        </header>
        <div>
          <a href="https://crv.to">
            <input type="button" value="Swap uAD" />
          </a>
        </div>

        <UadBalance />
        <CurveBalance />
        <CurveLPBalance />

        <UarBalance />
        <DebtCouponBalance />
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
        {balances?.debtCoupon.gt(BigNumber.from(0)) ? <DebtCouponRedeem /> : ""}
      </div>
    </>
  );
}
