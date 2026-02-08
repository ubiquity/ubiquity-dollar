import { ethers } from "ethers";
import useProtocolContracts, { ProtocolContracts } from "./hooks/contracts/use-protocol-contracts";
import useNamedContracts, { NamedContracts } from "./hooks/contracts/use-named-contracts";
import useWeb3, { PossibleProviders } from "./hooks/use-web-3";

export type LoadedContext = {
  protocolContracts: NonNullable<ProtocolContracts>;
  namedContracts: NonNullable<NamedContracts>;
  web3Provider: NonNullable<PossibleProviders>;
  walletAddress: string;
  signer: ethers.providers.JsonRpcSigner;
};

export default function withLoadedContext<T>(El: (params: LoadedContext & T) => JSX.Element, ElNull?: () => JSX.Element) {
  return (otherParams: T) => {
    const { walletAddress, signer, provider } = useWeb3();
    const namedContracts = useNamedContracts();
    const protocolContracts = useProtocolContracts();

    if (provider && walletAddress && signer && protocolContracts && namedContracts) {
      return (
        <El
          web3Provider={provider}
          walletAddress={walletAddress}
          signer={signer}
          namedContracts={namedContracts}
          protocolContracts={protocolContracts}
          {...otherParams}
        />
      );
    } else {
      return ElNull ? <ElNull /> : null;
    }
  };
}
