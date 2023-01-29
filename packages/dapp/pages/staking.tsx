import BondingSharesExplorer from "@/components/staking/BondingSharesExplorer";
import WalletConnectionWall from "@/components/ui/WalletConnectionWall";

export default function Staking() {
  return (
    <WalletConnectionWall>
      <BondingSharesExplorer />
    </WalletConnectionWall>
  );
}
