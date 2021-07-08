import { ethers, BigNumber } from "ethers";
import { useEffect, useState } from "react";
import { ADDRESS, Contracts } from "../src/contracts";
import { useConnectedContext } from "./context/connected";
import { formatEther, formatMwei } from "../utils/format";

type State = null | MetapoolMonitorProps;
type MetapoolMonitorProps = {
  metaPoolAddress: string;
  uadBalance: number;
  crvBalance: number;
  rates: [number, number];
  underBalances: [number, number, number, number];
  dai2usdtIndices: [number, number];
  uad2usdcIndices: [number, number];
  decimals: {
    uad: number;
    dai: number;
    usdc: number;
    usdt: number;
  };
  prices: {
    dai2usdt: number;
    uad2usdc: number;
    uad2dai: number;
    uad2usdt: number;
  };
};

const MetapoolMonitorContainer = () => {
  const { contracts } = useConnectedContext();
  const [metaPoolMonitorProps, setMetapoolMonitorProps] = useState<State>(null);

  useEffect(() => {
    if (contracts) {
      (async function () {
        const metaPoolGet = async (
          i1: BigNumber,
          i2: BigNumber
        ): Promise<BigNumber> => {
          return await contracts.metaPool[
            "get_dy_underlying(int128,int128,uint256)"
          ](i1, i2, ethers.utils.parseEther("1"));
        };

        const [
          uadBalance,
          crvBalance,
          rates,
          underBalances,
          dai2usdtIndices,
          uad2usdcIndices,
          decimals,
        ] = await Promise.all([
          contracts.metaPool.balances(0),
          contracts.metaPool.balances(1),
          contracts.curvePool.get_rates(contracts.metaPool.address),
          contracts.curvePool.get_underlying_balances(
            contracts.metaPool.address
          ),
          contracts.curvePool.get_coin_indices(
            contracts.metaPool.address,
            ADDRESS.DAI,
            ADDRESS.USDT
          ),
          contracts.curvePool.get_coin_indices(
            contracts.metaPool.address,
            contracts.uad.address,
            ADDRESS.USDC
          ),
          contracts.curvePool.get_underlying_decimals(
            contracts.metaPool.address
          ),
        ]);

        const [dai2usdt, uad2usdc, uad2dai, uad2usdt] = await Promise.all([
          metaPoolGet(dai2usdtIndices[0], dai2usdtIndices[1]),
          metaPoolGet(uad2usdcIndices[0], uad2usdcIndices[1]),
          metaPoolGet(uad2usdcIndices[0], dai2usdtIndices[0]),
          metaPoolGet(uad2usdcIndices[0], dai2usdtIndices[1]),
        ]);

        setMetapoolMonitorProps({
          metaPoolAddress: contracts.metaPool.address,
          uadBalance: +formatEther(uadBalance),
          crvBalance: +formatEther(crvBalance),
          rates: [+formatEther(rates[0]), +formatEther(rates[1])],
          underBalances: [
            +formatEther(underBalances[0]),
            +formatEther(underBalances[1]),
            +formatMwei(underBalances[2]),
            +formatMwei(underBalances[3]),
          ],
          dai2usdtIndices: dai2usdtIndices.map((v) => +v.toString()) as [
            number,
            number
          ],
          uad2usdcIndices: uad2usdcIndices.map((v) => +v.toString()) as [
            number,
            number
          ],
          decimals: {
            uad: +decimals[0].toString(),
            dai: +decimals[1].toString(),
            usdc: +decimals[2].toString(),
            usdt: +decimals[3].toString(),
          },
          prices: {
            dai2usdt: +formatMwei(dai2usdt),
            uad2usdc: +formatMwei(uad2usdc),
            uad2dai: +formatEther(uad2dai),
            uad2usdt: +formatMwei(uad2usdt),
          },
        });
      })();
    }
  }, [contracts]);

  return metaPoolMonitorProps && <MetapoolMonitor {...metaPoolMonitorProps} />;
};

