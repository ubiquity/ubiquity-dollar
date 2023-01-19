import axios from "axios";
import { spawn } from "child_process";
import { performance } from "node:perf_hooks";
import { RETRY_COUNT, RETRY_DELAY, RPC_BODY, RPC_HEADER, RPC_LIST } from "./conf";

export type DataType = {
  jsonrpc: string;
  id: number;
  result: {
    number: string;
    timestamp: string;
    hash: string;
  };
};

export const verifyBlock = (data: DataType) => {
  try {
    const { jsonrpc, id, result } = data;
    const { number, timestamp, hash } = result;
    return jsonrpc === "2.0" && id === 1 && parseInt(number, 16) > 0 && parseInt(timestamp, 16) > 0 && hash.match(/[0-9|a-f|A-F|x]/gm)?.join("").length === 66;
  } catch (error) {
    return false;
  }
};

export const getRPC = async () => {
  const promises = RPC_LIST.map(async (baseURL: string) => {
    try {
      const startTime = performance.now();
      const API = axios.create({
        baseURL,
        headers: RPC_HEADER,
      });

      const { data } = await API.post("", RPC_BODY);
      const endTime = performance.now();
      const latency = endTime - startTime;
      if (await verifyBlock(data)) {
        return Promise.resolve({
          latency,
          baseURL,
        });
      } else {
        return Promise.reject();
      }
    } catch (error) {
      return Promise.reject();
    }
  });
  const { baseURL: optimalRPC } = await Promise.any(promises);
  return optimalRPC;
};

let shouldSkip = false;
let retryCount = 0;
export const procFork = async () => {
  const optimalRPC = await getRPC();
  console.log(`using ${optimalRPC} for unit-testing...`);
  const command = spawn("forge", ["test", "--fork-url", optimalRPC as string]);
  shouldSkip = false;
  command.stdout.on("data", (output: unknown) => {
    console.log(output?.toString());
  });
  command.stderr.on("data", (output: unknown) => {
    console.log(output?.toString());
    if (shouldSkip === false && retryCount <= RETRY_COUNT) {
      retryCount++;
      setTimeout(() => {
        procFork();
      }, RETRY_DELAY);
      shouldSkip = true;
    }
  });
  command.on("close", (code: number) => {
    // if linux command exit code is not success (0) then throw an error
    if (code !== 0) throw new Error("Failing tests");
  });
};
