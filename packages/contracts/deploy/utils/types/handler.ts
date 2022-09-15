import { Env } from "./env"

export type DeployFuncParam = {
    env: Env
    args: any
};

export type DeployFuncCallback = (params: DeployFuncParam) => Promise<any>;