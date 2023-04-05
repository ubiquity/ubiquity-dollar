export const RPC_LIST: string[] = [
  "https://eth.ubq.fi/v1/mainnet",
  "https://rpc.flashbots.net",
  "https://nodes.mewapi.io/rpc/eth",
  "https://cloudflare-eth.com",
  "https://rpc.ankr.com/eth",
  "https://eth.llamarpc.com",
  "https://api.securerpc.com/v1",
];

export const LOCAL_RPC = "http://127.0.0.1:8545";

export const RPC_BODY = JSON.stringify({
  jsonrpc: "2.0",
  method: "eth_getBlockByNumber",
  params: ["latest", false],
  id: 1,
});

export const RPC_HEADER = {
  "Content-Type": "application/json",
};
