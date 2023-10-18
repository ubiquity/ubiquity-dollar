import { BigNumber } from "ethers";
import { useState } from "react";

import { ensureERC20Allowance } from "@/lib/contracts-shortcuts";
import { formatEther } from "@/lib/format";
import { safeParseEther } from "@/lib/utils";
import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import useBalances from "../lib/hooks/use-balances";
import useSigner from "../lib/hooks/use-signer";
import useTransactionLogger from "../lib/hooks/use-transaction-logger";
import useWalletAddress from "../lib/hooks/use-wallet-address";
import Button from "../ui/button";
import PositiveNumberInput from "../ui/positive-number-input";

const CreditNftGenerator = () => {
  const [walletAddress] = useWalletAddress();
  const signer = useSigner();
  const [balances, refreshBalances] = useBalances();
  const [, doTransaction, doingTransaction] = useTransactionLogger();
  const protocolContracts = useProtocolContracts();

  const [inputVal, setInputVal] = useState("");
  const [expectedCreditNft, setExpectedCreditNft] = useState<BigNumber | null>(null);

  if (!walletAddress || !signer) {
    return <span>Connect wallet</span>;
  }

  if (!balances || !protocolContracts) {
    return <span>· · ·</span>;
  }

  const depositDollarForCreditNfts = async (amount: BigNumber) => {
    const contracts = await protocolContracts;
    if (contracts.dollarToken && contracts.creditNftManagerFacet) {
      // cspell: disable-next-line
      await ensureERC20Allowance("CREDIT -> CreditNftManagerFacet", contracts.dollarToken, amount, signer, contracts.creditNftManagerFacet.address);
      await (await contracts.creditNftManagerFacet.connect(signer).exchangeDollarsForCreditNft(amount)).wait();
      refreshBalances();
    }
  };

  const handleBurn = async () => {
    const amount = extractValidAmount();
    if (amount) {
      // cspell: disable-next-line
      doTransaction("Burning Dollar...", async () => {
        setInputVal("");
        await depositDollarForCreditNfts(amount);
      });
    }
  };

  const handleInput = async (val: string) => {
    const contracts = await protocolContracts;
    setInputVal(val);
    const amount = extractValidAmount(val);
    if (amount && contracts.creditNftRedemptionCalculatorFacet) {
      setExpectedCreditNft(null);
      setExpectedCreditNft(await contracts.creditNftRedemptionCalculatorFacet.connect(signer).getCreditNftAmount(amount));
    }
  };

  const extractValidAmount = (val: string = inputVal): null | BigNumber => {
    const amount = safeParseEther(val);
    return amount && amount.gt(BigNumber.from(0)) && amount.lte(balances.dollar) ? amount : null;
  };

  const submitEnabled = !!(extractValidAmount() && !doingTransaction);

  return (
    <div>
      {/* cspell: disable-next-line */}
      <PositiveNumberInput value={inputVal} onChange={handleInput} placeholder="Dollar Amount" />
      <Button onClick={handleBurn} disabled={!submitEnabled}>
        {/* cspell: disable-next-line */}
        Redeem Dollar for CREDIT-NFT
      </Button>
      {expectedCreditNft && inputVal && <p>expected CREDIT-NFT {formatEther(expectedCreditNft)}</p>}
    </div>
  );
};

export default CreditNftGenerator;
