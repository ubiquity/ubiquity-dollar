import { OptionDefinition } from "command-line-args";

import { TaskFuncCallBack } from "../shared";

import PriceResetHandler, { optionDefinitions as priceResetOptions } from "./dollar/priceReset";

export const TASK_FUNCS: Record<string, { handler: TaskFuncCallBack; options: OptionDefinition[] }> = {
  PriceReset: {
    handler: PriceResetHandler,
    options: priceResetOptions,
  },
};
