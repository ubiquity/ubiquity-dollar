import { OptionDefinition } from "command-line-args";

import { TaskFuncCallBack } from "../shared";

import PriceResetHandler, { optionDefinitions, optionDefinitions as priceResetOptions } from "./dollar/price-reset";
import BlocksInWeekHandler from "./dollar/blocks-in-week";

export const TASK_FUNCS: Record<string, { handler: TaskFuncCallBack; options: OptionDefinition[] }> = {
  PriceReset: {
    handler: PriceResetHandler,
    options: priceResetOptions,
  },
  BlocksInWeek: {
    handler: BlocksInWeekHandler,
    options: optionDefinitions,
  },
};
