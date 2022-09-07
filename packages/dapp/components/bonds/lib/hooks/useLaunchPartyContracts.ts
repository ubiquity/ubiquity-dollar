import { useEffect, useState } from "react";

import { allPools } from "../pools";
import useDeployedAddress from "@/components/lib/hooks/useDeployedAddress";
import useWeb3 from "@/components/lib/hooks/useWeb3";
import { getChainlinkPriceFeedContract, getERC20Contract, getSimpleBondContract, getUbiquitystickContract, getUbiquityStickSaleContract } from "@/components/utils/contracts";
import { Contract } from "ethers";

const ChainLinkEthUsdAddress = "0x5f4ec3df9cbd43714fe2740f5e3616155c5b8419";

export type Contracts = {
  ubiquiStick: Contract;
  ubiquiStickSale: Contract;
  simpleBond: Contract;
  rewardToken: Contract;
  chainLink: Contract;
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

      const simpleBond = getSimpleBondContract(SimpleBondAddress, provider);
      const rewardToken = await simpleBond.tokenRewards();
      const contracts = {
        ubiquiStick: getUbiquitystickContract(TheUbiquityStickAddress, provider),
        ubiquiStickSale: getUbiquityStickSaleContract(TheUbiquityStickSaleAddress, provider),
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
