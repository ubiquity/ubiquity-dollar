import { DeployFuncParam } from "../utils";

export const optionDefinitions = [{ name: 'manager', alias: 'manager', type: String }]

const func = async (params: DeployFuncParam) => {
    return "OK"
}
export default func;