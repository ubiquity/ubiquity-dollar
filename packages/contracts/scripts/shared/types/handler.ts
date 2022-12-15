import { Env } from "./env";

export type DeployFuncParam = {
  env: Env;
  args: any;
};

export type DeployFuncCallback = (params: DeployFuncParam) => Promise<any>;

export type TaskFuncParam = {
  env: Env;
  args: any;
};

export type TaskFuncCallBack = (params: TaskFuncParam) => Promise<any>;
