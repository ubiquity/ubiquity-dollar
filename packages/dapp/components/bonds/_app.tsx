import { useState } from "react";

import { ensureERC20Allowance } from "@/lib/contracts-shortcuts";
import { performTransaction } from "@/lib/utils";

import useLaunchPartyContracts from "./lib/hooks/use-launch-party-contracts";
import usePrices from "./lib/hooks/use-prices";
import useSimpleBond from "./lib/hooks/use-simple-bond";
import useUbiquistick from "./lib/hooks/use-ubiquistick";
import { goldenPool } from "./lib/pools";

import { ethers, utils } from "ethers";
import useTransactionLogger from "../lib/hooks/use-transaction-logger";
import useWalletAddress from "../lib/hooks/use-wallet-address";
import useWeb3Provider from "../lib/hooks/use-web-3-provider";
import Button from "../ui/button";
import AllowanceManager from "./allowance-manager";
import FundingPools from "./funding-pools";
import LaunchPartyHeader from "./header";
import Liquidate from "./liquidate";
import MultiplicationPool from "./multiplication-pool";
import RewardsManager from "./rewards-manager";
import UbiquiStick from "./ubiquistick";
import YourBonds from "./your-bonds";

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
    <div>
      <div>
        <div onClick={() => setShowAdminComponents(false)}></div>
        <div>
          {isSaleContractOwner ? <AllowanceManager defaultAddress={walletAddress || ""} onSubmit={contractSetAllowance} /> : null}
          {isSimpleBondOwner ? <RewardsManager onSubmit={contractSimpleBondSetReward} ratios={tokensRatios} /> : null}
        </div>
      </div>

      <LaunchPartyHeader />

      {showAdminButton ? (
        <div>
          <Button disabled={!showAdminButton} onClick={() => setShowAdminComponents(true)}>
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
