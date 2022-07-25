import cx from "classnames";
import { useState } from "react";

import { ensureERC20Allowance } from "@/lib/contracts-shortcuts";
import { useTransactionLogger, useWalletAddress, useWeb3Provider } from "@/lib/hooks";
import { performTransaction } from "@/lib/utils";
import { Button } from "@/ui";

import useLaunchPartyContracts from "./lib/hooks/useLaunchPartyContracts";
import usePrices from "./lib/hooks/usePrices";
import useSimpleBond from "./lib/hooks/useSimpleBond";
import useUbiquistick from "./lib/hooks/useUbiquistick";
import { goldenPool } from "./lib/pools";

import { ethers, utils } from "ethers";
import AllowanceManager from "./AllowanceManager";
import FundingPools from "./FundingPools";
import LaunchPartyHeader from "./Header";
import Liquidate from "./Liquidate";
import MultiplicationPool from "./MultiplicationPool";
import RewardsManager from "./RewardsManager";
import UbiquiStick from "./UbiquiStick";
import YourBonds from "./YourBonds";

const App = () => {
  const provider = useWeb3Provider();
  const [walletAddress] = useWalletAddress();
  const [, doTransaction, doingTransaction] = useTransactionLogger();

  const [contracts, tokensContracts, { isSaleContractOwner, isSimpleBondOwner }] = useLaunchPartyContracts();
  const { sticks, allowance, tokenMedia, refreshUbiquistickData } = useUbiquistick(contracts);
  const { rewardTokenBalance, tokensRatios, poolsData, bondsData, needsStick, refreshSimpleBondData } = useSimpleBond(contracts, tokensContracts);
  const { uarUsdPrice } = usePrices(contracts, tokensContracts, poolsData);

  const [showAdminComponents, setShowAdminComponents] = useState(false);

  // ████████╗██████╗  █████╗ ███╗   ██╗███████╗ █████╗  ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
  // ╚══██╔══╝██╔══██╗██╔══██╗████╗  ██║██╔════╝██╔══██╗██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
  //    ██║   ██████╔╝███████║██╔██╗ ██║███████╗███████║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
  //    ██║   ██╔══██╗██╔══██║██║╚██╗██║╚════██║██╔══██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
  //    ██║   ██║  ██║██║  ██║██║ ╚████║███████║██║  ██║╚██████╗   ██║   ██║╚██████╔╝██║ ╚████║███████║
  //    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

  const contractSetAllowance = async (data: { address: string; count: string; price: string }[]) => {
    if (!isConnected || !isLoaded || doingTransaction) return;

    doTransaction("Setting allowance...", async () => {
      if (data.length > 1) {
        const addresses = data.map(({ address }) => address);
        const counts = data.map(({ count }) => utils.parseUnits(count, "wei"));
        const prices = data.map(({ price }) => utils.parseEther(price));
        await performTransaction(contracts.ubiquiStickSale.batchSetAllowances(addresses, counts, prices));
      } else {
        const { address, count, price } = data[0];
        await performTransaction(contracts.ubiquiStickSale.setAllowance(address, utils.parseUnits(count, "wei"), utils.parseEther(price)));
      }
      await refreshUbiquistickData();
    });
  };

  const contractMintUbiquistick = async () => {
    if (!isConnected || !isLoaded || doingTransaction) return;

    await doTransaction("Minting Ubiquistick...", async () => {
      await performTransaction(
        provider.getSigner().sendTransaction({
          to: contracts.ubiquiStickSale.address,
          value: ethers.utils.parseEther(allowance.price.toString()),
        })
      );
      await refreshUbiquistickData();
    });
  };

  const contractSimpleBondSetReward = async ({ token, ratio }: { token: string; ratio: ethers.BigNumber }) => {
    if (!isConnected || !isLoaded || doingTransaction) return;
    doTransaction("Setting reward...", async () => {
      await performTransaction(contracts.simpleBond.setRewards(token, ratio));
      await refreshSimpleBondData();
    });
  };

  const contractDepositAndBond = async ({ token, amount }: { token: string; amount: number }) => {
    if (!isConnected || !isLoaded || doingTransaction || tokensContracts.length === 0) return;
    if (!token || !amount) return;
    const contract = tokensContracts.find((tc) => tc.address === token);
    if (!contract) return;
    doTransaction("Depositing...", async () => {
      const decimals = await contract.decimals();
      const symbol = await contract.symbol();
      const bnAmount = ethers.utils.parseUnits(amount.toString(), decimals);
      const signer = provider.getSigner();
      if (await ensureERC20Allowance(symbol, contract, bnAmount, signer, contracts.simpleBond.address, decimals)) {
        if (await performTransaction(contracts.simpleBond.bond(token, bnAmount))) {
          console.log("Deposit successful!");
          refreshSimpleBondData();
        } else {
          console.log("Deposit failed!");
        }
      } else {
        console.error("Error setting ERC20 allowance");
      }
    });
  };

  const contractClaimAll = async () => {
    if (!isConnected || !isLoaded || doingTransaction) return;
    await doTransaction("Claiming all rewards...", async () => {
      await performTransaction(contracts.simpleBond.claim());
      await refreshSimpleBondData();
    });
  };

  // ██████╗ ███████╗██████╗ ██╗██╗   ██╗███████╗██████╗
  // ██╔══██╗██╔════╝██╔══██╗██║██║   ██║██╔════╝██╔══██╗
  // ██║  ██║█████╗  ██████╔╝██║██║   ██║█████╗  ██║  ██║
  // ██║  ██║██╔══╝  ██╔══██╗██║╚██╗ ██╔╝██╔══╝  ██║  ██║
  // ██████╔╝███████╗██║  ██║██║ ╚████╔╝ ███████╗██████╔╝
  // ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝  ╚══════╝╚═════╝

  const isConnected = !!(provider && walletAddress);
  const isLoaded = !!(contracts && sticks && allowance);
  const sticksCount = sticks ? sticks.gold + sticks.black + sticks.invisible : null;
  const canUsePools = (sticksCount !== null && sticksCount > 0) || !needsStick;
  const showAdminButton = isSaleContractOwner || isSimpleBondOwner;

  return (
    <div className="relative w-full">
      <div
        className={cx("absolute top-0 left-0 right-0 bottom-0 z-40 flex flex-col items-center transition-opacity duration-500", {
          "pointer-events-none opacity-0": !showAdminComponents,
          "pointer-events-auto opacity-100": showAdminComponents,
        })}
      >
        <div className="fixed top-0 left-0 right-0 bottom-0 bg-black/50" onClick={() => setShowAdminComponents(false)}></div>
        <div className="pt-6">
          {isSaleContractOwner ? <AllowanceManager defaultAddress={walletAddress || ""} onSubmit={contractSetAllowance} /> : null}
          {isSimpleBondOwner ? <RewardsManager onSubmit={contractSimpleBondSetReward} ratios={tokensRatios} /> : null}
        </div>
      </div>

      <LaunchPartyHeader />

      {showAdminButton ? (
        <div className="-mt-8 mb-8 flex h-0 justify-center">
          <Button disabled={!showAdminButton} size="sm" onClick={() => setShowAdminComponents(true)}>
            Admin
          </Button>
        </div>
      ) : null}

      <UbiquiStick isConnected={isConnected} onBuy={contractMintUbiquistick} sticks={sticks} media={tokenMedia} allowance={allowance} />
      <FundingPools enabled={canUsePools} poolsData={poolsData} onDeposit={contractDepositAndBond} />
      <MultiplicationPool enabled={canUsePools} poolsData={poolsData} onDeposit={contractDepositAndBond} />
      <YourBonds enabled={canUsePools && !doingTransaction} bonds={bondsData} onClaim={contractClaimAll} uarUsdPrice={uarUsdPrice} />
      <Liquidate accumulated={rewardTokenBalance} uarUsdPrice={uarUsdPrice} poolAddress={goldenPool.tokenAddress} />
    </div>
  );
};

export default App;
