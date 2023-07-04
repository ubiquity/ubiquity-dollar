import dotenv from "dotenv";
import { getUbiquityManagerContract } from "@/components/utils/contracts";
import { ethers } from "ethers";
import { LOCAL_NODE_ADDRESS } from "@/components/lib/hooks/use-web-3";

dotenv.config();

export async function fetchData() {
  if (process.env.DEBUG === "true") {
    const provider = new ethers.providers.JsonRpcProvider(LOCAL_NODE_ADDRESS);
    const signer = provider.getSigner();
    try {
      const managerAddress = "0x4e037B9A8Ce977462DA4E10Fc164363C827abfc6";
      const managerContract = await getUbiquityManagerContract(managerAddress, provider);

      console.log(await managerContract.connect(signer).twapOracleAddress(), "Twap Oracle Address");
      console.log(await managerContract.connect(signer).creditCalculatorAddress(), "Credit Calculator Address");

      const block = await provider?.getBlockNumber();
      console.log("Anvil Block Number", block);

      console.log("Connected to Chain ID", provider?.network.chainId);
    } catch (error) {
      console.log(error);
    }
  }
}

fetchData();
export default fetchData;
