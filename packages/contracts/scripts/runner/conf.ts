export const RPC_DELAY = 300;

export const RPC_LIST: string[] = [
    "https://ethereum.publicnode.com",
    "https://cloudflare-eth.com",
    "https://rpc.ankr.com/eth",
    "https://eth-mainnet.public.blastapi.io",
    "https://eth-mainnet-public.unifra.io",
    "https://nodes.mewapi.io/rpc/eth",
    "https://rpc.flashbots.net"
];

export const REQ_BODY = {
    method: "eth_blockNumber",
    params: [],
    id: "1",
    jsonrpc: "2.0"
};

export const RESP_STATUS = 200;
