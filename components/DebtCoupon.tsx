import { BigNumber, ethers } from "ethers";
import { ChangeEvent, Dispatch, memo, SetStateAction, useEffect, useMemo, useState } from "react";
import * as widget from "./ui/widget";
import { connectedWithUserContext, useConnectedContext } from "./context/connected";
import { Balances } from "./common/contracts-shortcuts";
import { formatTimeDiff } from "./common/utils";
import {
  DebtCouponManager__factory,
  ICouponsForDollarsCalculator__factory,
  UbiquityAlgorithmicDollarManager,
  UbiquityAlgorithmicDollar__factory,
} from "../contracts/artifacts/types";
import { ADDRESS } from "../contracts";

type Actions = {
  onRedeem: () => void;
  onSwap: () => void;
  onBurn: (uadAmount: string, setErrMsg: Dispatch<SetStateAction<string | undefined>>) => void;
};

async function _expectedDebtCoupon(
  amount: BigNumber,
  manager: UbiquityAlgorithmicDollarManager | null,
  provider: ethers.providers.Web3Provider | null,
  setExpectedDebtCoupon: Dispatch<SetStateAction<BigNumber | undefined>>
) {
  if (manager && provider) {
    const formulaAdr = await manager.couponCalculatorAddress();
    const SIGNER = provider.getSigner();
    const couponCalculator = ICouponsForDollarsCalculator__factory.connect(formulaAdr, SIGNER);
    const expectedDebtCoupon = await couponCalculator.getCouponAmount(amount);
    console.log("expectedDebtCoupon", expectedDebtCoupon.toString());
    setExpectedDebtCoupon(expectedDebtCoupon);
  }
}

const DEBT_COUPON_DEPOSIT_TRANSACTION = "DEBT_COUPON_DEPOSIT_TRANSACTION";

export const DebtCouponContainer = () => {
  const { balances, twapPrice, manager, provider, account, setBalances, updateActiveTransaction } = useConnectedContext();
  const actions: Actions = {
    onRedeem: () => {
      console.log("onRedeem");
    },
    onSwap: () => {
      console.log("onSwap");
    },
    onBurn: async (uadAmount, setErrMsg) => {
      setErrMsg("");
      const title = "Burning uAD...";
      updateActiveTransaction({ id: DEBT_COUPON_DEPOSIT_TRANSACTION, title, active: true });
      const uadAmountValue = uadAmount;
      if (!uadAmountValue) {
        console.log("uadAmountValue", uadAmountValue);
        setErrMsg("amount not valid");
      } else {
        const amount = ethers.utils.parseEther(uadAmountValue);
        if (BigNumber.isBigNumber(amount)) {
          if (amount.gt(BigNumber.from(0))) {
            await depositDollarForDebtCoupons(amount, setBalances);
          } else {
            setErrMsg("uAD Amount should be greater than 0");
          }
        } else {
          setErrMsg("amount not valid");
          updateActiveTransaction({ id: DEBT_COUPON_DEPOSIT_TRANSACTION, active: false });
          return;
        }
      }
      updateActiveTransaction({ id: DEBT_COUPON_DEPOSIT_TRANSACTION, active: false });
    },
  };

  const depositDollarForDebtCoupons = async (amount: BigNumber, setBalances: Dispatch<SetStateAction<Balances | null>>) => {
    if (provider && account && manager && balances) {
      const uAD = UbiquityAlgorithmicDollar__factory.connect(await manager.dollarTokenAddress(), provider.getSigner());
      const allowance = await uAD.allowance(account.address, ADDRESS.DEBT_COUPON_MANAGER);
      console.log("allowance", ethers.utils.formatEther(allowance), "amount", ethers.utils.formatEther(amount));
      if (allowance.lt(amount)) {
        // first approve
        const approveTransaction = await uAD.approve(ADDRESS.DEBT_COUPON_MANAGER, amount);

        const approveWaiting = await approveTransaction.wait();
        console.log(
          `approveWaiting gas used with 100 gwei / gas:${ethers.utils.formatEther(approveWaiting.gasUsed.mul(ethers.utils.parseUnits("100", "gwei")))}`
        );
      }

      const allowance2 = await uAD.allowance(account.address, ADDRESS.DEBT_COUPON_MANAGER);
      console.log("allowance2", ethers.utils.formatEther(allowance2));
      // depositDollarForDebtCoupons uAD

      const debtCouponMgr = DebtCouponManager__factory.connect(ADDRESS.DEBT_COUPON_MANAGER, provider.getSigner());
      const depositDollarForDebtCouponsWaiting = await debtCouponMgr.exchangeDollarsForDebtCoupons(amount);
      await depositDollarForDebtCouponsWaiting.wait();

      // fetch new uar and uad balance
      setBalances({
        ...balances,
        uad: BigNumber.from(0),
        debtCoupon: BigNumber.from(0),
      });
    }
  };

  const priceIncreaseFormula = async (amount: number) => {
    const formula = 0.001;
    return amount * formula;
  };

  const cycleStartDate = 1637625600000;
  const uarDeprecationRate = 0.0001;
  const uarCurrentRewardPct = 0.05;
  const udebtDeprecationRate = 0.0015;
  const udebtCurrentRewardPct = 0.05;
  const udebtExpirationTime = 1640217600000;
  const udebtUbqRedemptionRate = 0.25;
  const uadTotalSupply = 233000;
  const ubondTotalSupply = 10000;
  const uarTotalSupply = 30000;
  const udebtTotalSupply = 12000;

  return (
    <widget.Container className="max-w-screen-md !mx-auto relative">
      <widget.Title text="Debt Coupon" />
      {balances && (
        <DebtCoupon
          twapPrice={twapPrice}
          balances={balances}
          actions={actions}
          cycleStartDate={cycleStartDate}
          uarDeprecationRate={uarDeprecationRate}
          uarCurrentRewardPct={uarCurrentRewardPct}
          udebtDeprecationRate={udebtDeprecationRate}
          udebtCurrentRewardPct={udebtCurrentRewardPct}
          udebtExpirationTime={udebtExpirationTime}
          udebtUbqRedemptionRate={udebtUbqRedemptionRate}
          priceIncreaseFormula={priceIncreaseFormula}
          uadTotalSupply={uadTotalSupply}
          ubondTotalSupply={ubondTotalSupply}
          uarTotalSupply={uarTotalSupply}
          udebtTotalSupply={udebtTotalSupply}
          manager={manager}
          provider={provider}
        />
      )}
    </widget.Container>
  );
};

