import { ethers } from "ethers";
import { FC, useState } from "react";
import "@uniswap/widgets/fonts.css";

import useManagerManaged from "@/components/lib/hooks/contracts/useManagerManaged";
import useEffectAsync from "@/components/lib/hooks/useEffectAsync";
import DollarPrice from "@/components/redeem/DollarPrice";
import WalletConnectionWall from "@/components/ui/WalletConnectionWall";

const index: FC = (): JSX.Element => {
  const [twapPrice, setTwapPrice] = useState<ethers.BigNumber | null>(null);
  const managedContracts = useManagerManaged();

  useEffectAsync(async () => {
    if (managedContracts) {
      setTwapPrice(await managedContracts.dollarTwapOracle.consult(managedContracts.dollarToken.address));
    }
  }, [managedContracts]);

  return (
    <WalletConnectionWall>
      <DollarPrice />
    </WalletConnectionWall>
  );
};

export default index;
