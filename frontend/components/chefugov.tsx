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
      <div className="column-wrap">
        <div className="row">
          <button onClick={handleBalance}>Get UBQ Balance</button>
          <p className="value">
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
