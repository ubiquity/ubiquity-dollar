import useWeb3 from "./use-web-3";

const useWalletAddress = () => {
  const { walletAddress } = useWeb3();

  return [walletAddress];
};

export default useWalletAddress;
