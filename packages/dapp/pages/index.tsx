import { ethers } from "ethers";
import { FC, useState } from "react";
import '@uniswap/widgets/fonts.css'

import useManagerManaged from "@/components/lib/hooks/contracts/useManagerManaged";
import useEffectAsync from "@/components/lib/hooks/useEffectAsync";
import useWalletAddress from "@/components/lib/hooks/useWalletAddress";
import DollarPrice from "@/components/redeem/DollarPrice";
import MigrateButton from "@/components/redeem/MigrateButton";
import WalletNotConnected from "@/components/ui/WalletNotConnected";

const index: FC = (): JSX.Element => {
  const [twapPrice, setTwapPrice] = useState<ethers.BigNumber | null>(null);
  const [walletAddress] = useWalletAddress();
  const managedContracts = useManagerManaged();

  useEffectAsync(async () => {
    if (managedContracts) {
      setTwapPrice(await managedContracts.dollarTwapOracle.consult(managedContracts.dollarToken.address));
    }
  }, [managedContracts]);

  return walletAddress ? (
    <>
      <DollarPrice />
      <MigrateButton />
    </>
  ) : (
    WalletNotConnected
  );
};

export default index;
