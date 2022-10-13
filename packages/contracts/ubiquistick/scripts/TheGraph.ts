import type { Response } from "node-fetch";
import fetch from "node-fetch";

const runQuery = async (buffer: string): Promise<string> => {
  const res: Response = await fetch(uniswapV3API, { method: "POST", body: buffer });
  return (await res.json()) as string;
};

const uniswapV3API = "https://api.thegraph.com/subgraphs/name/uniswap/uniswap-v3";
const queryTimestamp = `{"query": "{positions(where: {id: 185851}) {transaction {timestamp}}}"}`;

const main = async () => {
  return JSON.stringify(await runQuery(queryTimestamp), null, 2);
};

main().then(console.log).catch(console.error);
