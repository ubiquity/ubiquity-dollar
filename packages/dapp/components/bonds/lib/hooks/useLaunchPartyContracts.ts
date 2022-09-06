import { useEffect, useState } from "react";

import {
  SimpleBond__factory,
  TheUbiquityStickSale__factory,
  TheUbiquityStick__factory,
} from "@ubiquity/ubiquistick/types";

import { allPools } from "../pools";
import useDeployedAddress from "@/components/lib/hooks/useDeployedAddress";
import useWeb3 from "@/components/lib/hooks/useWeb3";
import { getChainlinkPriceFeedContract, getERC20Contract } from "@/components/utils/contracts";
import { Contract } from "ethers";

const ChainLinkEthUsdAddress = "0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419";

export type Contracts = {
  ubiquiStick: Contract;
  ubiquiStickSale: Contract;
  simpleBond: Contract;
  rewardToken: Contract;
  chainLink: Contract;
};

export const factories = {
  ubiquiStick: TheUbiquityStick__factory.connect,
  ubiquiStickSale: TheUbiquityStickSale__factory.connect,
  simpleBond: SimpleBond__factory.connect,
};

const useLaunchPartyContracts = (): [Contracts | null, Contract[], { isSaleContractOwner: boolean; isSimpleBondOwner: boolean }] => {
  const [TheUbiquityStickAddress, TheUbiquityStickSaleAddress, SimpleBondAddress] = useDeployedAddress(
    "TheUbiquityStick",
    "TheUbiquityStickSale",
    "SimpleBond"
  );
  const [{ provider, walletAddress }] = useWeb3();
  const [contracts, setContracts] = useState<Contracts | null>(null);
  const [tokensContracts, setTokensContracts] = useState<Contract[]>([]);
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
        rewardToken: getERC20Contract(rewardToken, provider),
        chainLink: getChainlinkPriceFeedContract(ChainLinkEthUsdAddress, provider),
      };

      setContracts(contracts);
      setTokensContracts(allPools.map((pool) => getERC20Contract(pool.tokenAddress, provider)));

      setIsSaleContractOwner((await contracts.ubiquiStickSale.owner()).toLowerCase() === walletAddress.toLowerCase());
      setIsSimpleBondOwner((await contracts.simpleBond.owner()).toLowerCase() === walletAddress.toLowerCase());
    })();
  }, [provider, walletAddress, provider?.network]);

  return [contracts, tokensContracts, { isSaleContractOwner, isSimpleBondOwner }];
};

export default useLaunchPartyContracts;
