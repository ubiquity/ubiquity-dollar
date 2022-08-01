import { Balances, useBalances, useTransactionLogger } from "@/lib/hooks";
import { constrainNumber, formatTimeDiff } from "@/lib/utils";
import withLoadedContext, { LoadedContext } from "@/lib/withLoadedContext";
import * as widget from "@/ui/widget";
import { BigNumber, ethers } from "ethers";
import { ChangeEvent, Dispatch, memo, SetStateAction, useEffect, useMemo, useState } from "react";
import usePrices from "./lib/usePrices";

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

const uDEBT = "uDEBT";
const uAR = "uAR";

// async function _expectedCoupon(
//   uadAmount: string,
//   contracts: Contracts | null,
//   selectedCurrency: string,
//   setExpectedCoupon: Dispatch<SetStateAction<BigNumber | undefined>>
// ) {
//   const amount = ethers.utils.parseEther(uadAmount);
//   if (contracts && amount.gt(BigNumber.from(0))) {
//     if (selectedCurrency === uDEBT) {
//       const expectedCoupon = await contracts.coupon.getCouponAmount(amount);
//       console.log("expectedCoupon", expectedCoupon.toString());
//       setExpectedCoupon(expectedCoupon);
//     } else if (selectedCurrency === uAR) {
//       const blockHeight = await contracts.debtCouponManager.blockHeightDebt();
//       const expectedCoupon = await contracts.uarCalc.getUARAmount(amount, blockHeight);
//       console.log("expectedCoupon", expectedCoupon.toString());
//       setExpectedCoupon(expectedCoupon);
//     }
//   }
// }

// eslint-disable-next-line @typescript-eslint/no-unused-vars
export const DebtCouponContainer = ({ managedContracts, deployedContracts, web3Provider, walletAddress, signer }: LoadedContext) => {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [balances, refreshBalances] = useBalances();
  const [, doTransaction] = useTransactionLogger();
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const [twapPrice, spotPrice] = usePrices();

  const actions: Actions = {
    onRedeem: () => {
      console.log("onRedeem");
    },
    onSwap: () => {
      console.log("onSwap");
    },
    onBurn: async (uadAmount, setErrMsg) => {
      setErrMsg("");
      await doTransaction("Burning uAD...", async () => {});
    },
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
    <widget.Container>
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
  uadTotalSupply: number;
  ubondTotalSupply: number;
  uarTotalSupply: number;
  udebtTotalSupply: number;
  coupons: Coupons | null;
  priceIncreaseFormula: (amount: number) => Promise<number>;
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
    uadTotalSupply,
    ubondTotalSupply,
    uarTotalSupply,
    udebtTotalSupply,
    coupons,
    priceIncreaseFormula,
  }: DebtCouponProps) => {
    const [formattedSwapPrice, setFormattedSwapPrice] = useState("");
    const [selectedCurrency, selectCurrency] = useState(uDEBT);
    const [increasedValue, setIncreasedValue] = useState(0);
    const [errMsg, setErrMsg] = useState<string>();
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const [expectedCoupon, setExpectedCoupon] = useState<BigNumber>();
    const [uadAmount, setUadAmount] = useState("");

    const handleTabSelect = (tab: string) => {
      selectCurrency(tab);
    };

    useEffect(() => {
      if (twapPrice) {
        setFormattedSwapPrice(parseFloat(ethers.utils.formatEther(twapPrice)).toFixed(2));
        // setFormattedSwapPrice("1.06");
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
    };

    const handleBurn = () => {
      actions.onBurn(uadAmount, setErrMsg);
    };

    const isLessThanOne = () => parseFloat(formattedSwapPrice) <= 1;

    useEffect(() => {
      if (uadAmount) {
        // _expectedCoupon(uadAmount, contracts, selectedCurrency, setExpectedCoupon);
      }
    }, [uadAmount, selectedCurrency]);

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
            <PumpCycle
              uarDeprecationRate={uarDeprecationRate}
              uarCurrentRewardPct={uarCurrentRewardPct}
              udebtDeprecationRate={udebtDeprecationRate}
              udebtCurrentRewardPct={udebtCurrentRewardPct}
              udebtUbqRedemptionRate={udebtUbqRedemptionRate}
              calculatedUdebtExpirationTime={calculatedUdebtExpirationTime}
            />
            <UadBurning
              handleInputUAD={handleInputUAD}
              selectedCurrency={selectedCurrency}
              handleTabSelect={handleTabSelect}
              handleBurn={handleBurn}
              errMsg={errMsg}
              expectedCoupon={expectedCoupon}
              increasedValue={increasedValue}
            />
          </>
        ) : (
          <Coupons
            uadTotalSupply={uadTotalSupply}
            ubondTotalSupply={ubondTotalSupply}
            uarTotalSupply={uarTotalSupply}
            udebtTotalSupply={udebtTotalSupply}
            coupons={coupons}
            actions={actions}
          />
        )}
      </>
    );
  }
);

