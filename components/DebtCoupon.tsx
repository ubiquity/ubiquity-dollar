import { BigNumber, ethers } from "ethers";
import { ChangeEvent, Dispatch, memo, SetStateAction, useState } from "react";
import * as widget from "./ui/widget";
import { connectedWithUserContext, useConnectedContext } from "./context/connected";
import { Balances } from "./common/contracts-shortcuts";

type Actions = {
  onRedeem: () => void;
  onSwap: () => void;
  onBurn: () => void;
};

export const DebtCouponContainer = () => {
  const { balances, twapPrice, setTwapPrice } = useConnectedContext();
  const actions: Actions = {
    onRedeem: () => {
      console.log("onRedeem");
    },
    onSwap: () => {
      console.log("onSwap");
    },
    onBurn: () => {
      console.log("onBurn");
    },
  };

  return (
    <widget.Container className="max-w-screen-md !mx-auto relative">
      <widget.Title text="Debt Coupon" />
      {balances && <DebtCoupon twapPrice={twapPrice} setTwapPrice={setTwapPrice} balances={balances} actions={actions} />}
    </widget.Container>
  );
};

type DebtCouponProps = {
  twapPrice: BigNumber | null;
  setTwapPrice: Dispatch<SetStateAction<BigNumber | null>>;
  balances: Balances;
  actions: Actions;
};

const DebtCoupon = memo(({ twapPrice, setTwapPrice, actions }: DebtCouponProps) => {
  const [cycleStartDate, setCycleStartDate] = useState("3 weeks ago");
  const [selectedCurrency, selectCurrency] = useState("uar");

  const getTwapPrice = () => {
    if (twapPrice) {
      return parseFloat(ethers.utils.formatEther(twapPrice)).toFixed(2);
    }
    return 0;
  };
  const [currentTwapPrice, setCurrentTwapPrice] = useState(getTwapPrice());
  const handleTabSelect = (tab: string) => {
    selectCurrency(tab);
  };

  const handleSlide = (e: ChangeEvent<HTMLInputElement>) => {
    setCurrentTwapPrice(e.target.value);
  };
  return (
    <>
      <div className="w-full flex h-8 rounded-md border border-white/10 border-solid relative">
        <div className="w-full flex">
          <div className="w-5/12 flex justify-end border-0 border-r border-white/10 border-solid">
            <span className="pr-2 self-center">${currentTwapPrice}</span>
          </div>
          <div className="w-7/12 flex justify-center">
            <span className="pr-2 self-center">Pump cycle started {cycleStartDate}</span>
          </div>
        </div>
        <div className="w-full h-full absolute">
          <input type="range" min={0} max={2} step={0.01} onChange={handleSlide} className="m-0 w-full h-full p-0 bg-transparent" value={currentTwapPrice} />
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
                <td className="pl-4 text-left">10% / week</td>
              </tr>
              <tr>
                <td className="pr-4 text-right">Current reward %</td>
                <td className="pl-4 text-left">10%</td>
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
                <td className="pl-4 text-left">0%</td>
              </tr>
              <tr>
                <td className="pr-4 text-right">Current reward %</td>
                <td className="pl-4 text-left">15%</td>
              </tr>
              <tr>
                <td className="pr-4 text-right">Expires?</td>
                <td className="pl-4 text-left">After 30 days</td>
              </tr>
            </tbody>
          </table>
          <div>
            <span>Convertible to fungible</span>
          </div>
          <div>
            <span>Can be redeemed for UBQ at 25% rate</span>
          </div>
          <a href="">Learn more</a>
        </div>
      </div>
      <div className="inline-flex my-8">
        <span className="self-center">uAD</span>
        <input className="self-center" type="text" />
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
        <button onClick={actions.onBurn} className="self-center">
          Burn
        </button>
      </div>
      <div className="my-4">
        <span>Price will increase by an estimated of +$0.05</span>
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
            <div className="pt-1 pb-2">233k</div>
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
              <div className="pt-1 pb-2">10,000</div>
            </div>
            <div className="w-1/3">
              <div className="pt-2 pb-1">uAR</div>
              <div className="pt-1 pb-2">30,000</div>
            </div>
            <div className="w-1/3">
              <div className="pt-2 pb-1">uDEBT</div>
              <div className="pt-1 pb-2">5,000</div>
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
});

export default connectedWithUserContext(DebtCouponContainer);
