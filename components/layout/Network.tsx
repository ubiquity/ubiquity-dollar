import { useEffect, useState } from "react";

import { useWeb3Provider } from "@/lib/hooks";
import { getNetworkName } from "@/lib/utils";

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

  return <div>{network}</div>;
};

export default Network;
