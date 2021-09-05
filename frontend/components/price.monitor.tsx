import { ethers, BigNumber } from "ethers";
import { useEffect, useState } from "react";
import { ADDRESS, Contracts } from "../src/contracts";
import { useConnectedContext } from "./context/connected";
import { formatEther, formatMwei } from "../utils/format";
import * as widget from "./ui/widget";

type State = null | PriceMonitorProps;
type PriceMonitorProps = {
  metaPoolAddress: string;
  daiUsdt: number;
  uadUsdc: number;
  uadDai: number;
  uadUsdt: number;
  twapAddress: string;
  uadCrv: number;
  crvUad: number;
  dollarMintCalcAddress: string;
  dollarToBeMinted: number | null;
};

const fetchPrices = async ({
  uad,
  curvePool,
  metaPool,
  twapOracle,
  dollarMintCalc,
}: Contracts): Promise<PriceMonitorProps> => {
  const [[daiIndex, usdtIndex], [uadIndex, usdcIndex]] = await Promise.all([
    curvePool.get_coin_indices(metaPool.address, ADDRESS.DAI, ADDRESS.USDT),
    curvePool.get_coin_indices(metaPool.address, uad.address, ADDRESS.USDC),
  ]);

  const metaPoolGet = async (
    i1: BigNumber,
    i2: BigNumber
  ): Promise<BigNumber> => {
    return await metaPool["get_dy_underlying(int128,int128,uint256)"](
      i1,
      i2,
      ethers.utils.parseEther("1")
    );
  };

  const [
    daiUsdt,
    uadUsdc,
    uadDai,
    uadUsdt,
    uadCrv,
    crvUad,
  ] = await Promise.all([
    metaPoolGet(daiIndex, usdtIndex),
    metaPoolGet(uadIndex, usdcIndex),
    metaPoolGet(uadIndex, daiIndex),
    metaPoolGet(uadIndex, usdtIndex),
    twapOracle.consult(uad.address),
    twapOracle.consult(ADDRESS.curve3CrvToken),
  ]);

  return {
    metaPoolAddress: metaPool.address,
    daiUsdt: +formatMwei(daiUsdt),
    uadUsdc: +formatMwei(uadUsdc),
    uadDai: +formatEther(uadDai),
    uadUsdt: +formatMwei(uadUsdt),
    twapAddress: twapOracle.address,
    uadCrv: +formatEther(uadCrv),
    crvUad: +formatEther(crvUad),
    dollarMintCalcAddress: dollarMintCalc.address,
    dollarToBeMinted: uadCrv.gt(ethers.utils.parseEther("1"))
      ? +formatEther(await dollarMintCalc.getDollarsToMint())
      : null,
  };
};

const PriceMonitorContainer = () => {
  const { contracts } = useConnectedContext();
  const [priceMonitorProps, setPriceMonitorProps] = useState<State>(null);

  useEffect(() => {
    if (contracts) {
      (async function () {
        setPriceMonitorProps(await fetchPrices(contracts));
      })();
    }
  }, [contracts]);

  return priceMonitorProps && <PriceMonitor {...priceMonitorProps} />;
};

const PriceMonitor = (props: PriceMonitorProps) => {
  return (
    <widget.Container>
      <widget.Title text="Price monitor" />
      <widget.Address title="Metapool" address={props.metaPoolAddress} />
      <widget.PriceExchange from="DAI" to="USDT" value={props.daiUsdt} />
      <widget.PriceExchange from="uAD" to="USDC" value={props.uadUsdc} />
      <widget.PriceExchange from="uAD" to="DAI" value={props.uadDai} />
      <widget.PriceExchange from="uAD" to="USDT" value={props.uadUsdt} />
      <widget.SubTitle text="Time Weighted Average" />
      <widget.Address title="TWAP Oracle" address={props.twapAddress} />
      <widget.PriceExchange from="uAD" to="3CRV" value={props.uadCrv} />
      <widget.PriceExchange from="3CRV" to="uAD" value={props.crvUad} />
      <widget.SubTitle text="Dollar Minting" />
      <widget.Address
        title="Dollar Minting Calculator"
        address={props.dollarMintCalcAddress}
      />
      <div className="text-center mt-4">
        {props.dollarToBeMinted ? (
          <div>
            {props.dollarToBeMinted}{" "}
            <span className="text-white text-opacity-75"> uAD</span> to be
            minted
          </div>
        ) : (
          "No minting needed"
        )}
      </div>
    </widget.Container>
  );
};

export default PriceMonitorContainer;
