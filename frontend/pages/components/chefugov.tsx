import { ethers, BigNumber } from "ethers";

import { UbiquityAlgorithmicDollar__factory } from "../../src/types/factories/UbiquityAlgorithmicDollar__factory";
import { IMetaPool__factory } from "../../src/types/factories/IMetaPool__factory";
import { Bonding__factory } from "../../src/types/factories/Bonding__factory";
import { BondingShare__factory } from "../../src/types/factories/BondingShare__factory";
import { UbiquityAlgorithmicDollarManager__factory } from "../../src/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { UbiquityAlgorithmicDollarManager } from "../../src/types/UbiquityAlgorithmicDollarManager";
import { ERC20__factory } from "../../src/types/factories/ERC20__factory";

import { ADDRESS } from "../index";
import { useConnectedContext } from "../context/connected";
import { useEffect, useState } from "react";
import { Bonding, BondingShare, IMetaPool } from "../../src/types";
import { Account } from "../utils/types";

const ChefUgov = () => {
  const { account, bonding, masterChef, uGov } = useConnectedContext();

  const [ugovBalance, setUgovBalance] = useState<string>();
  const [rewards, setRewards] = useState<string>();
  if (!account) {
    return null;
  }
  const handleBalance = async () => {
    if (uGov) {
      console.log("888", uGov.address, account.address);
      const symbol = await uGov.symbol();
      console.log("symbol", symbol);
      const balance = await uGov?.balanceOf(account.address);
      console.log("999");
      if (balance) {
        setUgovBalance(ethers.utils.formatEther(balance));
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
  return (
    <>
      <button onClick={handleReward}>Get uGov Rewards</button>
      <button onClick={handleClaim}>Claim Rewards</button>
      <p>uGov Rewards Balance: {rewards}</p>
      <button onClick={handleBalance}>Get uGov Balance</button>
      <p>uGov Balance: {ugovBalance}</p>
    </>
  );
};

export default ChefUgov;
