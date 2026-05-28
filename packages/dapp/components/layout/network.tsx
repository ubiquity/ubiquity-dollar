import { useEffect, useState } from "react";

import { getNetworkName } from "@/lib/utils";
import useWeb3Provider from "../lib/hooks/use-web-3-provider";

const Network = () => {
  const web3Provider = useWeb3Provider();
  const [network, setNetwork] = useState("");

  useEffect(() => {
    if (web3Provider) {
      const networkName = getNetworkName(web3Provider);
      setNetwork(networkName);
    }
  }, [web3Provider]);

  if (!web3Provider) {
    return null;
  }

  return <>{network}</>;
};

export default Network;
