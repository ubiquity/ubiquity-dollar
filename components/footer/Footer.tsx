import { useConnectedContext } from "../context/connected";
import Inventory from "../inventory";

export default function Header() {
  const { balances, account, contracts } = useConnectedContext();

  if (!balances || !contracts || !account) {
    return null;
  }

  return <Inventory balances={balances} address={account.address} contracts={contracts} />;
}
