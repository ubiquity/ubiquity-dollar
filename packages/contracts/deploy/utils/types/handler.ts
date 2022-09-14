import { Env } from "./env"

export type DeployFuncParam = {
    env: Env
    args: string[]
};

export type DeployFuncCallback = (params: DeployFuncParam) => Promise<any>;