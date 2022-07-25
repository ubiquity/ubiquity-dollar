import { BigNumber, ethers } from "ethers";
import { useEffect, useState } from "react";

import NAMED_ACCOUNTS from "@/fixtures/named-accounts.json";
import { formatEther, formatMwei } from "@/lib/format";
import { useManagerManaged, useNamedContracts } from "@/lib/hooks";
import { Container, SubTitle, Title } from "@/ui";

import { Address, PriceExchange } from "./ui";

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

type ManagedContracts = NonNullable<Awaited<ReturnType<typeof useManagerManaged>>>;
type NamedContracts = NonNullable<Awaited<ReturnType<typeof useNamedContracts>>>;

const fetchPrices = async ({ uad, metaPool, twapOracle, dollarMintCalc }: ManagedContracts, { curvePool }: NamedContracts): Promise<PriceMonitorProps> => {
  const [[daiIndex, usdtIndex], [uadIndex, usdcIndex]] = await Promise.all([
    curvePool.get_coin_indices(metaPool.address, NAMED_ACCOUNTS.DAI, NAMED_ACCOUNTS.USDT),
    curvePool.get_coin_indices(metaPool.address, uad.address, NAMED_ACCOUNTS.USDC),
  ]);

  const metaPoolGet = async (i1: BigNumber, i2: BigNumber): Promise<BigNumber> => {
    return await metaPool["get_dy_underlying(int128,int128,uint256)"](i1, i2, ethers.utils.parseEther("1"));
  };

  const [daiUsdt, uadUsdc, uadDai, uadUsdt, uadCrv, crvUad] = await Promise.all([
    metaPoolGet(daiIndex, usdtIndex),
    metaPoolGet(uadIndex, usdcIndex),
    metaPoolGet(uadIndex, daiIndex),
    metaPoolGet(uadIndex, usdtIndex),
    twapOracle.consult(uad.address),
    twapOracle.consult(NAMED_ACCOUNTS.curve3CrvToken),
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
    dollarToBeMinted: uadCrv.gt(ethers.utils.parseEther("1")) ? +formatEther(await dollarMintCalc.getDollarsToMint()) : null,
  };
};

const PriceMonitorContainer = () => {
  const managedContracts = useManagerManaged();
  const namedContracts = useNamedContracts();
  const [priceMonitorProps, setPriceMonitorProps] = useState<State>(null);

  useEffect(() => {
    if (managedContracts && namedContracts) {
      (async function () {
        setPriceMonitorProps(await fetchPrices(managedContracts, namedContracts));
      })();
    }
  }, [managedContracts, namedContracts]);

  return priceMonitorProps && <PriceMonitor {...priceMonitorProps} />;
};

const PriceMonitor = (props: PriceMonitorProps) => {
  return (
    <Container>
      <Title text="Price monitor" />
      <Address title="Metapool" address={props.metaPoolAddress} />
      <PriceExchange from="DAI" to="USDT" value={props.daiUsdt} />
      <PriceExchange from="uAD" to="USDC" value={props.uadUsdc} />
      <PriceExchange from="uAD" to="DAI" value={props.uadDai} />
      <PriceExchange from="uAD" to="USDT" value={props.uadUsdt} />
      <SubTitle text="Time Weighted Average" />
      <Address title="TWAP Oracle" address={props.twapAddress} />
      <PriceExchange from="uAD" to="3CRV" value={props.uadCrv} />
      <PriceExchange from="3CRV" to="uAD" value={props.crvUad} />
      <SubTitle text="Dollar Minting" />
      <Address title="Dollar Minting Calculator" address={props.dollarMintCalcAddress} />
      <div className="mt-4 text-center">
        {props.dollarToBeMinted ? (
          <div>
            {props.dollarToBeMinted} <span className="text-white text-opacity-75"> uAD</span> to be minted
          </div>
        ) : (
          "No minting needed"
        )}
      </div>
    </Container>
  );
};

export default PriceMonitorContainer;
