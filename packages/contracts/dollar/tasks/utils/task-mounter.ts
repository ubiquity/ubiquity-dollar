import { task } from "hardhat/config";
import { ActionType, CLIArgumentType } from "hardhat/types";
import path from "path";
import { libraryDirectory } from "../index";
import { colorizeText } from "./console-colors";

interface Params {
  [key: string]: string;
}
type ParamWithDefault = [string | undefined, unknown, CLIArgumentType<string> | undefined];
interface OptionalParams {
  [key: string]: ParamWithDefault[];
}
interface PositionalParams {
  [key: string]: ParamWithDefault[];
}
interface TaskModule {
  action: () => ActionType<any>;
  description?: string;
  params?: Params;
  optionalParams?: OptionalParams;
  positionalParams?: PositionalParams;
}

export function taskMounter(filename: string) {
  const pathToFile = path.join(libraryDirectory, filename);
  let taskName = filename.split("/").pop()?.split(".").shift() as string; // dynamically name task based on filename

  import(pathToFile).then(extendHardhatCli);

  function extendHardhatCli({ action, description, params, optionalParams, positionalParams }: TaskModule): void {
    description ? (description = colorizeText(description, "bright")) : false; // highlight custom task descriptions
    const extension = task(taskName, description);

    if (!action) {
      // import the task
      // required
      console.error(`\t${taskName} has no action export`);
      action = () => {
        throw new Error("No function found");
      };
    }

    if (!description) {
      // import the description
      // optional
      console.warn(`\t${colorizeText(taskName, "bright")} has no description`);
      description = "No description found";
    }

    if (params) {
      // import the required params
      // optional; if there are none this can still run
      Object.entries(params).forEach(([key, value]) => extension.addParam(key, value));
    } else {
      // console.warn(`\t${colorizeText(taskName, "bright")} has no params`);
    }

    if (optionalParams) {
      // import the optional params
      // optional
      Object.entries(optionalParams).forEach((optionalParam) => {
        const flattened = optionalParam.flat();
        // @ts-expect-error
        extension.addOptionalParam(...flattened);
      });
    } else {
      // console.warn(`\t${colorizeText(taskName, "bright")} has no optionalParams`);
    }

    if (positionalParams) {
      // import the positional params
      // optional
      Object.entries(positionalParams).forEach((positionalParam) => {
        const flattened = positionalParam.flat();
        // @ts-expect-error
        extension.addPositionalParam(...flattened);
      });
    } else {
      // console.warn(`\t${colorizeText(taskName, "bright")} has no positionalParams`);
    }

    extension.setAction(action());
  }
}
