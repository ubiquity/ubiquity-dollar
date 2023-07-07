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
      const diamondAddress = "0xbe0efAbc83686a81903C1D4a2515f8111e53B5Cb";
      const managerContract = await getUbiquityManagerContract(diamondAddress, provider);

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