import { ethers } from "ethers";
import { FC, useState } from "react";
import "@uniswap/widgets/fonts.css";

import useManagerManaged from "old-components/lib/hooks/contracts/useManagerManaged";
import useEffectAsync from "old-components/lib/hooks/useEffectAsync";
import DollarPrice from "old-components/redeem/DollarPrice";
import MigrateButton from "old-components/redeem/MigrateButton";
import WalletConnectionWall from "old-components/ui/WalletConnectionWall";

const index: FC = (): JSX.Element => {
  const [, setTwapPrice] = useState<ethers.BigNumber | null>(null);
  const managedContracts = useManagerManaged();

  useEffectAsync(async () => {
    if (managedContracts) {
      setTwapPrice(await managedContracts.dollarTwapOracle.consult(managedContracts.dollarToken.address));
    }
  }, [managedContracts]);

  return (
    <WalletConnectionWall>
      <DollarPrice />
      <MigrateButton />
    </WalletConnectionWall>
  );
};

export default index;
