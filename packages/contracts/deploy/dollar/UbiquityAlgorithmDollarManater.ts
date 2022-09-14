import { DeployFuncParam } from "../utils";

const func = async (params: DeployFuncParam) => {
    const { env, args } = params;
    return "OK"
}
export default func;