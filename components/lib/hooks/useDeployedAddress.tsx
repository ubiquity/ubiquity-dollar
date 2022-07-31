import dollarDeployments from "@/fixtures/contracts-addresses/dollar.json";
import ubiquiStickDeployments from "@/fixtures/contracts-addresses/ubiquistick.json";

const LOCAL_CHAIN = 31337;
const LOCAL_FORK_FROM = 1;

console.log(ubiquiStickDeployments);

// type Dollar = typeof dollarDeployments[1];
// type UbiquiStick = typeof ubiquiStickDeployments[31337];

// type ContractsNames = keyof Dollar | keyof UbiquiStick;
type ContractsNames = string;
type AddressesObject = { [key: string]: string };
type ChainsAddressesObject = { [key: string]: AddressesObject };

const dollarChains = dollarDeployments as ChainsAddressesObject;
const ubiquistickChains = ubiquiStickDeployments as ChainsAddressesObject;

class ContractNotAvailable extends Error {
  constructor(contractName: string, chainId: string) {
    super(`Necessary contract ${contractName} not deployed on chain ID ${chainId}`); // (1)
    this.name = "ContractNotAvailable"; // (2)
  }
}

const useDeployedAddress = (...names: ContractsNames[]): string[] => {
  const chainId = typeof window === "undefined" ? null : window?.ethereum?.networkVersion || LOCAL_CHAIN;
  if (chainId) {
    const fallbackDollar = dollarChains[LOCAL_FORK_FROM] || {};
    const fallbackUbiquistick = ubiquistickChains[LOCAL_FORK_FROM] || {};
    const dollar = dollarChains[chainId] || {};
    const ubiquistick = ubiquistickChains[chainId] || {};

    const getContractAddress = (key: string) =>
      dollar[key] || ubiquistick[key] || (chainId === LOCAL_CHAIN ? fallbackDollar[key] || fallbackUbiquistick[key] : "");

    return names.map((name) => {
      const address = getContractAddress(name);
      if (!address) {
        throw new ContractNotAvailable(name, chainId);
      }
      return address;
    });
  } else {
    return [];
  }
};

export default useDeployedAddress;
