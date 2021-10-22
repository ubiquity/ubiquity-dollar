import React, { useEffect, useState } from "react";
import { useConnectedContext } from "./context/connected";
import { getNetworkName } from "./common/utils";

const Network = () => {
  const { provider } = useConnectedContext();
  const [network, setNetwork] = useState("");

  useEffect(() => {
    if (provider) {
      const networkName = getNetworkName(provider);
      setNetwork(networkName);
    }
  }, [provider]);

  if (!provider) {
    return null;
  }

  return (
    <div>
      <span className="text-accent text-sm">{network}</span>
    </div>
  );
};

export default Network;
