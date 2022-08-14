import { BigNumber, ethers } from "ethers";
import { memo, useEffect, useState } from "react";

import { ERC20 } from "@/dollar-types";
import { ensureERC20Allowance } from "@/lib/contracts-shortcuts";
import { constrainStringNumber, performTransaction } from "@/lib/utils";
import withLoadedContext, { LoadedContext } from "@/lib/withLoadedContext";

import { loadYieldProxyData, loadYieldProxyDepositInfo, YieldProxyData, YieldProxyDepositInfo } from "./lib/data";
import useBalances from "../lib/hooks/useBalances";
import useTransactionLogger from "../lib/hooks/useTransactionLogger";
import Button from "../ui/Button";
import Icon from "../ui/Icon";
import MaxButtonWrapper from "../ui/MaxButtonWrapper";
import PositiveNumberInput from "../ui/PositiveNumberInput";
import Tooltip from "../ui/Tooltip";
import WalletNotConnected from "../ui/WalletNotConnected";

type Balance = { usdc: number; ubq: number; uad: number };

type Actions = {
  onDeposit: (payload: Balance) => void;
  onWithdraw: () => void;
};

export const YieldFarmingContainer = ({ managedContracts, namedContracts: contracts, walletAddress, signer }: LoadedContext) => {
  const [yieldProxyData, setYieldProxyData] = useState<YieldProxyData | null>(null);
  const [depositInfo, setDepositInfo] = useState<YieldProxyDepositInfo | null>(null);
  const [, doTransaction, doingTransaction] = useTransactionLogger();
  const [balances, refreshBalances] = useBalances();

  async function refreshYieldProxyData() {
    const ypd = await loadYieldProxyData(contracts);
    const di = await loadYieldProxyDepositInfo(ypd, contracts, walletAddress);
    setYieldProxyData(ypd);
    setDepositInfo(di);
  }

  useEffect(() => {
    (async function () {
      refreshYieldProxyData();
    })();
  }, []);

  const actions: Actions = {
    onDeposit: async ({ usdc, ubq, uad }) => {
      doTransaction("Depositing...", async () => {
        const bigUsdc = ethers.utils.parseUnits(String(usdc), 6);
        const bigUbq = ethers.utils.parseUnits(String(ubq), 18);
        const bigUad = ethers.utils.parseUnits(String(uad), 18);
        console.log(`Depositing: USDC ${usdc} | UBQ ${ubq} | uAD ${uad}`);
        if (
          (await ensureERC20Allowance("USDC", contracts.usdc, bigUsdc, signer, contracts.yieldProxy.address, 6)) &&
          (await ensureERC20Allowance("UBQ", managedContracts.ugov as unknown as ERC20, bigUbq, signer, contracts.yieldProxy.address)) &&
          (await ensureERC20Allowance("uAD", managedContracts.uad as unknown as ERC20, bigUad, signer, contracts.yieldProxy.address)) &&
          (await performTransaction(contracts.yieldProxy.connect(signer).deposit(bigUsdc, bigUad, bigUbq)))
        ) {
          await refreshYieldProxyData();
          await refreshBalances();
        } else {
          // TODO: Show transaction error
        }
      });
    },
    onWithdraw: async () => {
      doTransaction("Withdrawing...", async () => {
        await performTransaction(contracts.yieldProxy.connect(signer).withdrawAll());
        await refreshYieldProxyData();
        await refreshBalances();
      });
    },
  };

  const parsedBalances = balances && {
    usdc: +ethers.utils.formatUnits(balances.usdc, 6),
    ubq: +ethers.utils.formatEther(balances.ubq),
    uad: +ethers.utils.formatEther(balances.uad),
  };

  return (
    <YieldFarmingSubcontainer
      yieldProxyData={yieldProxyData}
      depositInfo={depositInfo}
      isProcessing={doingTransaction}
      actions={actions}
      balance={parsedBalances}
    />
  );
};

type YieldFarmingSubcontainerProps = {
  yieldProxyData: YieldProxyData | null;
  depositInfo: YieldProxyDepositInfo | null;
  isProcessing: boolean;
  actions: Actions;
  balance: Balance | null;
};

const fm = (n: BigNumber, d = 18) => +ethers.utils.formatUnits(n, d);
const USDC_JAR_APY = { min: 10.1, max: 19.65 };
const TVL = { usdc: 1.2, ubq: 2.5, uad: 0.6 };

