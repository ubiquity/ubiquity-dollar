import { ethers } from "ethers";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useEffect, useState } from "react";
import {
  MasterChef__factory,
  UbiquityAlgorithmicDollarManager,
  UbiquityGovernance__factory,
} from "../src/types";

async function _getUBQBalance(
  account: string,
  manager: UbiquityAlgorithmicDollarManager | undefined,
  provider: ethers.providers.Web3Provider | undefined,
  balances: Balances | undefined,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>
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
  manager: UbiquityAlgorithmicDollarManager | undefined,
  provider: ethers.providers.Web3Provider | undefined,
  reward: string | undefined,
  setRewards: Dispatch<SetStateAction<string | undefined>>
): Promise<void> {
  const SIGNER = provider?.getSigner();

  if (SIGNER && manager && account) {
    const masterChef = MasterChef__factory.connect(
      await manager.masterChefAddress(),
      SIGNER
    );
    const balance = await masterChef?.pendingUGOV(account);
    if (balance) {
      if (!(balance.toString() === reward)) {
        setRewards(ethers.utils.formatEther(balance));
      }
    }
  }
}

async function _claimReward(
  account: string,
  manager: UbiquityAlgorithmicDollarManager | undefined,
  provider: ethers.providers.Web3Provider | undefined,
  rewards: string | undefined,
  setRewards: Dispatch<SetStateAction<string | undefined>>,
  balances: Balances | undefined,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>
): Promise<void> {
  const SIGNER = provider?.getSigner();

  if (SIGNER && manager && account) {
    const masterChef = MasterChef__factory.connect(
      await manager.masterChefAddress(),
      SIGNER
    );

    await (await masterChef?.getRewards()).wait();
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
    _getUBQBalance(
      account ? account.address : "",
      manager,
      provider,
      balances,
      setBalances
    );
    _getUBQReward(
      account ? account.address : "",
      manager,
      provider,
      rewards,
      setRewards
    );
  }, [balances?.ubq]);

  const [rewards, setRewards] = useState<string>();

  const handleBalance = async () => {
    _getUBQBalance(
      account ? account.address : "",
      manager,
      provider,
      balances,
      setBalances
    );
  };
  const handleReward = async () => {
    _getUBQReward(
      account ? account.address : "",
      manager,
      provider,
      rewards,
      setRewards
    );
  };

  if (!account) {
    return null;
  }

  const handleClaim = async () => {
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
      <div>
        {/* <button onClick={handleReward}>Get UBQ Rewards</button> */}
        <button onClick={handleClaim}>Claim Rewards</button>
        <p>Pending Rewards: {rewards} UBQ</p>
      </div>
      <div>
        <div>
          {/* <button onClick={handleBalance}>Get UBQ Balance</button> */}
          <p>
            {balances ? ethers.utils.formatEther(balances.ubq) : "0.0"} UBQ
          </p>{" "}
        </div>
        <div>
          <a href="  https://app.sushi.com/add/0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0/0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6">
            Get UBQ on sushiswap.
          </a>
        </div>
      </div>
    </>
  );
};

export default ChefUgov;
