import { memo, useEffect, useState } from "react";
import { connectedWithUserContext, useConnectedContext, UserContext } from "./context/connected";
import * as widget from "./ui/widget";
import { WarningIcon, HelpIcon } from "./ui/icons";
import { loadYieldProxyData, YieldProxyData, ensureERC20Allowance } from "./common/contractsShortcuts";
import { BigNumber, ethers } from "ethers";
import { performTransaction } from "./common/utils";

type Actions = {
  onDeposit: (payload: { usdc: number; ubq: number; uad: number }) => void;
};

export const YieldFarmingContainer = ({ contracts, account, signer }: UserContext) => {
  const [yieldProxyData, setYieldProxyData] = useState<YieldProxyData | null>(null);
  const { refreshBalances } = useConnectedContext();
  const [isProcessing, setIsProcessing] = useState(false);

  useEffect(() => {
    (async function () {
      setYieldProxyData(await loadYieldProxyData(contracts));
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

  return (
    <YieldFarming
      maxUbq={1000}
      maxUad={1000}
      depositFee={10}
      balance={{ usdc: 200, ubq: 150, uad: 300 }}
      tvl={{ usdc: 1.2, ubq: 2.5, uad: 0.6 }}
      usdcApy={{ min: 14.18, max: 27.07 }}
      yieldProxyData={yieldProxyData}
      maxYieldMultiplier={40.59}
      withdrawable={false}
      onDeposit={actions.onDeposit}
      onWithdraw={() => {
        alert("onWithdraw");
      }}
    />
  );
};

type YieldFarmingProps = {
  tvl: { usdc: number; ubq: number; uad: number };
  usdcApy: { min: number; max: number };
  yieldProxyData: YieldProxyData | null;
  onDeposit: Actions["onDeposit"];
  maxYieldMultiplier: number;
  depositFee: number;
  maxUbq: number;
  maxUad: number;
  balance: { usdc: number; ubq: number; uad: number };
  withdrawable: boolean;
  onWithdraw: () => void;
};

export const YieldFarming = memo(
  ({ usdcApy, maxUbq, maxUad, maxYieldMultiplier, yieldProxyData, tvl, depositFee, withdrawable, balance, onWithdraw, onDeposit }: YieldFarmingProps) => {
    const [usdc, setUsdc] = useState(0);
    const [ubq, setUbq] = useState(0);
    const [uad, setUad] = useState(0);
    const [error, setError] = useState("");

    const deposit: () => void = () => {
      if (usdc && ubq && uad) {
        onDeposit({ usdc, ubq, uad });
      }
    };

    const handleNotEnoughCurrencyError = (currency: string) => {
      setError(`You don't have enough ${currency.toUpperCase()} funds`);
    };

    const handleInputChange = (event: React.ChangeEvent<HTMLInputElement>) => {
      const { value, name } = event.currentTarget;
      let parsedValue = parseFloat(value);
      switch (name) {
        case "usdc":
          if (parsedValue < 0) {
            parsedValue = 0;
          }
          setUsdc(parsedValue);
          break;

        case "ubq":
          if (parsedValue < 0) {
            parsedValue = 0;
          } else if (parsedValue > maxUbq) {
            parsedValue = maxUbq;
          }
          setUbq(parsedValue);
          break;

        case "uad":
          if (parsedValue < 0) {
            parsedValue = 0;
          } else if (parsedValue > maxUad * usdc) {
            parsedValue = maxUad * usdc;
          }
          setUad(parsedValue);
          break;

        default:
          break;
      }
    };

    const canDeposit: () => boolean = () => {
      if (usdc > 0 && usdc <= balance.usdc && ubq > 0 && ubq <= balance.ubq && uad > 0 && uad <= balance.uad) {
        return true;
      }
      return false;
    };

    const ubqFee = () => {
      return depositFee - (ubq / maxUbq) * depositFee;
    };

    const uadBoost = () => {
      if (usdc === 0) {
        return 0;
      }
      return ((uad / (maxUad * usdc)) * maxYieldMultiplier).toFixed(2) || 0;
    };

    const maxApy = () => {
      if (uad > 0) {
        return uadBoost();
      }
      return maxYieldMultiplier;
    };

    const setMaxUbq = () => {
      const max = maxUbq < balance.ubq ? balance.ubq : maxUbq;
      setUbq(max);
    };

    const setMaxUad = () => {
      let max = maxUad * usdc;
      if (max > balance.uad) {
        max = balance.uad;
      }
      setUad(max);
    };

    useEffect(() => {
      if (usdc <= 0 || ubq <= 0 || uad <= 0) {
        setError("Invalid Inputs");
      } else if (usdc > balance.usdc) {
        handleNotEnoughCurrencyError("usdc");
      } else if (ubq > balance.ubq) {
        handleNotEnoughCurrencyError("ubq");
      } else if (uad > balance.uad) {
        handleNotEnoughCurrencyError("uad");
      } else {
        setError("");
      }
    }, [usdc, ubq, uad]);

    return (
      <widget.Container className="max-w-screen-md !mx-auto relative">
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
            <input type="number" value={usdc} onChange={handleInputChange} name="usdc" placeholder="2,000" className="w-full m-0 box-border" />
          </div>
          <div className="w-1/2">
            <div className="text-3xl text-accent font-bold">{maxApy()}%</div>
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
              <input type="number" value={ubq} onChange={handleInputChange} name="ubq" placeholder="Max 10,000" className="w-10/12 m-0 box-border" />
              <div className="flex flex-col text-center justify-center items-center text-accent">
                <span>{ubqFee()}%</span>
                <span className="text-xs">FEE</span>
              </div>
            </div>
            <div className="w-10/12 flex justify-end mt-2">
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
              <span>Multiples yield up to 50%</span>
              <span className="pl-2">{HelpIcon}</span>
            </div>
            <div className="flex justify-between items-center">
              <input
                type="number"
                disabled={usdc <= 0}
                value={uad}
                onChange={handleInputChange}
                name="uad"
                placeholder="Max 50% of deposit"
                className="w-10/12 m-0 box-border"
              />
              <div className="flex flex-col text-center justify-center items-center text-accent">
                <span>{uadBoost()}%</span>
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
        {withdrawable ? (
          <button onClick={onWithdraw} className="w-full flex justify-center m-0 mt-8">
            Withdraw
          </button>
        ) : (
          <>
            {error && <span className="text-red-500">{error}</span>}
            <button onClick={deposit} disabled={!canDeposit()} className="w-full flex justify-center m-0 mt-8">
              Deposit
            </button>
          </>
        )}
      </widget.Container>
    );
  }
);

export default connectedWithUserContext(YieldFarmingContainer);