export const YieldFarmingSubcontainer = ({ actions, yieldProxyData, depositInfo, isProcessing, balance }: YieldFarmingSubcontainerProps) => {
  return (
    <div>
      <h2>Boosted Yield Farming (Beta)</h2>

      <div>
        <div>
          <Icon icon="warning" />
        </div>
        <p>
          <span>Explainer article coming soon!</span>
        </p>
      </div>

      <div>
        <div>
          <Icon icon="warning" />
        </div>
        <p>
          <span>uCR is 1:1 redeemable for uAD when the TWAP goes above 1.00. </span>
          <a target="_blank" href="https://medium.com/ubiquity-dao/ubiquitys-debt-system-explained-40e51325fc5">
            Learn more &raquo;
          </a>
        </p>
      </div>
      {yieldProxyData ? (
        depositInfo ? (
          <YieldFarmindWithdraw
            token={yieldProxyData.token.toUpperCase()}
            amount={fm(depositInfo.amount, yieldProxyData.decimals)}
            newAmount={fm(depositInfo.newAmount, yieldProxyData.decimals)}
            yieldPct={depositInfo.currentYieldPct}
            yieldAmount={fm(depositInfo.jarYieldAmount)}
            uad={fm(depositInfo.uad)}
            uadMax={yieldProxyData.bonusYieldUadMaxPct * +fm(depositInfo.amount, yieldProxyData.decimals)}
            uadBasePct={yieldProxyData.bonusYieldBasePct}
            uadBonusPct={depositInfo.bonusYieldExtraPct}
            uadBonusAmount={fm(depositInfo.bonusYieldAmount)}
            ubq={fm(depositInfo.ubq)}
            ubqMax={fm(yieldProxyData.depositFeeUbqMax)}
            feePct={depositInfo.feePct}
            feePctMax={yieldProxyData.depositFeeBasePct}
            feeAmount={fm(depositInfo.feeAmount)}
            uar={fm(depositInfo.uar)}
            uarApyMin={USDC_JAR_APY.min + depositInfo.bonusYieldTotalPct * USDC_JAR_APY.min}
            uarApyMax={USDC_JAR_APY.max + depositInfo.bonusYieldTotalPct * USDC_JAR_APY.max}
            uarCurrentYieldPct={depositInfo.currentYieldPct}
            onWithdraw={actions.onWithdraw}
            disable={isProcessing}
          />
        ) : balance ? (
          <YieldFarmingDeposit
            tvl={TVL}
            usdcApy={USDC_JAR_APY}
            maxUbqAmount={+ethers.utils.formatEther(yieldProxyData.depositFeeUbqMax)}
            maxUadPct={yieldProxyData.bonusYieldUadMaxPct}
            baseYieldBonusPct={yieldProxyData.bonusYieldBasePct}
            maxYieldBonusPct={yieldProxyData.bonusYieldMaxPct}
            baseDepositFeePct={yieldProxyData.depositFeeBasePct}
            minDepositFeePct={0}
            balance={balance}
            onDeposit={actions.onDeposit}
            disable={isProcessing}
          />
        ) : (
          "Loading..."
        )
      ) : (
        "Loading..."
      )}
    </div>
  );
};

type YieldFarmingWithdrawProps = {
  token: string;
  amount: number;
  newAmount: number;
  yieldPct: number;
  yieldAmount: number;
  uad: number;
  uadMax: number;
  uadBasePct: number;
  uadBonusPct: number;
  uadBonusAmount: number;
  ubq: number;
  ubqMax: number;
  feePct: number;
  feePctMax: number;
  feeAmount: number;
  uar: number;
  uarApyMin: number;
  uarApyMax: number;
  uarCurrentYieldPct: number;
  disable: boolean;
  onWithdraw: () => void;
};

const f = (n: number) => (Math.round(n * 100) / 100).toLocaleString();

