import React, { memo, useEffect, useState } from "react";
import Tippy from "@tippyjs/react";
import { connectedWithUserContext, useConnectedContext, UserContext } from "./context/connected";
import * as widget from "./ui/widget";
import { loadYieldProxyData, loadYieldProxyDepositInfo, YieldProxyDepositInfo, YieldProxyData, ensureERC20Allowance } from "./common/contracts-shortcuts";
import { BigNumber, ethers } from "ethers";
import { performTransaction, constrainNumber } from "./common/utils";
import icons from "./ui/icons";
type Balance = { usdc: number; ubq: number; uad: number };

type Actions = {
  onDeposit: (payload: Balance) => void;
  onWithdraw: () => void;
};

const DEPOSIT_TRANSACTION = "DEPOSIT_TRANSACTION";
const WITHDRAW_TRANSACTION = "WITHDRAW_TRANSACTION";

export const YieldFarmingContainer = ({ contracts, account, signer }: UserContext) => {
  const [yieldProxyData, setYieldProxyData] = useState<YieldProxyData | null>(null);
  const [depositInfo, setDepositInfo] = useState<YieldProxyDepositInfo | null>(null);
  const { refreshBalances, balances, updateActiveTransaction } = useConnectedContext();
  const [isProcessing, setIsProcessing] = useState(false);

  async function refreshYieldProxyData() {
    const ypd = await loadYieldProxyData(contracts);
    const di = await loadYieldProxyDepositInfo(ypd, contracts, account.address);
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
      setIsProcessing(true);
      const title = "Depositing...";
      updateActiveTransaction({ id: DEPOSIT_TRANSACTION, title, active: true });
      const bigUsdc = ethers.utils.parseUnits(String(usdc), 6);
      const bigUbq = ethers.utils.parseUnits(String(ubq), 18);
      const bigUad = ethers.utils.parseUnits(String(uad), 18);
      console.log(`Depositing: USDC ${usdc} | UBQ ${ubq} | uAD ${uad}`);
      if (
        (await ensureERC20Allowance("USDC", contracts.usdc, bigUsdc, signer, contracts.yieldProxy.address, 6)) &&
        (await ensureERC20Allowance("UBQ", contracts.ugov, bigUbq, signer, contracts.yieldProxy.address)) &&
        (await ensureERC20Allowance("uAD", contracts.uad, bigUad, signer, contracts.yieldProxy.address)) &&
        (await performTransaction(contracts.yieldProxy.connect(signer).deposit(bigUsdc, bigUad, bigUbq)))
      ) {
        await refreshYieldProxyData();
        await refreshBalances();
      } else {
        // TODO: Show transaction error
      }
      setIsProcessing(false);
      updateActiveTransaction({ id: DEPOSIT_TRANSACTION, title, active: false });
    },
    onWithdraw: async () => {
      setIsProcessing(true);
      const title = "Withdrawing...";
      updateActiveTransaction({ id: WITHDRAW_TRANSACTION, title, active: true });
      await performTransaction(contracts.yieldProxy.connect(signer).withdrawAll());
      await refreshYieldProxyData();
      await refreshBalances();
      updateActiveTransaction({ id: WITHDRAW_TRANSACTION, title, active: false });
      setIsProcessing(false);
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
      isProcessing={isProcessing}
      actions={actions}
      balance={parsedBalances}
    />
  );
};

