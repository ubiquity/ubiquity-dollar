import { FC } from "react";
import CreditNft from "@/components/redeem/credit-nft";
import useWalletAddress from "@/components/lib/hooks/use-wallet-address";

const CreditNftPage: FC = (): JSX.Element => {
  const [walletAddress] = useWalletAddress();
  return <div>{walletAddress && <CreditNft />}</div>;
};

export default CreditNftPage;
