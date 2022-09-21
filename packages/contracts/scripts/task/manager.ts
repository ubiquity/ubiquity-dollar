import { TaskFuncCallBack } from "../shared";


export const TASK_FUNCS: Record<string, { handler: TaskFuncCallBack, options: any }> = {
    "PriceReset": {
        handler: bondingFunc,
        options: bondingOptions
    }
}