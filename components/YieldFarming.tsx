import { memo, useEffect, useState } from "react";
import { connectedWithUserContext, useConnectedContext, UserContext } from "./context/connected";
import * as widget from "./ui/widget";
import { WarningIcon, HelpIcon } from "./ui/icons";
import { loadYieldProxyData, loadYieldProxyDepositInfo, YieldProxyDepositInfo, YieldProxyData, ensureERC20Allowance } from "./common/contractsShortcuts";
import { BigNumber, ethers } from "ethers";
import { performTransaction, constrainNumber } from "./common/utils";

type Actions = {
  onDeposit: (payload: { usdc: number; ubq: number; uad: number }) => void;
};

export const YieldFarmingContainer = ({ contracts, account, signer }: UserContext) => {
  const [yieldProxyData, setYieldProxyData] = useState<YieldProxyData | null>(null);
  const [depositInfo, setDepositInfo] = useState<YieldProxyDepositInfo | null>(null);
  const { refreshBalances } = useConnectedContext();
  const [isProcessing, setIsProcessing] = useState(false);

  useEffect(() => {
    (async function () {
      const ypd = await loadYieldProxyData(contracts);
      const di = await loadYieldProxyDepositInfo(ypd, contracts, account.address);
      setYieldProxyData(ypd);
      setDepositInfo(di);
    })();
  }, []);

  const actions: Actions = {
    onDeposit: async ({ usdc, ubq, uad }) => {
      setIsProcessing(true);
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
        refreshBalances();
      } else {
        // TODO: Show transaction error
      }
      setIsProcessing(false);
    },
  };

  return <YieldFarmingSubcontainer yieldProxyData={yieldProxyData} depositInfo={depositInfo} isProcessing={isProcessing} actions={actions} />;
};

type YieldFarmingSubcontainerProps = {
  yieldProxyData: YieldProxyData | null;
  depositInfo: YieldProxyDepositInfo | null;
  isProcessing: boolean;
  actions: Actions;
};

export const YieldFarmingSubcontainer = ({ actions, yieldProxyData, depositInfo, isProcessing }: YieldFarmingSubcontainerProps) => {
  return (
    <widget.Container className="max-w-screen-md !mx-auto relative" transacting={isProcessing}>
      <widget.Title text="Boosted yield farming" />
      <div className="flex justify-evenly items-center p-4 border border-white/10 border-solid bg-accent bg-opacity-10 rounded-md mb-4">
        <div className="w-20">{WarningIcon}</div>
        <p className="text-left flex-grow">
          uAR is 1:1 redeemable for uAD when our TWAP goes above 1.00.{" "}
          <a target="_blank" href="https://medium.com/ubiquity-dao/ubiquitys-debt-system-explained-40e51325fc5">
            Learn more &raquo;
          </a>
        </p>
      </div>
      {depositInfo && yieldProxyData ? (
        depositInfo ? (
          <div>Already deposited</div>
        ) : (
          <YieldFarmingDeposit
            tvl={{ usdc: 1.2, ubq: 2.5, uad: 0.6 }}
            usdcApy={{ min: 14.18, max: 27.07 }}
            maxUbqAmount={+ethers.utils.formatEther(yieldProxyData.depositFeeUbqMax)}
            maxUadPct={yieldProxyData.bonusYieldUadMaxPct}
            baseYieldBonusPct={yieldProxyData.bonusYieldBasePct}
            maxYieldBonusPct={yieldProxyData.bonusYieldMaxPct}
            baseDepositFeePct={yieldProxyData.depositFeeBasePct}
            minDepositFeePct={0}
            balance={{ usdc: 200, ubq: 150, uad: 300 }}
            onDeposit={actions.onDeposit}
          />
        )
      ) : (
        "Loading..."
      )}
    </widget.Container>
  );
};

