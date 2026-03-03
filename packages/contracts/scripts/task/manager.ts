import { OptionDefinition } from "command-line-args";

import { TaskFuncCallBack } from "../shared";

import PriceResetHandler, { optionDefinitions as priceResetOptions } from "./dollar/price-reset";
import BlocksInWeekHandler, { optionDefinitions as blocksInWeekOptions } from "./dollar/blocks-in-week";
import SecurityMonitorHandler, { optionDefinitions as securityMonitorOptions } from "./dollar/security-monitor";

export const TASK_FUNCS: Record<string, { handler: TaskFuncCallBack; options: OptionDefinition[] }> = {
  PriceReset: {
    handler: PriceResetHandler,
    options: priceResetOptions,
  },
  BlocksInWeek: {
    handler: BlocksInWeekHandler,
    options: blocksInWeekOptions,
  },
  SecurityMonitor: {
    handler: SecurityMonitorHandler,
    options: securityMonitorOptions,
  },
};