type DebtCouponProps = {
  twapPrice: BigNumber | null;
  balances: Balances;
  actions: Actions;
  cycleStartDate: number;
  uarDeprecationRate: number;
  uarCurrentRewardPct: number;
  udebtDeprecationRate: number;
  udebtCurrentRewardPct: number;
  udebtExpirationTime: number;
  udebtUbqRedemptionRate: number;
  priceIncreaseFormula: (amount: number) => Promise<number>;
  uadTotalSupply: number;
  ubondTotalSupply: number;
  uarTotalSupply: number;
  udebtTotalSupply: number;
  manager: UbiquityAlgorithmicDollarManager | null;
  provider: ethers.providers.Web3Provider | null;
};

const DebtCoupon = memo(
  ({
    twapPrice,
    actions,
    cycleStartDate,
    uarDeprecationRate,
    uarCurrentRewardPct,
    udebtDeprecationRate,
    udebtCurrentRewardPct,
    udebtExpirationTime,
    udebtUbqRedemptionRate,
    priceIncreaseFormula,
    uadTotalSupply,
    ubondTotalSupply,
    uarTotalSupply,
    udebtTotalSupply,
    manager,
    provider,
  }: DebtCouponProps) => {
    const [formattedSwapPrice, setFormattedSwapPrice] = useState("");
    const [selectedCurrency, selectCurrency] = useState("udebt");
    const [increasedValue, setIncreasedValue] = useState(0);
    const [errMsg, setErrMsg] = useState<string>();
    const [expectedDebtCoupon, setExpectedDebtCoupon] = useState<BigNumber>();
    const [uadAmount, setUadAmount] = useState("");

    const handleTabSelect = (tab: string) => {
      selectCurrency(tab);
    };

    useEffect(() => {
      if (twapPrice) {
        setFormattedSwapPrice(parseFloat(ethers.utils.formatEther(twapPrice)).toFixed(2));
      }
    }, [twapPrice]);

    const calculatedCycleStartDate = useMemo(() => {
      if (cycleStartDate) {
        const diff = Date.now() - cycleStartDate;
        return formatTimeDiff(diff);
      }
    }, [cycleStartDate]);

    const calculatedUdebtExpirationTime = useMemo(() => {
      if (udebtExpirationTime) {
        const diff = udebtExpirationTime - Date.now();
        return formatTimeDiff(diff);
      }
    }, [udebtExpirationTime]);

    const handleInputUAD = async (e: ChangeEvent) => {
      setErrMsg("");
      const title = "Input uAD...";
      const missing = `Missing input value for`;
      const bignumberErr = `can't parse BigNumber from`;

      const subject = `uAD amount`;
      const amountEl = e.target as HTMLInputElement;
      const amountValue = amountEl?.value;
      if (!amountValue) {
        setErrMsg(`${missing} ${subject}`);
        return;
      }
      if (BigNumber.isBigNumber(amountValue)) {
        setErrMsg(`${bignumberErr} ${subject}`);
        return;
      }
      const amount = ethers.utils.parseEther(amountValue);
      if (!amount.gt(BigNumber.from(0))) {
        setErrMsg(`${subject} should be greater than 0`);
        return;
      }
      setUadAmount(amountValue);

      _expectedDebtCoupon(amount, manager, provider, setExpectedDebtCoupon);
    };

    const handleBurn = () => {
      actions.onBurn(uadAmount, setErrMsg);
    };

    useEffect(() => {
      priceIncreaseFormula(10).then((value) => {
        setIncreasedValue(value);
      });
    });

    return (
      <>
        <div className="w-full flex h-8 rounded-md border border-white/10 border-solid relative">
          <div className="w-full flex">
            <div className="w-5/12 flex justify-end border-0 border-r border-white/10 border-solid">
              <span className="pr-2 self-center">${formattedSwapPrice}</span>
            </div>
            <div className="w-7/12 flex justify-center">
              <span className="pr-2 self-center">Pump cycle started {calculatedCycleStartDate} ago</span>
            </div>
          </div>
        </div>
        <div className="py-4">
          <span className="text-center">Burn uAD for debt coupons and help pump the price back up</span>
        </div>
        <div className="py-8">
          <span>Pump Cycle</span>
        </div>
        <div className="flex justify-center pb-4">
          <div className="w-2/4 px-8 border-0 border-r border-white/10 border-solid">
            <span>Fungible (uAR)</span>
            <table className="w-full">
              <tbody>
                <tr>
                  <td className="pr-4 text-right">Deprecation rate</td>
                  <td className="pl-4 text-left">{uarDeprecationRate * 100}% / week</td>
                </tr>
                <tr>
                  <td className="pr-4 text-right">Current reward %</td>
                  <td className="pl-4 text-left">{uarCurrentRewardPct * 100}%</td>
                </tr>
                <tr>
                  <td className="pr-4 text-right">Expires?</td>
                  <td className="pl-4 text-left">No</td>
                </tr>
              </tbody>
            </table>
            <div>
              <span>Higher priority when redeeming</span>
            </div>
            <a href="">Learn more</a>
          </div>
          <div className="w-2/4 px-8">
            <span>Non-fungible (uDEBT)</span>
            <table className="w-full">
              <tbody>
                <tr>
                  <td className="pr-4 text-right">Deprecation rate</td>
                  <td className="pl-4 text-left">{udebtDeprecationRate * 100}%</td>
                </tr>
                <tr>
                  <td className="pr-4 text-right">Current reward %</td>
                  <td className="pl-4 text-left">{udebtCurrentRewardPct * 100}%</td>
                </tr>
                <tr>
                  <td className="pr-4 text-right">Expires?</td>
                  <td className="pl-4 text-left">After {calculatedUdebtExpirationTime}</td>
                </tr>
              </tbody>
            </table>
            <div>
              <span>Convertible to fungible</span>
            </div>
            <div>
              <span>Can be redeemed for UBQ at {udebtUbqRedemptionRate * 100}% rate</span>
            </div>
            <a href="">Learn more</a>
          </div>
        </div>
        <div className="inline-flex my-8">
          <span className="self-center">uAD</span>
          <input className="self-center" type="number" onChange={handleInputUAD} />
          <nav className="self-center flex flex-col border-b-2 sm:flex-row">
            <button
              className={`m-0 rounded-r-none self-center hover:text-accent focus:outline-none ${
                selectedCurrency === "uar" ? "text-accent font-medium border-accent" : "text-gray-600"
              }`}
              onClick={() => handleTabSelect("uar")}
            >
              uAR
            </button>
            <button
              className={`m-0 rounded-l-none self-center hover:text-accent focus:outline-none ${
                selectedCurrency === "udebt" ? "text-accent font-medium border-accent" : "text-gray-600"
              }`}
              onClick={() => handleTabSelect("udebt")}
            >
              uDEBT
            </button>
          </nav>
          <button onClick={handleBurn} className="self-center">
            Burn
          </button>
        </div>
        <p>{errMsg}</p>
        {expectedDebtCoupon && <p>expected uDEBT {ethers.utils.formatEther(expectedDebtCoupon)}</p>}
        <div className="my-4">
          <span>Price will increase by an estimated of +${increasedValue}</span>
        </div>
        <div className="my-4">
          <span>Reward Cycle</span>
        </div>
        <div className="w-full">
          <div className="w-10/12 inline-flex justify-between border rounded-md border-white/10 border-solid">
            <div className="w-1/4 text-center self-center">
              <span>uAD</span>
            </div>
            <div className="w-1/4 text-center self-center">
              <div className="pt-2 pb-1">Total Supply</div>
              <div className="pt-1 pb-2">{uadTotalSupply}</div>
            </div>
            <div className="w-1/4 text-center self-center">
              <div className="pt-2 pb-1">Minted</div>
              <div className="pt-1 pb-2">25k</div>
            </div>
            <div className="w-1/4 text-center self-center">
              <div className="pt-2 pb-1">Mintable</div>
              <div className="pt-1 pb-2">12k</div>
            </div>
          </div>
        </div>
        <div className="w-full mt-4">
          <div className="w-10/12 inline-flex">
            <div className="w-1/4 self-center">
              <span>Total debt</span>
            </div>
            <div className="w-3/4 inline-flex justify-between border rounded-md rounded-b-none border-white/10 border-solid">
              <div className="w-1/3">
                <div className="pt-2 pb-1">uBOND</div>
                <div className="pt-1 pb-2">{ubondTotalSupply}</div>
              </div>
              <div className="w-1/3">
                <div className="pt-2 pb-1">uAR</div>
                <div className="pt-1 pb-2">{uarTotalSupply}</div>
              </div>
              <div className="w-1/3">
                <div className="pt-2 pb-1">uDEBT</div>
                <div className="pt-1 pb-2">{udebtTotalSupply}</div>
              </div>
            </div>
          </div>
        </div>
        <div className="w-full">
          <div className="w-10/12 inline-flex">
            <div className="w-1/4 self-center">
              <span>Redeemable</span>
            </div>
            <div className="inline-flex w-3/4 justify-between border rounded-md rounded-t-none border-white/10 border-solid">
              <div className="w-1/3 py-2">10,000</div>
              <div className="w-1/3 py-2">27,000</div>
              <div className="w-1/3 py-2">0</div>
            </div>
          </div>
        </div>
        <div className="py-8">
          <span>Your Coupons</span>
        </div>
        <div className="w-10/12 my-0 mx-auto">
          <div className="w-full">
            <div className="inline-flex justify-between w-full">
              <div className="w-5/12 text-left self-center">
                <span>uBOND 1,000</span>
              </div>
              <div className="inline-flex w-7/12 justify-between">
                <input type="text" />
                <button onClick={actions.onRedeem}>Redeem</button>
              </div>
            </div>
          </div>
          <div className="w-full">
            <div className="inline-flex justify-between w-full">
              <div className="w-5/12 text-left self-center">
                <span>uAR 3,430 - $2,120</span>
              </div>
              <div className="inline-flex w-7/12 justify-between">
                <input type="text" />
                <button onClick={actions.onRedeem}>Redeem</button>
              </div>
            </div>
          </div>
          <div className="w-full">
            <div className="inline-flex justify-between w-full">
              <div className="w-5/12 text-left self-center">
                <span>Deprecation rate 10% / week</span>
              </div>
              <div className="inline-flex w-7/12 justify-between">
                <span className="text-center w-1/2 self-center">2120 uDEBT</span>
                <button onClick={actions.onSwap}>Swap</button>
              </div>
            </div>
          </div>
        </div>
        <div className="w-10/12 my-0 mx-auto">
          <table className="w-full border border-white/10 border-solid border-colapse mt-16">
            <thead>
              <tr>
                <th className="normal-case">uDEBT</th>
                <th className="normal-case">Expiration</th>
                <th className="normal-case">Swap</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              <tr>
                <td>1,000</td>
                <td>3.2 weeks</td>
                <td>800 uAR</td>
                <td>
                  <button onClick={actions.onRedeem}>Redeem</button>
                </td>
              </tr>
              <tr>
                <td>500</td>
                <td>1.3 weeks</td>
                <td>125 uAR</td>
                <td>
                  <button onClick={actions.onRedeem}>Redeem</button>
                </td>
              </tr>
              <tr>
                <td className="h-12">666</td>
                <td>Expired</td>
                <td>166.5 UBQ</td>
                <td></td>
              </tr>
            </tbody>
          </table>
        </div>
      </>
    );
  }
);

export default connectedWithUserContext(DebtCouponContainer);
