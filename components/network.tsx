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

  return network === "Mainnet" ? null : (
    <div className="px-4 py-2 border border-solid border-white border-opacity-25 rounded font-special uppercase text-xs text-white text-opacity-75">
      {network}
      {/* <span className="text-accent text-sm">{network}</span> */}
    </div>
  );
};

export default Network;