export const YieldFarmindWithdraw = memo(
  ({
    token,
    amount,
    newAmount,
    yieldPct,
    yieldAmount,
    uad,
    uadMax,
    uadBasePct,
    uadBonusPct,
    uadBonusAmount,
    ubq,
    ubqMax,
    feePct,
    feePctMax,
    feeAmount,
    uar,
    uarApyMin,
    uarApyMax,
    uarCurrentYieldPct,
    disable,
    onWithdraw,
  }: YieldFarmingWithdrawProps) => {
    return (
      <>
        <h3>Current Deposit</h3>
        <div>
          <DepositItem val={f(newAmount)} fadeVal={` (${f(amount)})`} text={token} />
          <DepositItem val={`${f(yieldPct * 100)}%`} text="Yield %" />
          <DepositItem val={`${f(yieldAmount)} uCR`} text="Yield" />
          <DepositItem val={f(uad)} fadeVal={` / ${f(uadMax)}`} text="uAD" />
          <DepositItem val={`${f(uadBasePct * 100)}% + ${f(uadBonusPct * 100)}%`} text="Yield Multiplier" />
          <DepositItem val={`${f(uadBonusAmount)} uCR`} text="Bonus Yield" />
          <DepositItem val={f(ubq)} fadeVal={` / ${f(ubqMax)}`} text="UBQ" />
          <DepositItem val={`${f(feePct * 100)}%`} fadeVal={` / ${f(feePctMax * 100)}%`} text="Deposit Fee" />
          <DepositItem val={`${f(feeAmount)} uCR`} text={`Converted from ${token}`} />
          <DepositItem val={f(uar)} text="uCR" />
          <DepositItem val={`${f(uarApyMin)}% - ${f(uarApyMax)}%`} text="APY in uCR" />
          <DepositItem val={`${f(uarCurrentYieldPct * 100)}%`} text="Current Yield" />
        </div>
        <div>
          <Button onClick={onWithdraw} disabled={disable}>
            Withdraw
          </Button>
        </div>
      </>
    );
  }
);

type DepositItemProps = {
  val: number | string;
  fadeVal?: number | string;
  text: string;
};
const DepositItem = ({ val, fadeVal, text }: DepositItemProps) => (
  <div>
    <div>
      {val}
      {fadeVal ? <span>{fadeVal}</span> : null}
    </div>
    <div>{text}</div>
  </div>
);

type YieldFarmingDepositProps = {
  tvl: Balance;
  balance: Balance;
  usdcApy: { min: number; max: number };
  baseYieldBonusPct: number; // 0.5
  maxYieldBonusPct: number; // 1
  baseDepositFeePct: number; // 0.1
  minDepositFeePct: number; // 0
  maxUbqAmount: number; // 10000
  maxUadPct: number; // 0.5
  disable: boolean;
  onDeposit: Actions["onDeposit"];
};

