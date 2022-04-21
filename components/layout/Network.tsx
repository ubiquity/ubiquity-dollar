import { useEffect, useState } from "react";

import { useConnectedContext } from "@/lib/connected";
import { getNetworkName } from "@/lib/utils";

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
    <div className="rounded-bl-lg border-l border-b border-solid border-accent/60 bg-white/10 px-4 py-2 font-special text-xs uppercase text-white/75">
      {network}
    </div>
  );
};

export default Network;
