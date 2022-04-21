import Icon from "./Icon";

const WalletNotConnected = (
  <div className="flex items-center rounded-xl bg-white/10 p-8 text-lg text-white/50">
    <div className="mr-8 w-20">
      <Icon icon="wallet" />
    </div>
    Connect wallet to continue
  </div>
);

export default WalletNotConnected;
