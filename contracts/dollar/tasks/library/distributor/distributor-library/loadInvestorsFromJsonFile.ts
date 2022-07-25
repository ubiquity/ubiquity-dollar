import path from "path";
import { warn } from "../../../../hardhat.config";
import { Investor } from "./investor-types";

export async function loadInvestorsFromJsonFile(pathToJson: string): Promise<Investor[]> {
  try {
    const importing = await import(pathToJson);
    const recipients = importing.default;
    return recipients;
  } catch (e) {
    warn(`incorrect pathToJson`);
    warn(path.resolve(pathToJson));
    throw e;
  }
}
