import { useEffect, useState } from "react";

import { ERC20, ERC20__factory } from "@/dollar-types";
import { ChainlinkPriceFeed, ChainlinkPriceFeed__factory } from "@/fixtures/abi/types";
import { useDeployedAddress, useWeb3 } from "@/lib/hooks";
import {
  SimpleBond,
  SimpleBond__factory,
  TheUbiquityStick,
  TheUbiquityStickSale,
  TheUbiquityStickSale__factory,
  TheUbiquityStick__factory,
} from "@/ubiquistick-types";

import { allPools } from "../pools";

const ChainLinkEthUsdAddress = "0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419";

export type Contracts = {
  ubiquiStick: TheUbiquityStick;
  ubiquiStickSale: TheUbiquityStickSale;
  simpleBond: SimpleBond;
  rewardToken: ERC20;
  chainLink: ChainlinkPriceFeed;
};

export const factories = {
  ubiquiStick: TheUbiquityStick__factory.connect,
  ubiquiStickSale: TheUbiquityStickSale__factory.connect,
  simpleBond: SimpleBond__factory.connect,
  chainLink: ChainlinkPriceFeed__factory.connect,
};

const useLaunchPartyContracts = (): [Contracts | null, ERC20[], { isSaleContractOwner: boolean; isSimpleBondOwner: boolean }] => {
  const [TheUbiquityStickAddress, TheUbiquityStickSaleAddress, SimpleBondAddress] = useDeployedAddress(
    "TheUbiquityStick",
    "TheUbiquityStickSale",
    "SimpleBond"
  );
  const [{ provider, walletAddress }] = useWeb3();
  const [contracts, setContracts] = useState<Contracts | null>(null);
  const [tokensContracts, setTokensContracts] = useState<ERC20[]>([]);
  const [isSaleContractOwner, setIsSaleContractOwner] = useState<boolean>(false);
  const [isSimpleBondOwner, setIsSimpleBondOwner] = useState<boolean>(false);

  useEffect(() => {
    if (!provider || !walletAddress || !provider.network) {
      return;
    }

    (async () => {
      const signer = provider.getSigner();

      const simpleBond = factories.simpleBond(SimpleBondAddress, provider).connect(signer);

      const rewardToken = await simpleBond.tokenRewards();
      const contracts = {
        ubiquiStick: factories.ubiquiStick(TheUbiquityStickAddress, provider).connect(signer),
        ubiquiStickSale: factories.ubiquiStickSale(TheUbiquityStickSaleAddress, provider).connect(signer),
        simpleBond,
        rewardToken: ERC20__factory.connect(rewardToken, provider).connect(signer),
        chainLink: factories.chainLink(ChainLinkEthUsdAddress, provider),
      };

      setContracts(contracts);
      setTokensContracts(allPools.map((pool) => ERC20__factory.connect(pool.tokenAddress, provider)));

      setIsSaleContractOwner((await contracts.ubiquiStickSale.owner()).toLowerCase() === walletAddress.toLowerCase());
      setIsSimpleBondOwner((await contracts.simpleBond.owner()).toLowerCase() === walletAddress.toLowerCase());
    })();
  }, [provider, walletAddress, provider?.network]);

  return [contracts, tokensContracts, { isSaleContractOwner, isSimpleBondOwner }];
};

export default useLaunchPartyContracts;
