import useWeb3 from "./useWeb3";

const useWalletAddress = () => {
  const [{ walletAddress }] = useWeb3();

  return [walletAddress];
};

export default useWalletAddress;
