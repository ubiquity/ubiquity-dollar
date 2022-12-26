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

export type ArgsType = {
  [index: string]: string;
};

export type Deploy_Manager_Type = {
  [indexed: string]: (args: any) => void;
};

export type CMDType = commandLineArgs.CommandLineOptions;