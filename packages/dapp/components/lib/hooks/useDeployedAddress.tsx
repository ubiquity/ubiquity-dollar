// @dev you need to run a build to generate these fixtures.
import dollarDeployments from "@ubiquity/dollar/deployments.json";
import ubiquiStickDeployments from "@ubiquity/ubiquistick/deployments.json";

const LOCAL_CHAIN = 31337;
const dollarChains: Record<string, any> = dollarDeployments;
const ubiquistickChains: Record<string, any> = ubiquiStickDeployments;

const useDeployedAddress = (...names: string[]): string[] => {
  const chainId: number = typeof window === "undefined" ? null : window?.ethereum?.networkVersion || LOCAL_CHAIN;
  if (chainId) {
    const dollarRecord = dollarChains[chainId.toString()] ?? {};
    const ubiquistickRecord = ubiquistickChains[chainId.toString()] ?? {};

    const getContractAddress = (name: string): string | undefined => {
      const dollarContract = dollarRecord[0]?.contracts ? dollarRecord[0]?.contracts[name] : undefined
      const ubiquistickContract = ubiquistickRecord[0]?.contracts ? ubiquistickRecord[0]?.contracts[name] : undefined
      return dollarContract?.address || ubiquistickContract?.address || undefined;
    }

    const addresses = names.map(name => getContractAddress(name) || "");
    return addresses;
  } else {
    return [];
  }
};

export default useDeployedAddress;
