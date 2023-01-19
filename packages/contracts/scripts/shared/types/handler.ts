import { Env } from "./env";
import commandLineArgs from "command-line-args";

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

export type InputParams = {
  [index: string]: string;
};

export type DeployCallbackFn = {
  [index: string]: (args: any) => void;
};

export type AbiType = object[];

export type CommandLineOption = commandLineArgs.CommandLineOptions;
