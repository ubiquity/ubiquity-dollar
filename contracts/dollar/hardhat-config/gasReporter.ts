import { getKey } from "./utils/getKey";
export default function gasReporter(REPORT_GAS?: string | boolean) {
  if (!REPORT_GAS) {
    REPORT_GAS = false;
  }

  return {
    enabled: Boolean(REPORT_GAS),
    currency: "USD",
    gasPrice: 60,
    onlyCalledMethods: true,
    coinmarketcap: getKey("COINMARKETCAP"),
  };
}
