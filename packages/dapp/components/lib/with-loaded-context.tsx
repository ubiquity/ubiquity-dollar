import { ethers } from "ethers";
import useDeployedContracts, { DeployedContracts } from "./hooks/contracts/use-deployed-contracts";
import { ManagedContracts } from "./hooks/contracts/use-manager-managed";
import useNamedContracts, { NamedContracts } from "./hooks/contracts/use-named-contracts";
import useWeb3, { PossibleProviders } from "./hooks/use-web-3";

import useManagerManaged from "@/components/lib/hooks/contracts/use-manager-managed";
export type LoadedContext = {
  managedContracts: NonNullable<ManagedContracts>;
  deployedContracts: NonNullable<DeployedContracts>;
  namedContracts: NonNullable<NamedContracts>;
  web3Provider: NonNullable<PossibleProviders>;
  walletAddress: string;
  signer: ethers.providers.JsonRpcSigner;
};

export default function withLoadedContext<T>(El: (params: LoadedContext & T) => JSX.Element, ElNull?: () => JSX.Element) {
  return (otherParams: T) => {
    const { walletAddress, signer, provider } = useWeb3();
    const managedContracts = useManagerManaged();
    const deployedContracts = useDeployedContracts();
    const namedContracts = useNamedContracts();

    if (provider && walletAddress && signer && managedContracts && deployedContracts && namedContracts) {
      return (
        <El
          web3Provider={provider}
          walletAddress={walletAddress}
          signer={signer}
          namedContracts={namedContracts}
          managedContracts={managedContracts}
          deployedContracts={deployedContracts}
          {...otherParams}
        />
      );
    } else {
      return ElNull ? <ElNull /> : null;
    }
  };
}
