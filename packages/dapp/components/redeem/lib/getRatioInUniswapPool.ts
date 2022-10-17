import { useEffect, useState } from "react";
import { ethers } from "ethers";
import { getuCRTokenContract, getuADTokenContract, getUSDCTokenContract, getUSDTTokenContract, getDAITokenContract } from "@/components/utils/contracts";
import { USDC_ADDRESS, DAI_ADDRESS, USDT_ADDRESS, uCR_uAD_ADDRESS, uCR_USDC_ADDRESS, uCR_DAI_ADDRESS, uCR_USDT_ADDRESS } from "../../lib/utils";
import useDeployedContracts from "@/components/lib/hooks/contracts/useDeployedContracts";
import useWeb3 from "@/components/lib/hooks/useWeb3";

const useRatio = (selectedToken: string): number => {
  const deployedContracts = useDeployedContracts();
  const [{ provider }] = useWeb3();
  const [ratio, setRatio] = useState<number>(0);

  async function refreshGetRatio() {
    if (provider && deployedContracts) {
      let uCRAmount;
      let pairAmount;
      let ratio;
      const uCRTokenContract = getuCRTokenContract(await deployedContracts.manager.autoRedeemTokenAddress(), provider);
      try {
        if (selectedToken === "uAD") {
          uCRAmount = await uCRTokenContract.balanceOf(uCR_uAD_ADDRESS);
          const uADTokenContract = getuADTokenContract(await deployedContracts.manager.dollarTokenAddress(), provider);
          pairAmount = await uADTokenContract.balanceOf(uCR_uAD_ADDRESS);
        } else if (selectedToken === "USDC") {
          uCRAmount = await uCRTokenContract.balanceOf(uCR_USDC_ADDRESS);
          const USDCTokenContract = getUSDCTokenContract(USDC_ADDRESS, provider);
          pairAmount = await USDCTokenContract.balanceOf(uCR_USDC_ADDRESS);
        } else if (selectedToken === "DAI") {
          uCRAmount = await uCRTokenContract.balanceOf(uCR_DAI_ADDRESS);
          const DAITokenContract = getDAITokenContract(DAI_ADDRESS, provider);
          pairAmount = await DAITokenContract.balanceOf(uCR_DAI_ADDRESS);
        } else if (selectedToken === "USDT") {
          uCRAmount = await uCRTokenContract.balanceOf(uCR_USDT_ADDRESS);
          const USDTTokenContract = getUSDTTokenContract(USDT_ADDRESS, provider);
          pairAmount = await USDTTokenContract.balanceOf(uCR_USDT_ADDRESS);
        }
        console.log(`pair(${selectedToken}) Amount:`, ethers.utils.formatEther(pairAmount), "|| uCR Amount:", ethers.utils.formatEther(uCRAmount));
        ratio = (pairAmount / uCRAmount).toFixed(2); // Pa*Aa = Pb*Ab, ratio = Aa/Ab = Pb/Pa, A-amount, P-price
        setRatio(Number(ratio));
      } catch (error) {
        console.log("exeption in getEstimatedReturnValue", error);
        return 0;
      }
    }
  }

  useEffect(() => {
    refreshGetRatio();
  }, [selectedToken]);

  console.log("ratio", ratio);

  return ratio;
};

export default useRatio;
