import { ethers } from "ethers";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useEffect, useState } from "react";
import {
  BondingShareV2__factory,
  MasterChefV2__factory,
  UbiquityAlgorithmicDollarManager,
  UbiquityGovernance__factory,
} from "../src/types";

async function _getUBQBalance(
  account: string,
  manager: UbiquityAlgorithmicDollarManager | null,
  provider: ethers.providers.Web3Provider | null,
  balances: Balances | null,
  setBalances: Dispatch<SetStateAction<Balances | null>>
): Promise<void> {
  const SIGNER = provider?.getSigner();
  if (SIGNER && manager) {
    const uGov = UbiquityGovernance__factory.connect(
      await manager.governanceTokenAddress(),
      SIGNER
    );
    const rawBalance = await uGov?.balanceOf(account);
    if (balances) {
      if (!balances.ubq.eq(rawBalance))
        setBalances({ ...balances, ubq: rawBalance });
    }
  }
}

async function _getUBQReward(
  account: string,
  manager: UbiquityAlgorithmicDollarManager | null,
  provider: ethers.providers.Web3Provider | null,
  reward: string | undefined,
  setRewards: Dispatch<SetStateAction<string | undefined>>
): Promise<void> {
  const SIGNER = provider?.getSigner();

  if (SIGNER && manager && account) {
    const masterChef = MasterChefV2__factory.connect(
      await manager.masterChefAddress(),
      SIGNER
    );
    const bondingShareAdr = await manager.bondingShareAddress();
    const bondingShare = BondingShareV2__factory.connect(
      bondingShareAdr,
      SIGNER
    );
    const bondingShareIds = await bondingShare.holderTokens(account);
    // TODO there can be several Ids so we should be able to select one

    if (bondingShareIds.length) {
      const balance = await masterChef?.pendingUGOV(bondingShareIds[0]);
      if (balance) {
        if (!(balance.toString() === reward)) {
          setRewards(ethers.utils.formatEther(balance));
        }
      }
    } else {
      setRewards(ethers.BigNumber.from(0).toString());
    }
  }
}

async function _claimReward(
  account: string,
  manager: UbiquityAlgorithmicDollarManager | null,
  provider: ethers.providers.Web3Provider | null,
  rewards: string | undefined,
  setRewards: Dispatch<SetStateAction<string | undefined>>,
  balances: Balances | null,
  setBalances: Dispatch<SetStateAction<Balances | null>>
): Promise<void> {
  const SIGNER = provider?.getSigner();

  if (SIGNER && manager && account) {
    const masterChef = MasterChefV2__factory.connect(
      await manager.masterChefAddress(),
      SIGNER
    );
    const bondingShareAdr = await manager.bondingShareAddress();
    const bondingShare = BondingShareV2__factory.connect(
      bondingShareAdr,
      SIGNER
    );
    const bondingShareIds = await bondingShare.holderTokens(account);
    // TODO there can be several Ids so we should be able to select one
    if (bondingShareIds.length) {
      await (await masterChef?.getRewards(bondingShareIds[0])).wait();
    }
    await _getUBQReward(account, manager, provider, rewards, setRewards);
    await _getUBQBalance(account, manager, provider, balances, setBalances);
  }
}

const ChefUgov = () => {
  const {
    account,
    manager,
    provider,
    balances,
    setBalances,
  } = useConnectedContext();

  useEffect(() => {
    handleBalance();
    handleReward();
  }, [balances?.ubq]);

  const [rewards, setRewards] = useState<string>();

  const handleBalance = () => {
    _getUBQBalance(
      account ? account.address : "",
      manager,
      provider,
      balances,
      setBalances
    );
  };

  const handleReward = () => {
    console.log(`handling reward`);
    _getUBQReward(
      account ? account.address : "",
      manager,
      provider,
      rewards,
      setRewards
    );
  };

  useEffect(() => {
    const intervalId = setInterval(handleReward, 8e4);
    return () => clearInterval(intervalId);
  }, []);

  if (!account) {
    return null;
  }

  const handleClaim = () => {
    _claimReward(
      account ? account.address : "",
      manager,
      provider,
      rewards,
      setRewards,
      balances,
      setBalances
    );
  };

  return (
    <>
      <div id="chefugov">
        <p>
          <span>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 91.57 104.19">
              <path d="M43.28.67 2.5 24.22A5 5 0 0 0 0 28.55v47.09A5 5 0 0 0 2.5 80l40.78 23.55a5 5 0 0 0 5 0L89.07 80a5 5 0 0 0 2.5-4.33V28.55a5 5 0 0 0-2.5-4.33L48.28.67a5 5 0 0 0-5 0zm36.31 25a2 2 0 0 1 0 3.46l-6 3.48c-2.72 1.57-4.11 4.09-5.34 6.3-.18.33-.36.66-.55 1-3 5.24-4.4 10.74-5.64 15.6C59.71 64.76 58 70.1 50.19 72.09a17.76 17.76 0 0 1-8.81 0c-7.81-2-9.53-7.33-11.89-16.59-1.24-4.86-2.64-10.36-5.65-15.6l-.54-1c-1.23-2.21-2.62-4.73-5.34-6.3l-6-3.47a2 2 0 0 1 0-3.47L43.28 7.6a5 5 0 0 1 5 0zM43.28 96.59 8.5 76.51A5 5 0 0 1 6 72.18v-36.1a2 2 0 0 1 3-1.73l6 3.46c1.29.74 2.13 2.25 3.09 4l.6 1c2.59 4.54 3.84 9.41 5 14.11 2.25 8.84 4.58 18 16.25 20.93a23.85 23.85 0 0 0 11.71 0C63.3 75 65.63 65.82 67.89 57c1.2-4.7 2.44-9.57 5-14.1l.59-1.06c1-1.76 1.81-3.27 3.1-4l5.94-3.45a2 2 0 0 1 3 1.73v36.1a5 5 0 0 1-2.5 4.33L48.28 96.59a5 5 0 0 1-5 0z" />
            </svg>
          </span>
          <span>{rewards}</span>
        </p>
        <button id="claimer" onClick={handleClaim}>
          <span>Claim Pending Ubiquity Rewards</span>
        </button>
      </div>
    </>
  );
};

export default ChefUgov;