type YieldFarmingDepositProps = {
  tvl: { usdc: number; ubq: number; uad: number };
  balance: { usdc: number; ubq: number; uad: number };
  usdcApy: { min: number; max: number };
  baseYieldBonusPct: number; // 0.5
  maxYieldBonusPct: number; // 1
  baseDepositFeePct: number; // 0.1
  minDepositFeePct: number; // 0
  maxUbqAmount: number; // 10000
  maxUadPct: number; // 0.5

  onDeposit: Actions["onDeposit"];
};

export const YieldFarmingDeposit = memo(
  ({
    usdcApy,
    maxUbqAmount,
    maxUadPct,
    baseYieldBonusPct,
    maxYieldBonusPct,
    tvl,
    baseDepositFeePct,
    minDepositFeePct,
    balance,
    onDeposit,
  }: YieldFarmingDepositProps) => {
    const [usdc, setUsdc] = useState<number>(0);
    const [ubq, setUbq] = useState<number>(0);
    const [uad, setUad] = useState<number>(0);
    const [errors, setErrors] = useState<string[]>([]);

    const deposit: () => void = () => {
      if (usdc && ubq && uad) {
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
      console.log(uad, maxUadPct, usdc);
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

    useEffect(() => {
      const errors: string[] = [];
      const noFunds = (token: string) => `You don't have enough ${token.toUpperCase()} funds`;
      if (usdc > balance.usdc) errors.push(noFunds("usdc"));
      if (ubq > balance.ubq) errors.push(noFunds("ubq"));
      if (uad > balance.uad) errors.push(noFunds("uad"));

      setErrors(errors);
    }, [usdc, ubq, uad]);

    return (
      <>
        <widget.SubTitle text="Deposit" />
        <div className="flex justify-between items-center mb-8">
          <div className="w-5/12">
            <div className="flex justify-between">
              <span className="font-bold">USDC</span>
              <span>
                <span>TVL</span>
                <span className="pl-4">{tvl.usdc}M</span>
              </span>
            </div>
            <div className="text-left mb-2">
              <span>
                {usdcApy.min.toFixed(2)}% - {usdcApy.max.toFixed(2)}%
              </span>
              <span className="pl-2">APY</span>
              <span className="pl-2">{HelpIcon}</span>
            </div>
            <input type="number" value={usdc || ""} onChange={handleInputChange} name="usdc" className="w-full m-0 box-border" />
          </div>
          <div className="w-1/2">
            <div className="text-3xl text-accent font-bold">{Math.round(maxApy() * 100) / 100}%</div>
            <div>
              Max APY in uAR<span className="pl-2">{HelpIcon}</span>
            </div>
          </div>
        </div>
        <widget.SubTitle text="Boosters" />
        <div className="flex justify-between items-center mb-4">
          <div className="w-5/12">
            <div className="flex justify-between">
              <span className="font-bold">UBQ</span>
              <span>
                <span>TVL</span>
                <span className="pl-4">{tvl.ubq}M</span>
              </span>
            </div>
            <div className="text-left w-10/12 mb-2">
              <span>Minimizes deposit fee</span>
              <span className="pl-2" title="The deposit fee gets converted to uAR when you withdraw">
                {HelpIcon}
              </span>
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
              <span className="flex-grow opacity-50 text-left">Balance: {balance.ubq}</span>
              <span className="text-accent cursor-pointer" onClick={setMaxUbq}>
                Max
              </span>
            </div>
          </div>
          <div className="w-5/12">
            <div className="flex justify-between">
              <span className="font-bold">uAD</span>
              <span className="pl-4">
                <span>TVL</span>
                <span className="pl-4">{tvl.uad}M</span>
              </span>
            </div>
            <div className="text-left  w-10/12 mb-2">
              <span>Multiples yield up to {(maxYieldBonusPct - baseYieldBonusPct) * 100}% more</span>
              <span className="pl-2">{HelpIcon}</span>
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
              <span className="text-accent cursor-pointer" onClick={setMaxUad}>
                Max
              </span>
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
          <button onClick={deposit} disabled={!canDeposit()} className="w-full flex justify-center m-0 mt-8">
            Deposit
          </button>
        </>
      </>
    );
  }
);

export default connectedWithUserContext(YieldFarmingContainer);
