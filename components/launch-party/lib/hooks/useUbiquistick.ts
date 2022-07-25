import { useManagerManaged, useWeb3 } from "@/lib/hooks";
import { useEffect, useState } from "react";
import { Contracts } from "./useLaunchPartyContracts";

export type OwnedSticks = {
  black: number;
  gold: number;
  invisible: number;
};

export type TokenMedia = {
  black?: TokenData;
  gold?: TokenData;
  invisible?: TokenData;
};

export type TokenData = {
  name: string;
  animation_url: string;
  image: string;
  type: "black" | "gold" | "invisible";
};

export type SticksAllowance = {
  count: number;
  price: number;
};

const useUbiquistick = (contracts: Contracts | null) => {
  const [{ provider, walletAddress }] = useWeb3();
  const ubqContracts = useManagerManaged();

  const [sticks, setSticks] = useState<OwnedSticks | null>(null);
  const [allowance, setAllowance] = useState<SticksAllowance | null>(null);
  const [tokenMedia, setTokensMedia] = useState<TokenMedia>({});

  async function refreshUbiquistickData() {
    if (provider && walletAddress && contracts && ubqContracts) {
      const newSticks: OwnedSticks = { black: 0, gold: 0, invisible: 0 };
      const sticksAmount = (await contracts.ubiquiStick.balanceOf(walletAddress)).toNumber();
      const newTokenMedia: TokenMedia = {};

      await Promise.all(
        new Array(sticksAmount).fill(0).map(async (_, i) => {
          const id = (await contracts.ubiquiStick.tokenOfOwnerByIndex(walletAddress, i)).toNumber();
          const uri = await contracts.ubiquiStick.tokenURI(id);
          const data: TokenData = await fetch(uri).then((res) => res.json());
          newTokenMedia[data.type] = data;
          switch (data.type) {
            case "gold":
              newSticks.gold++;
              break;
            case "invisible":
              newSticks.invisible++;
              break;
            default:
              newSticks.black++;
          }
        })
      );

      const allowance = await contracts.ubiquiStickSale.allowance(walletAddress);

      setSticks(newSticks);
      setTokensMedia(newTokenMedia);

      setAllowance({ count: +allowance.count.toString(), price: +allowance.price.toString() / 1e18 });
    }
  }

  useEffect(() => {
    refreshUbiquistickData();
  }, [provider, walletAddress, contracts, ubqContracts]);

  return {
    sticks,
    allowance,
    tokenMedia,
    refreshUbiquistickData,
  };
};

export default useUbiquistick;
