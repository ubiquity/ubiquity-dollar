import BondingSharesExplorer from "old-components/staking/BondingSharesExplorer";
import WalletConnectionWall from "old-components/ui/WalletConnectionWall";

export default function Staking() {
  return (
    <WalletConnectionWall>
      <BondingSharesExplorer />
    </WalletConnectionWall>
  );
}
