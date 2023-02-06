import useWeb3 from "./useWeb3";

const useSigner = () => {
  const [{ signer }] = useWeb3();
  return signer;
};

export default useSigner;
