import { BigNumber, ethers } from "ethers";
import { ChangeEvent, Dispatch, memo, SetStateAction, useEffect, useMemo, useState } from "react";
import * as widget from "./ui/widget";
import { connectedWithUserContext, useConnectedContext } from "./context/connected";
import { Balances } from "./common/contracts-shortcuts";
import { formatTimeDiff, constrainNumber } from "./common/utils";
import {
  DebtCouponManager__factory,
  ICouponsForDollarsCalculator__factory,
  UbiquityAlgorithmicDollarManager,
  UbiquityAlgorithmicDollar__factory,
} from "../contracts/artifacts/types";
import { ADDRESS } from "../contracts";

type Actions = {
  onRedeem: () => void;
  onSwap: (amount: number, unit: string) => void;
  onBurn: (uadAmount: string, setErrMsg: Dispatch<SetStateAction<string | undefined>>) => void;
};

type Coupon = {
  amount: number;
  expiration: number;
  swap: { amount: number; unit: string };
};

type Coupons = {
  uDEBT: Coupon[];
  uBOND: number;
  uAR: number;
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
  const coupons: Coupons = {
    uDEBT: [
      { amount: 1000, expiration: 1640390400000, swap: { amount: 800, unit: "uAR" } },
      { amount: 500, expiration: 1639526400000, swap: { amount: 125, unit: "uAR" } },
      { amount: 666, expiration: 1636934400000, swap: { amount: 166.5, unit: "UBQ" } },
    ],
    uBOND: 1000,
    uAR: 3430,
  };

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
          coupons={coupons}
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
  coupons: Coupons | null;
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
    coupons,
  }: DebtCouponProps) => {
    const [formattedSwapPrice, setFormattedSwapPrice] = useState("");
    const [selectedCurrency, selectCurrency] = useState("udebt");
    const [increasedValue, setIncreasedValue] = useState(0);
    const [errMsg, setErrMsg] = useState<string>();
    const [expectedDebtCoupon, setExpectedDebtCoupon] = useState<BigNumber>();
    const [uadAmount, setUadAmount] = useState("");
    const [uarAmount, setUarAmount] = useState("");
    const [ubondAmount, setUbondAmount] = useState("");

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

    const shouldDisableInput = (type: string) => {
      if (!coupons) {
        return true;
      } else if (type === "uar") {
        return !coupons.uAR || coupons.uAR <= 0;
      } else if (type === "ubond") {
        return !coupons.uBOND || coupons.uBOND <= 0;
      }
      return false;
    };

    const handleInputUAR = async (e: ChangeEvent) => {
      if (!coupons || !coupons.uAR) {
        return;
      }
      const amountEl = e.target as HTMLInputElement;
      const amountValue = amountEl?.value;
      setUarAmount(`${constrainNumber(parseFloat(amountValue), 0, coupons.uAR)}`);
    };

    const handleInputUBOND = async (e: ChangeEvent) => {
      if (!coupons || !coupons.uBOND) {
        return;
      }
      const amountEl = e.target as HTMLInputElement;
      const amountValue = amountEl?.value;
      setUbondAmount(`${constrainNumber(parseFloat(amountValue), 0, coupons.uBOND)}`);
    };

    const handleBurn = () => {
      actions.onBurn(uadAmount, setErrMsg);
    };

    const isLessThanOne = () => parseFloat(formattedSwapPrice) <= 1;

    const uarToUdebtFormula = (amount: string) => {
      const parsedValue = parseFloat(amount);
      return isNaN(parsedValue) ? 0 : parsedValue * 0.9;
    };

    useEffect(() => {
      priceIncreaseFormula(10).then((value) => {
        setIncreasedValue(value);
      });
    });

    return (
      <>
        <TwapPriceBar price={formattedSwapPrice} date={calculatedCycleStartDate} />
        {isLessThanOne() ? (
          <>
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
          </>
        ) : (
          <>
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
                  <div className="pt-1 pb-2">{uadTotalSupply.toLocaleString()}</div>
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
                    <div className="pt-1 pb-2">{ubondTotalSupply.toLocaleString()}</div>
                  </div>
                  <div className="w-1/3">
                    <div className="pt-2 pb-1">uAR</div>
                    <div className="pt-1 pb-2">{uarTotalSupply.toLocaleString()}</div>
                  </div>
                  <div className="w-1/3">
                    <div className="pt-2 pb-1">uDEBT</div>
                    <div className="pt-1 pb-2">{udebtTotalSupply.toLocaleString()}</div>
                  </div>
                </div>
              </div>
            </div>
            <div className="w-full">
              <div className="w-10/12 inline-flex">
                <div className="w-1/4 self-center">
                  <span>Redeemable</span>
                </div>
                <div className="inline-flex w-3/4 justify-between border border-t-0 rounded-md rounded-t-none border-white/10 border-solid">
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
                    <span>uBOND {coupons?.uBOND.toLocaleString()}</span>
                  </div>
                  <div className="inline-flex w-7/12 justify-between">
                    <input type="number" value={ubondAmount} disabled={shouldDisableInput("ubond")} onChange={handleInputUBOND} />
                    <button onClick={actions.onRedeem}>Redeem</button>
                  </div>
                </div>
              </div>
              <div className="w-full">
                <div className="inline-flex justify-between w-full">
                  <div className="w-5/12 text-left self-center">
                    <span>uAR {coupons?.uAR.toLocaleString()} - $2,120</span>
                  </div>
                  <div className="inline-flex w-7/12 justify-between">
                    <input type="number" value={uarAmount} disabled={shouldDisableInput("uar")} onChange={handleInputUAR} />
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
                    <span className="text-center w-1/2 self-center">{uarToUdebtFormula(uarAmount).toLocaleString()} uDEBT</span>
                    <button onClick={() => actions.onSwap(2120, "uDEBT")}>Swap</button>
                  </div>
                </div>
              </div>
            </div>
            <div className="w-10/12 my-0 mx-auto">
              <CouponTable coupons={coupons} onRedeem={actions.onRedeem} onSwap={actions.onSwap} />
            </div>
          </>
        )}
      </>
    );
  }
);

