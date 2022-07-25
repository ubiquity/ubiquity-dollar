import { loadInvestorsFromJsonFile } from "./loadInvestorsFromJsonFile";
import { verifyDataShape } from "./verifyDataShape";

export async function getInvestors(pathToJson: string) {
  if (typeof pathToJson !== "string") {
    throw new Error("Recipients must be a path to a json file");
  }

  const recipients = await loadInvestorsFromJsonFile(pathToJson);
  recipients.forEach(verifyDataShape);
  return recipients;
}