type CouponsProps = {
  uadTotalSupply: number;
  ubondTotalSupply: number;
  uarTotalSupply: number;
  udebtTotalSupply: number;
  coupons: Coupons | null;
  actions: Actions;
};

export const Coupons = ({ uadTotalSupply, ubondTotalSupply, uarTotalSupply, udebtTotalSupply, coupons, actions }: CouponsProps) => {
  return (
    <>
      <RewardCycleInfo
        uadTotalSupply={uadTotalSupply}
        ubondTotalSupply={ubondTotalSupply}
        uarTotalSupply={uarTotalSupply}
        udebtTotalSupply={udebtTotalSupply}
      />
      <div>
        <span>Your Coupons</span>
      </div>
      <CouponRedeem coupons={coupons} actions={actions} />
      <CouponTable coupons={coupons} onRedeem={actions.onRedeem} onSwap={actions.onSwap} />
    </>
  );
};

type CouponRedeemProps = {
  coupons: Coupons | null;
  actions: Actions;
};

export const CouponRedeem = ({ coupons, actions }: CouponRedeemProps) => {
  const [uarAmount, setUarAmount] = useState("");
  const [ubondAmount, setUbondAmount] = useState("");
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

  const uarToUdebtFormula = (amount: string) => {
    const parsedValue = parseFloat(amount);
    return isNaN(parsedValue) ? 0 : parsedValue * 0.9;
  };

  return (
    <>
      <div>
        <div>
          <div>
            <div>
              <span>uBOND {coupons?.uBOND.toLocaleString()}</span>
            </div>
            <div>
              <input type="number" value={ubondAmount} disabled={shouldDisableInput("ubond")} onChange={handleInputUBOND} />
              <button onClick={actions.onRedeem}>Redeem</button>
            </div>
          </div>
        </div>
        <div>
          <div>
            <div>
              <span>uAR {coupons?.uAR.toLocaleString()} - $2,120</span>
            </div>
            <div>
              <input type="number" value={uarAmount} disabled={shouldDisableInput("uar")} onChange={handleInputUAR} />
              <button onClick={actions.onRedeem}>Redeem</button>
            </div>
          </div>
        </div>
        <div>
          <div>
            <div>
              <span>Deprecation rate 10% / week</span>
            </div>
            <div>
              <span>{uarToUdebtFormula(uarAmount).toLocaleString()} uDEBT</span>
              <button onClick={() => actions.onSwap(2120, uDEBT)}>Swap</button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

type RewardCycleInfoProps = {
  uadTotalSupply: number;
  ubondTotalSupply: number;
  uarTotalSupply: number;
  udebtTotalSupply: number;
};

export const RewardCycleInfo = ({ uadTotalSupply, ubondTotalSupply, uarTotalSupply, udebtTotalSupply }: RewardCycleInfoProps) => {
  return (
    <>
      <div>
        <span>Reward Cycle</span>
      </div>
      <div>
        <div>
          <div>
            <span>uAD</span>
          </div>
          <div>
            <div>Total Supply</div>
            <div>{uadTotalSupply.toLocaleString()}</div>
          </div>
          <div>
            <div>Minted</div>
            <div>25k</div>
          </div>
          <div>
            <div>Mintable</div>
            <div>12k</div>
          </div>
        </div>
      </div>
      <div>
        <div>
          <div>
            <span>Total debt</span>
          </div>
          <div>
            <div>
              <div>uBOND</div>
              <div>{ubondTotalSupply.toLocaleString()}</div>
            </div>
            <div>
              <div>uAR</div>
              <div>{uarTotalSupply.toLocaleString()}</div>
            </div>
            <div>
              <div>uDEBT</div>
              <div>{udebtTotalSupply.toLocaleString()}</div>
            </div>
          </div>
        </div>
      </div>
      <div>
        <div>
          <div>
            <span>Redeemable</span>
          </div>
          <div>
            <div>10,000</div>
            <div>27,000</div>
            <div>0</div>
          </div>
        </div>
      </div>
    </>
  );
};

type UadBurningProps = {
  selectedCurrency: string;
  errMsg: string | undefined;
  expectedCoupon: BigNumber | undefined;
  increasedValue: number;
  handleInputUAD: (e: ChangeEvent) => Promise<void>;
  handleTabSelect: (tab: string) => void;
  handleBurn: () => void;
};

export const UadBurning = ({ handleInputUAD, selectedCurrency, handleTabSelect, handleBurn, increasedValue, expectedCoupon, errMsg }: UadBurningProps) => {
  return (
    <>
      <div>
        <span>uAD</span>
        <input type="number" onChange={handleInputUAD} />
        <nav>
          <button onClick={() => handleTabSelect(uAR)}>uAR</button>
          <button onClick={() => handleTabSelect(uDEBT)}>uDEBT</button>
        </nav>
        <button onClick={handleBurn}>Burn</button>
      </div>
      <p>{errMsg}</p>
      {expectedCoupon && (
        <p>
          expected {selectedCurrency} {ethers.utils.formatEther(expectedCoupon)}
        </p>
      )}
      <div>
        <span>Price will increase by an estimated of +${increasedValue}</span>
      </div>
    </>
  );
};

type PumpCycleProps = {
  uarDeprecationRate: number;
  uarCurrentRewardPct: number;
  udebtDeprecationRate: number;
  udebtCurrentRewardPct: number;
  udebtUbqRedemptionRate: number;
  calculatedUdebtExpirationTime: string | undefined;
};

export const PumpCycle = ({
  uarDeprecationRate,
  uarCurrentRewardPct,
  udebtDeprecationRate,
  udebtCurrentRewardPct,
  udebtUbqRedemptionRate,
  calculatedUdebtExpirationTime,
}: PumpCycleProps) => {
  return (
    <>
      <div>
        <span>Pump Cycle</span>
      </div>
      <div>
        <div>
          <span>Fungible (uAR)</span>
          <table>
            <tbody>
              <tr>
                <td>Deprecation rate</td>
                <td>{uarDeprecationRate * 100}% / week</td>
              </tr>
              <tr>
                <td>Current reward %</td>
                <td>{uarCurrentRewardPct * 100}%</td>
              </tr>
              <tr>
                <td>Expires?</td>
                <td>No</td>
              </tr>
            </tbody>
          </table>
          <div>
            <span>Higher priority when redeeming</span>
          </div>
          <a href="">Learn more</a>
        </div>
        <div>
          <span>Non-fungible (uDEBT)</span>
          <table>
            <tbody>
              <tr>
                <td>Deprecation rate</td>
                <td>{udebtDeprecationRate * 100}%</td>
              </tr>
              <tr>
                <td>Current reward %</td>
                <td>{udebtCurrentRewardPct * 100}%</td>
              </tr>
              <tr>
                <td>Expires?</td>
                <td>After {calculatedUdebtExpirationTime}</td>
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
    </>
  );
};

type TwapPriceBarProps = {
  price: string;
  date: string | undefined;
};

export const TwapPriceBar = ({ price, date }: TwapPriceBarProps) => {
  const calculatedPercent = () => {
    const parsedPrice = parseFloat(price);
    let leftBarPercent = ((parsedPrice - 0.9) * 100 * 0.8) / 0.2;
    leftBarPercent = leftBarPercent < 10 ? 10 : leftBarPercent > 90 ? 90 : leftBarPercent;
    return leftBarPercent;
  };

  const leftPositioned = parseFloat(price) <= 1;

  return (
    <>
      <div>
        <div>
          <div></div>
          <hr />
          <div style={{ width: `${leftPositioned ? calculatedPercent() : 40}%` }}>
            {leftPositioned ? <span>${price}</span> : <span>Redeeming cycle started {date} ago</span>}
          </div>
          {leftPositioned ? (
            <>
              <div>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
                </svg>
              </div>
              <hr />
            </>
          ) : (
            <>
              <hr />
              <div style={{ width: `${calculatedPercent() - 40}%` }}>
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16l-4-4m0 0l4-4m-4 4h18" />
                </svg>
              </div>
            </>
          )}
          <div>{leftPositioned ? <span>Pump cycle started {date} ago</span> : <span>${price}</span>}</div>
          <hr />
          <div></div>
        </div>
      </div>
      <div>
        <div>
          <span>$0.9</span>
        </div>
        <div>
          <span>$1</span>
        </div>
        <div>
          <span>$1.1</span>
        </div>
      </div>
      <div>
        <span>
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
    <div>
      <table>
        <thead>
          <tr>
            <th>uDEBT</th>
            <th>Expiration</th>
            <th>Swap</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {coupons && coupons.uDEBT && coupons.uDEBT.length
            ? coupons.uDEBT.map((coupon, index) => <CouponRow coupon={coupon} onRedeem={onRedeem} onSwap={onSwap} key={index} />)
            : null}
        </tbody>
      </table>
    </div>
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
      <td>
        <button onClick={handleSwap}>{`${coupon.swap.amount.toLocaleString()} ${coupon.swap.unit}`}</button>
      </td>
      <td>{timeDiff > 0 ? <button onClick={onRedeem}>Redeem</button> : null}</td>
    </tr>
  );
};

export default withLoadedContext(DebtCouponContainer);
