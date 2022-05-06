import useWeb3Provider from "./useWeb3Provider";
import dollarDeployments from "@/fixtures/contracts-addresses/dollar.json";
import ubiquistickDeployments from "@/fixtures/contracts-addresses/ubiquistick.json";

const LOCAL_CHAIN = "31337";
const LOCAL_FORK_FROM = "1";

type DollarType = typeof dollarDeployments[1];
type UbiquistickType = typeof ubiquistickDeployments[31337];

type ContractsNames = keyof DollarType | keyof UbiquistickType;
type AddressesObject = { [key: string]: string };
type ChainsAddressesObject = { [key: string]: AddressesObject };

const dollarChains = dollarDeployments as ChainsAddressesObject;
const ubiquistickChains = ubiquistickDeployments as ChainsAddressesObject;

const useDeployedAddress = (...names: ContractsNames[]): string[] => {
  const chainId = typeof window === "undefined" ? null : (window as any)?.ethereum?.networkVersion;
  if (chainId) {
    const fallbackDollar = dollarChains[LOCAL_FORK_FROM] || {};
    const fallbackUbiquistick = ubiquistickChains[LOCAL_FORK_FROM] || {};
    const dollar = dollarChains[chainId] || {};
    const ubiquistick = ubiquistickChains[chainId] || {};

    const getContractAddress = (key: string) => {
      return dollar[key] || ubiquistick[key] || (chainId === LOCAL_CHAIN ? fallbackDollar[key] || fallbackUbiquistick[key] : "");
    };

    return names.map((name) => {
      const address = getContractAddress(name);
      if (!address) {
        console.error(`No address for ${name} on chain ID ${chainId}`);
      }
      return address;
    });
  } else {
    return [];
  }
};

export default useDeployedAddress;
