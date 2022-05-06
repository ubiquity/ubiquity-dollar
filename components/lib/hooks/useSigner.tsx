import useWalletAddress from "./useWalletAddress";
import useWeb3Provider from "./useWeb3Provider";

const useSigner = () => {
  const [walletAddress] = useWalletAddress();
  const provider = useWeb3Provider();

  const signer = provider && walletAddress ? provider.getSigner(walletAddress) : null;

  return signer;
};

export default useSigner;
