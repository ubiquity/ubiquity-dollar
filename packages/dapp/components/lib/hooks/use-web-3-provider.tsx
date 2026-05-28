import useWeb3 from "./use-web-3";

const useWeb3Provider = () => {
  const { provider } = useWeb3();

  return provider;
};

export default useWeb3Provider;