const MetapoolMonitor = (props: MetapoolMonitorProps) => {
  return (
    <div
      border="1 solid white/10"
      text="white/50"
      className="!block !mx-0 !py-8 px-4 tracking-wide bg-blur rounded-md"
    >
      <div className="text-center uppercase mb-2 tracking-widest text-sm">
        Metapool monitor
      </div>
      <div className="text-center break-words text-xs mb-8">
        {props.metaPoolAddress}
      </div>
      <div className="mb-8">
        <div className="flex">
          <div className="text-white/75 w-1/2">uAD Balance</div>
          <div>{props.uadBalance}</div>
        </div>
        <div className="flex">
          <div className="text-white/75 w-1/2">CRV Balance</div>
          <div>{props.crvBalance}</div>
        </div>
      </div>
      <div className="mb-8">
        <div className="uppercase tracking-widest text-sm text-white/75 mb-2">
          Rates
        </div>
        <div className="flex">
          <div className="w-1/2">{props.rates[0]}</div>
          <div className="w-1/2">{props.rates[1]}</div>
        </div>
      </div>
      <div className="mb-8">
        <div className="uppercase tracking-widest text-sm text-white/75 mb-2">
          Underlying Balances
        </div>
        <div className="flex flex-wrap">
          <div className="w-1/2">{props.underBalances[0]}</div>
          <div className="w-1/2">{props.underBalances[1]}</div>
          <div className="w-1/2">{props.underBalances[2]}</div>
          <div className="w-1/2">{props.underBalances[3]}</div>
        </div>
      </div>
      <div className="mb-8">
        <div className="uppercase tracking-widest text-sm text-white/75 mb-2">
          Indices
        </div>
        <div className="flex flex-wrap">
          <div className="w-1/2">
            <span className="text-white/75">DAI</span>{" "}
            {props.dai2usdtIndices[0]}
          </div>
          <div className="w-1/2">
            <span className="text-white/75">USDT</span>{" "}
            {props.dai2usdtIndices[1]}
          </div>
          <div className="w-1/2">
            <span className="text-white/75">uAD</span>{" "}
            {props.uad2usdcIndices[0]}
          </div>
          <div className="w-1/2">
            <span className="text-white/75">USDC</span>{" "}
            {props.uad2usdcIndices[1]}
          </div>
        </div>
      </div>
      <div className="mb-8">
        <div className="uppercase tracking-widest text-sm text-white/75 mb-2">
          Decimals
        </div>
        <div className="flex flex-wrap">
          <div className="w-1/2">
            <span className="text-white/75">uAD</span> {props.decimals.uad}
          </div>
          <div className="w-1/2">
            <span className="text-white/75">DAI</span> {props.decimals.dai}
          </div>
          <div className="w-1/2">
            <span className="text-white/75">USDC</span> {props.decimals.usdc}
          </div>
          <div className="w-1/2">
            <span className="text-white/75">USDT</span> {props.decimals.usdt}
          </div>
        </div>
      </div>
      <div className="mb-8">
        <div className="uppercase tracking-widest text-sm text-white/75 mb-2">
          Prices
        </div>
        <div className="">
          {priceInfoView("DAI", "USDT", props.prices.dai2usdt.toString())}
          {priceInfoView("uAD", "USDC", props.prices.uad2usdc.toString())}
          {priceInfoView("uAD", "DAI", props.prices.uad2dai.toString())}
          {priceInfoView("uAD", "USDT", props.prices.uad2usdt.toString())}
        </div>
      </div>
    </div>
  );
};

const priceInfoView = (from: string, to: string, value: string) => (
  <div className="flex">
    <span className="w-1/2 text-right">
      1 <span className="text-white text-opacity-75">{from}</span>
    </span>
    <span className="w-8 -mt-1 text-center">⇄</span>
    <span className="w-1/2 flex-grow text-left">
      {value.toString()}{" "}
      <span className="text-white text-opacity-75">{to}</span>
    </span>
  </div>
);

export default MetapoolMonitorContainer;
