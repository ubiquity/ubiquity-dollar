import axios from "axios";
import { spawn } from "child_process";
import {
    RPC_LIST,
    RPC_DELAY,
    REQ_BODY,
    RESP_STATUS
} from "./conf";

const getRandom = async (array: string[]) => {
    const length = array == null ? 0 : array.length;
    return length ? array[Math.floor(Math.random() * length)] : undefined;
};

const getUrl = async () => {
    let isRPC = false;

    while (!isRPC) {
        try {
            const rpcUrl = await getRandom(RPC_LIST);
            const resp = await axios.post(rpcUrl as string, REQ_BODY);

            if (resp.status === RESP_STATUS) {
                isRPC = true;
                return rpcUrl;
            }
        } catch (error) {
            await setTimeout(() => ({}), RPC_DELAY);
        }
    }
};

(async () => {
    const currentRPC = await getUrl();
    console.log(`using ${currentRPC} for testing...`);
    const command = spawn("forge", ["test", "--fork-url", currentRPC as string]);
    command.stdout.on("data", (output: any) => {
        console.log(output.toString());
    });
})();
