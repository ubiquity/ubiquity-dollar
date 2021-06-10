import { ethers } from "ethers";
import { useConnectedContext } from "./context/connected";
import { useState } from "react";

const ChefUgov = () => {
  const {
    account,
    masterChef,
    uGov,
    balances,
    setBalances,
  } = useConnectedContext();

  const [rewards, setRewards] = useState<string>();
  if (!account) {
    return null;
  }
  const handleBalance = async () => {
    if (uGov) {
      const rawBalance = await uGov?.balanceOf(account.address);
      if (balances) {
        balances.ubq = rawBalance;
        setBalances(balances);
      }
    }
  };

  const handleReward = async () => {
    if (masterChef) {
      const balance = await masterChef?.pendingUGOV(account.address);
      if (balance) {
        setRewards(ethers.utils.formatEther(balance));
      }
    }
  };
  const handleClaim = async () => {
    if (masterChef) {
      await (await masterChef?.getRewards()).wait();
      await handleReward();
      await handleBalance();
    }
  };
  handleReward();
  handleBalance();
  return (
    <>
      <div className="row">
        <button onClick={handleReward}>Get UBQ Rewards</button>
        <button onClick={handleClaim}>Claim Rewards</button>
        <p className="value">Pending Rewards: {rewards} UBQ</p>
      </div>
      <div className="row">
        <button onClick={handleBalance}>Get UBQ Balance</button>
        <p className="value">
          {balances ? ethers.utils.formatEther(balances.ubq) : "0.0"} UBQ
        </p>
      </div>
    </>
  );
};

export default ChefUgov;
