import useWeb3 from "./use-web-3";

const useSigner = () => {
  const { signer } = useWeb3();
  return signer;
};

export default useSigner;
