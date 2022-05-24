import { useState, useEffect } from "react";

import { useWeb3 } from "@/lib/hooks";
import { ERC20, ERC20__factory } from "@/dollar-types";
import {
  TheUbiquityStickSale__factory,
  SimpleBond__factory,
  SimpleBond,
  TheUbiquityStickSale,
  TheUbiquityStick,
  TheUbiquityStick__factory,
} from "@/ubiquistick-types";
import { ChainlinkPriceFeed, ChainlinkPriceFeed__factory } from "@/fixtures/abi/types";
import deployedAddresses from "@/fixtures/contracts-addresses/ubiquistick.json";

import { allPools, goldenPool, pools } from "../pools";

type Addresses = {
  TheUbiquityStick: string;
  TheUbiquityStickSale: string;
  SimpleBond: string;
  chainLinkEthUsd: string;
};

const externalAddresses = { chainLinkEthUsd: "0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419" };

const castedDeployedAddress = (deployedAddresses as unknown) as { [key: string]: Addresses };

for (const key in castedDeployedAddress) {
  castedDeployedAddress[key] = { ...castedDeployedAddress[key], ...externalAddresses };
}

export const addresses = castedDeployedAddress;

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
      const chainAddresses = addresses[provider.network.chainId];
      const signer = provider.getSigner();

      const simpleBond = factories.simpleBond(chainAddresses.SimpleBond, provider).connect(signer);

      let rewardToken;
      try {
        rewardToken = await simpleBond.tokenRewards();
      } catch (error) {
        if (!rewardToken) {
          console.error(error);
          // Wait until faucet show the following logs, then it should work

          // Transferred 1000.0 UBQ from 0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd
          // USDC: 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
          throw new Error("rewardToken not found on chain. Are you on the correct network?");
        }
      }

      const contracts = {
        ubiquiStick: factories.ubiquiStick(chainAddresses.TheUbiquityStick, provider).connect(signer),
        ubiquiStickSale: factories.ubiquiStickSale(chainAddresses.TheUbiquityStickSale, provider).connect(signer),
        simpleBond,
        rewardToken: ERC20__factory.connect(rewardToken, provider).connect(signer),
        chainLink: factories.chainLink(chainAddresses.chainLinkEthUsd, provider),
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
