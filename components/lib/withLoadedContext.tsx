import { ethers } from "ethers";
import { DeployedContracts, default as useDeployedContracts } from "./hooks/contracts/useDeployedContracts";
import { ManagedContracts, default as useManagerManaged } from "./hooks/contracts/useManagerManaged";
import { NamedContracts, default as useNamedContracts } from "./hooks/contracts/useNamedContracts";
import { Web3Provider, default as useWeb3Provider } from "./hooks/useWeb3Provider";
import { default as useWalletAddress } from "./hooks/useWalletAddress";
import { default as useSigner } from "./hooks/useSigner";

export type LoadedContext = {
  managedContracts: NonNullable<ManagedContracts>;
  deployedContracts: NonNullable<DeployedContracts>;
  namedContracts: NonNullable<NamedContracts>;
  web3Provider: NonNullable<Web3Provider>;
  walletAddress: string;
  signer: ethers.providers.JsonRpcSigner;
};

export default function withLoadedContext<T>(El: (params: LoadedContext & T) => JSX.Element, ElNull?: () => JSX.Element) {
  return (otherParams: T) => {
    const web3Provider = useWeb3Provider();
    const [walletAddress] = useWalletAddress();
    const signer = useSigner();
    const managedContracts = useManagerManaged();
    const deployedContracts = useDeployedContracts();
    const namedContracts = useNamedContracts();

    if (web3Provider && walletAddress && signer && managedContracts && deployedContracts && namedContracts) {
      return (
        <El
          web3Provider={web3Provider}
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
