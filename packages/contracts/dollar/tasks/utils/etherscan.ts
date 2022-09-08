const API_URL = "https://api.etherscan.io/api";

export type EtherscanResponse<T> = {
  status: string;
  message: string;
  result: T[];
};

export type Transaction = {
  isError: "0" | "1";
  input: string;
  hash: string;
  from: string;
  to: string;
  blockNumber: string;
  contractAddress: string;
  timeStamp: string;
};

export type TransactionEvent = {
  data: string;
  transactionHash: string;
};

export async function fetchEtherscanApi<T>(query: Record<string, string>): Promise<T> {
  const response = await fetch(`${API_URL}?${new URLSearchParams(query).toString()}`);
  return response.json() as Promise<T>;
}

export async function fetchLatestBlockNumber(): Promise<number> {
  console.log("Fetching latest block number...");
  const response = await fetchEtherscanApi<{ result: string }>({
    module: "proxy",
    action: "eth_blockNumber",
    apiKey: process.env.API_KEY_ETHERSCAN || "",
  });
  const latestBlockNumber = parseInt(response.result, 16);
  console.log("Latest block number: ", latestBlockNumber);
  return latestBlockNumber;
}

export function generateEtherscanQuery(address: string, startblock: number, endblock: number | string): Record<string, string> {
  return {
    module: "account",
    action: "txlist",
    address,
    startblock: startblock.toString(),
    endblock: endblock.toString(),
    sort: "asc",
    apiKey: process.env.API_KEY_ETHERSCAN || "",
  };
}

export function generateEventLogQuery(address: string, topic0: string, startblock: number, endblock: number | string): Record<string, string> {
  return {
    module: "logs",
    action: "getLogs",
    address,
    topic0,
    startblock: startblock.toString(),
    endblock: endblock.toString(),
    sort: "asc",
    apiKey: process.env.API_KEY_ETHERSCAN || "",
  };
}