export const YieldFarmingDeposit = memo(
  ({
    usdcApy,
    maxUbqAmount,
    maxUadPct,
    baseYieldBonusPct,
    maxYieldBonusPct,
    // tvl,
    baseDepositFeePct,
    minDepositFeePct,
    balance,
    disable,
    onDeposit,
  }: YieldFarmingDepositProps) => {
    const [usdc, setUsdc] = useState<string>("");
    const [ubq, setUbq] = useState<string>("");
    const [uad, setUad] = useState<string>("");
    const [errors, setErrors] = useState<string[]>([]);

    const usdcNum = parseFloat(usdc) || 0;
    const ubqNum = parseFloat(ubq) || 0;
    const uadNum = parseFloat(uad) || 0;

    const deposit: () => void = () => {
      if (usdc && ubq && uad) {
        onDeposit({ usdc: parseFloat(usdc), ubq: parseFloat(ubq), uad: parseFloat(uad) });
      }
    };

    const handleUsdcChange = (v: string) => {
      setUsdc(v);
      const newUsdc = parseFloat(v) || 0;
      if (newUsdc === 0) setUad("");
      else if (newUsdc < usdcNum) setUad(constrainStringNumber(uad, 0, maxUadPct * newUsdc));
    };

    const handleUbqChange = (v: string) => {
      setUbq(constrainStringNumber(v, 0, maxUbqAmount));
    };

    const handleUadChange = (v: string) => {
      setUad(constrainStringNumber(v, 0, maxUadPct * usdcNum));
    };

    const canDeposit: () => boolean = () => {
      if (usdcNum > 0 && usdcNum <= balance.usdc && ubqNum >= 0 && ubqNum <= balance.ubq && uadNum >= 0 && uadNum <= balance.uad) {
        return true;
      }
      return false;
    };

    const ubqFee = () => {
      return baseDepositFeePct - (ubqNum / maxUbqAmount) * (baseDepositFeePct - minDepositFeePct);
    };

    const uadBoost = () => {
      const pct = usdcNum ? uadNum / (maxUadPct * usdcNum) : 0;
      return baseYieldBonusPct + (maxYieldBonusPct - baseYieldBonusPct) * pct;
    };

    const maxApy = () => {
      return usdcApy.max + usdcApy.max * (uadNum && usdcNum ? uadBoost() : maxYieldBonusPct);
    };

    const setMaxUbq = () => {
      const max = maxUbqAmount > balance.ubq ? balance.ubq : maxUbqAmount;
      setUbq(max.toString());
    };

    const setMaxUad = () => {
      let max = maxUadPct * usdcNum;
      if (max > balance.uad) {
        max = balance.uad;
      }
      setUad(max.toString());
    };

    const setMaxUsdc = () => {
      setUsdc(balance.usdc.toString());
    };

    useEffect(() => {
      const errors: string[] = [];
      const noFunds = (token: string) => `You don't have enough ${token.toUpperCase()}.`;
      if (usdcNum > balance.usdc) errors.push(noFunds("usdc"));
      if (ubqNum > balance.ubq) errors.push(noFunds("ubq"));
      if (uadNum > balance.uad) errors.push(noFunds("uad"));

      setErrors(errors);
    }, [usdc, ubq, uad]);

    const HelpTooltip = ({ content }: { content: string }) => (
      <Tooltip content={content}>
        <span>
          <Icon icon="help" />
        </span>
      </Tooltip>
    );

    return (
      <>
        <h3>Primary deposit</h3>
        <div>
          {/* TODO: ICON */}
          <div>
            <div>
              <span>USDC</span>
              {/* <span>
                <span>TVL</span>
                <span>{tvl.usdc}M</span>
              </span> */}
            </div>
            <div>
              <span>
                {usdcApy.min.toFixed(2)}% - {usdcApy.max.toFixed(2)}%
              </span>
              <span>APY</span>
              <HelpTooltip content="This is the APY from the Pickle Finance USDC jar" />
            </div>
            <MaxButtonWrapper onMax={setMaxUsdc}>
              <PositiveNumberInput value={usdc} onChange={handleUsdcChange} />
            </MaxButtonWrapper>
            <div>Balance: {f(balance.usdc)}</div>
          </div>
          <div>
            <div>{Math.round(maxApy() * 100) / 100}%</div>
            <div>
              Max APY in uCR
              <HelpTooltip content="All the rewards are multiplied and provided in uCR" />
            </div>
          </div>
        </div>
        <h3>Boosters</h3>
        <div>
          <div>
            <div>
              <span>UBQ</span>
            </div>
            <div>
              <span>Minimizes deposit fee</span>
              <HelpTooltip content="The deposit fee gets converted to uCR when you withdraw" />
            </div>
            <div>
              <MaxButtonWrapper onMax={setMaxUbq}>
                <PositiveNumberInput value={ubq} onChange={handleUbqChange} placeholder={`${maxUbqAmount.toLocaleString()} for 0% fee`} />
              </MaxButtonWrapper>
              <div>
                <span>{Math.round(ubqFee() * 100 * 100) / 100}%</span>
                <span>FEE</span>
              </div>
            </div>
            <div>Balance: {f(balance.ubq)}</div>
          </div>

          <div>
            <div>
              <span>uAD</span>
              {/* <span>
                <span>TVL</span>
                <span>{tvl.uad}M</span>
              </span> */}
            </div>
            <div>
              <span>Boosts yield</span>
              {/* <span>up to {(maxYieldBonusPct - baseYieldBonusPct) * 100}% more</span> */}
              <HelpTooltip content="Match 50% of the USDC deposit and you get an extra 50% boost" />
            </div>
            <div>
              <MaxButtonWrapper onMax={setMaxUad} disabled={usdcNum <= 0}>
                <PositiveNumberInput
                  disabled={usdcNum <= 0}
                  value={uad}
                  onChange={handleUadChange}
                  placeholder={`${maxUadPct * 100}% of deposit for max boost`}
                />
              </MaxButtonWrapper>
              <div>
                <span>{Math.round(uadBoost() * 100 * 100) / 100}%</span>
                <span>BOOST</span>
              </div>
            </div>
            <div>Balance: {f(balance.uad)}</div>
          </div>
        </div>

        <>
          {errors.length ? (
            <div>
              {errors.map((err, i) => (
                <div key={i}>{err}</div>
              ))}
            </div>
          ) : null}
          <div>
            <Button onClick={deposit} disabled={!canDeposit() || disable}>
              Deposit
            </Button>
          </div>
        </>
      </>
    );
  }
);

export default memo(withLoadedContext(YieldFarmingContainer, () => WalletNotConnected));