export const Tooltip = ({ content, children }: { content: string; children: React.ReactElement }) => (
  <Tippy
    content={
      <div className="px-4 border border-white/10 border-solid rounded-md" style={{ backdropFilter: "blur(8px)" }}>
        <p className="text-center text-white/50">{content}</p>
      </div>
    }
  >
    {children}
  </Tippy>
);

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
    <widget.Container className="max-w-screen-md !mx-auto relative" transacting={isProcessing}>
      <widget.Title text="Boosted Yield Farming (Beta)" />

      <div className="flex justify-evenly items-center p-4 border border-white/10 border-solid rounded-md mb-4">
        <div className="w-20">{icons.svgs.warning}</div>
        <p className="text-left flex-grow">
          <span>Explainer article coming soon!</span>
        </p>
      </div>

      <div className="flex justify-evenly items-center p-4 border border-white/10 border-solid rounded-md mb-4">
        <div className="w-20">{icons.svgs.warning}</div>
        <p className="text-left flex-grow">
          <span>uAR is 1:1 redeemable for uAD when the TWAP goes above 1.00. </span>
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
    </widget.Container>
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
        <widget.SubTitle text="Current Deposit" />
        <div className="grid grid-cols-3 gap-y-4">
          <DepositItem val={f(newAmount)} fadeVal={` (${f(amount)})`} text={token} />
          <DepositItem val={`${f(yieldPct * 100)}%`} text="Yield %" />
          <DepositItem val={`${f(yieldAmount)} uAR`} text="Yield" />
          <DepositItem val={f(uad)} fadeVal={` / ${f(uadMax)}`} text="uAD" />
          <DepositItem val={`${f(uadBasePct * 100)}% + ${f(uadBonusPct * 100)}%`} text="Yield Multiplier" />
          <DepositItem val={`${f(uadBonusAmount)} uAR`} text="Bonus Yield" />
          <DepositItem val={f(ubq)} fadeVal={` / ${f(ubqMax)}`} text="UBQ" />
          <DepositItem val={`${f(feePct * 100)}%`} fadeVal={` / ${f(feePctMax * 100)}%`} text="Deposit Fee" />
          <DepositItem val={`${f(feeAmount)} uAR`} text={`Converted from ${token}`} />
          <DepositItem val={f(uar)} text="uAR" />
          <DepositItem val={`${f(uarApyMin)}% - ${f(uarApyMax)}%`} text="APY in uAR" />
          <DepositItem val={`${f(uarCurrentYieldPct * 100)}%`} text="Current Yield" />
        </div>
        <button onClick={onWithdraw} disabled={disable} className="w-full flex justify-center m-0 mt-8">
          Withdraw
        </button>
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
  <div className="flex flex-col justify-center">
    <div className="mb-1 text-lg font-bold">
      {val}
      {fadeVal ? <span className="opacity-50">{fadeVal}</span> : null}
    </div>
    <div className="text-sm">{text}</div>
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
    const [usdc, setUsdc] = useState<number>(0);
    const [ubq, setUbq] = useState<number>(0);
    const [uad, setUad] = useState<number>(0);
    const [errors, setErrors] = useState<string[]>([]);

    const deposit: () => void = () => {
      if (canDeposit()) {
        onDeposit({ usdc, ubq, uad });
      }
    };

    const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
      const { value, name } = event.currentTarget;
      const num = parseFloat(value) || 0;
      switch (name) {
        case "usdc":
          {
            const newUsdc = constrainNumber(num, 0, Infinity);
            setUsdc(newUsdc);
            if (newUsdc < usdc) {
              setUad(constrainNumber(uad, 0, maxUadPct * newUsdc));
            }
          }
          break;

        case "ubq":
          setUbq(constrainNumber(num, 0, maxUbqAmount));
          break;

        case "uad":
          setUad(constrainNumber(num, 0, maxUadPct * usdc));
          break;
        default:
          break;
      }
    };

    const canDeposit: () => boolean = () => {
      if (usdc > 0 && usdc <= balance.usdc && ubq >= 0 && ubq <= balance.ubq && uad >= 0 && uad <= balance.uad) {
        return true;
      }
      return false;
    };

    const ubqFee = () => {
      return baseDepositFeePct - (ubq / maxUbqAmount) * (baseDepositFeePct - minDepositFeePct);
    };

    const uadBoost = () => {
      const pct = usdc ? uad / (maxUadPct * usdc) : 0;
      return baseYieldBonusPct + (maxYieldBonusPct - baseYieldBonusPct) * pct;
    };

    const maxApy = () => {
      return usdcApy.max + usdcApy.max * (uad && usdc ? uadBoost() : maxYieldBonusPct);
    };

    const setMaxUbq = () => {
      const max = maxUbqAmount > balance.ubq ? balance.ubq : maxUbqAmount;
      setUbq(max);
    };

    const setMaxUad = () => {
      let max = maxUadPct * usdc;
      if (max > balance.uad) {
        max = balance.uad;
      }
      setUad(max);
    };

    const setMaxUsdc = () => {
      setUsdc(balance.usdc);
    };

    useEffect(() => {
      const errors: string[] = [];
      const noFunds = (token: string) => `You don't have enough ${token.toUpperCase()}.`;
      if (usdc > balance.usdc) errors.push(noFunds("usdc"));
      if (ubq > balance.ubq) errors.push(noFunds("ubq"));
      if (uad > balance.uad) errors.push(noFunds("uad"));

      setErrors(errors);
    }, [usdc, ubq, uad]);

    return (
      <>
        <widget.SubTitle text="New Deposit" />
        <div className="flex justify-between items-center mb-8">
          {/* TODO: ICON */}
          <div className="w-5/12" style={{ backgroundImage: `url('data:image/svg+xml;utf8,${icons.strings.usdc}')` }}>
            <div className="flex justify-between">
              <span className="font-bold">USDC</span>
              {/* <span>
                <span>TVL</span>
                <span className="pl-4">{tvl.usdc}M</span>
              </span> */}
            </div>
            <div className="text-left mb-2">
              <span>
                {usdcApy.min.toFixed(2)}% - {usdcApy.max.toFixed(2)}%
              </span>
              <span className="pl-2">APY</span>
              <Tooltip content="This is the APY from the Pickle Finance USDC jar">
                <span className="pl-2">{icons.svgs.help}</span>
              </Tooltip>
            </div>
            <input type="number" value={usdc || ""} onChange={handleInputChange} name="usdc" className="w-full m-0 box-border" />
            <div className="flex justify-end mt-2">
              <span className="flex-grow opacity-50 text-left">Balance: {f(balance.usdc)}</span>
              <button onClick={setMaxUsdc}>Max</button>
            </div>
          </div>
          <div className="w-1/2">
            <div className="text-3xl text-accent font-bold">{Math.round(maxApy() * 100) / 100}%</div>
            <div>
              Max APY in uAR
              <Tooltip content="All the rewards are multiplied and provided in uAR">
                <span className="pl-2">{icons.svgs.help}</span>
              </Tooltip>
            </div>
          </div>
        </div>
        <widget.SubTitle text="Boosters" />
        <div className="flex justify-between items-center mb-4">
          <div className="w-5/12" style={{ backgroundImage: `url('data:image/svg+xml;utf8,${icons.stringsCyan.ubq}')` }}>
            <div className="flex justify-between">
              <span className="font-bold">UBQ</span>
              {/* <span>
                <span>TVL</span>
                <span className="pl-4">{tvl.ubq}M</span>
              </span> */}
            </div>
            <div className="text-left w-10/12 mb-2">
              <span>Minimizes deposit fee</span>
              <Tooltip content="The deposit fee gets converted to uAR when you withdraw">
                <span className="pl-2">{icons.svgs.help}</span>
              </Tooltip>
            </div>
            <div className="flex justify-between items-center">
              <input
                type="number"
                value={ubq || ""}
                onChange={handleInputChange}
                name="ubq"
                placeholder={`Max ${maxUbqAmount.toLocaleString()}`}
                className="w-10/12 m-0 box-border"
              />
              <div className="flex flex-col text-center justify-center items-center text-accent w-2/12">
                <span>{Math.round(ubqFee() * 100 * 100) / 100}%</span>
                <span className="text-xs">FEE</span>
              </div>
            </div>
            <div className="w-10/12 flex justify-end mt-2">
              <span className="flex-grow opacity-50 text-left">Balance: {f(balance.ubq)}</span>
              <button onClick={setMaxUbq}>Max</button>
            </div>
          </div>

          <div className="w-5/12" style={{ backgroundImage: `url('data:image/svg+xml;utf8,${icons.stringsCyan.uad}')` }}>
            <div className="flex justify-between">
              <span className="font-bold">uAD</span>
              {/* <span className="pl-4">
                <span>TVL</span>
                <span className="pl-4">{tvl.uad}M</span>
              </span> */}
            </div>
            <div className="text-left  w-10/12 mb-2">
              <span>Boosts yield</span>
              {/* <span>up to {(maxYieldBonusPct - baseYieldBonusPct) * 100}% more</span> */}
              <Tooltip content="Match 50% of the USDC deposit and you get an extra 50% boost">
                <span className="pl-1">{icons.svgs.help}</span>
              </Tooltip>
            </div>
            <div className="flex justify-between items-center">
              <input
                type="number"
                disabled={usdc <= 0}
                value={uad || ""}
                onChange={handleInputChange}
                name="uad"
                placeholder={`Max ${maxUadPct * 100}% of deposit`}
                className="w-10/12 m-0 box-border disabled:opacity-25 disabled:bg-white disabled:text-black"
              />
              <div className="flex flex-col text-center justify-center items-center text-accent">
                <span>{Math.round(uadBoost() * 100 * 100) / 100}%</span>
                <span className="text-xs">BOOST</span>
              </div>
            </div>
            <div className="w-10/12 flex justify-end mt-2">
              <span className="flex-grow opacity-50 text-left">Balance: {f(balance.uad)}</span>
              <button onClick={setMaxUad}>Max</button>
            </div>
          </div>
        </div>

        <>
          {errors.length ? (
            <div>
              {errors.map((err, i) => (
                <div key={i} className="text-red-500">
                  {err}
                </div>
              ))}
            </div>
          ) : null}
          <button onClick={deposit} disabled={!canDeposit() || disable} className="w-full flex justify-center m-0 mt-8">
            Deposit
          </button>
        </>
      </>
    );
  }
);

export default connectedWithUserContext(YieldFarmingContainer);