type TwapPriceBarProps = {
  price: string;
  date: string | undefined;
};

export const TwapPriceBar = ({ price, date }: TwapPriceBarProps) => {
  const calculatedPercent = () => {
    const parsedPrice = parseFloat(price);
    let leftBarPercent = (parsedPrice - 1) * 100 + 50;
    leftBarPercent = leftBarPercent < 20 ? 20 : leftBarPercent > 80 ? 80 : leftBarPercent;
    return leftBarPercent;
  };

  const leftPositioned = parseFloat(price) <= 1;

  return (
    <>
      <div className="w-full flex h-8 rounded-md border border-white/10 border-solid relative">
        <div className="w-full flex">
          <div
            className={`flex rounded-l-md justify-${leftPositioned ? "end bg-red-600" : "center"} border-0 border-r border-white/10 border-solid`}
            style={{ width: `${calculatedPercent()}%` }}
          >
            {leftPositioned ? <span className="pr-2 self-center">${price}</span> : <span className="pr-2 self-center">Redeeming cycle started {date} ago</span>}
          </div>
          <div className={`flex rounded-r-md justify-${leftPositioned ? "center" : "end bg-green-600"}`} style={{ width: `${100 - calculatedPercent()}%` }}>
            {leftPositioned ? <span className="pr-2 self-center">Pump cycle started {date} ago</span> : <span className="pr-2 self-center">${price}</span>}
          </div>
        </div>
      </div>
      <div className="py-4">
        <span className="text-center">
          {parseFloat(price) <= 1 ? "Burn uAD for debt coupons and help pump the price back up" : "Time to redeem debts coupons and help move the price down"}
        </span>
      </div>
    </>
  );
};

type CouponTableProps = {
  coupons: Coupons | null;
  onRedeem: Actions["onRedeem"];
  onSwap: Actions["onSwap"];
};

export const CouponTable = ({ coupons, onRedeem, onSwap }: CouponTableProps) => {
  return (
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
        {coupons && coupons.uDEBT && coupons.uDEBT.length
          ? coupons.uDEBT.map((coupon, index) => <CouponRow coupon={coupon} onRedeem={onRedeem} onSwap={onSwap} key={index} />)
          : null}
      </tbody>
    </table>
  );
};

type CouponRowProps = {
  coupon: Coupon;
  onRedeem: Actions["onRedeem"];
  onSwap: Actions["onSwap"];
};

export const CouponRow = ({ coupon, onRedeem, onSwap }: CouponRowProps) => {
  const timeDiff = coupon.expiration - Date.now();

  const handleSwap = () => {
    onSwap(coupon.swap.amount, coupon.swap.unit);
  };

  return (
    <tr>
      <td>{coupon.amount.toLocaleString()}</td>
      <td>
        {formatTimeDiff(Math.abs(timeDiff))}
        {timeDiff < 0 ? " ago" : ""}
      </td>
      <button onClick={handleSwap}>{`${coupon.swap.amount.toLocaleString()} ${coupon.swap.unit}`}</button>
      <td className="h-12">{timeDiff > 0 ? <button onClick={onRedeem}>Redeem</button> : null}</td>
    </tr>
  );
};

export default connectedWithUserContext(DebtCouponContainer);
