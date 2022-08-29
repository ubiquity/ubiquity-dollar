import { Signer } from "ethers";
import { ethers, getNamedAccounts, network } from "hardhat";
import { expect } from "chai";
import { IERC20 } from "../artifacts/types/IERC20";
import { IJar } from "../artifacts/types/IJar";
import { YieldProxy } from "../artifacts/types/YieldProxy";
import { IController } from "../artifacts/types/IController";
import { mineNBlock, resetFork } from "./utils/hardhatNode";
import { isAmountEquivalent } from "./utils/calc";

describe("Pickle", () => {
  let jar: IJar;
  let pickleController: IController;
  let admin: Signer;
  let secondAccount: Signer;
  let usdcToken: IERC20;
  let DAI: string;
  let USDC: string;
  let USDT: string;
  let usdcWhaleAddress: string;
  let pickleControllerAddr: string;
  let strategyYearnUsdcV2: string;
  let jarUSDCAddr: string;
  let usdcWhale: Signer;
  beforeEach(async () => {
    ({ DAI, USDC, USDT, usdcWhaleAddress, jarUSDCAddr, pickleControllerAddr, strategyYearnUsdcV2 } = await getNamedAccounts());
    [admin, secondAccount] = await ethers.getSigners();
    await resetFork(13185077);

    jar = (await ethers.getContractAt("IJar", jarUSDCAddr)) as IJar;
    pickleController = (await ethers.getContractAt("IController", pickleControllerAddr)) as IController;
    usdcToken = (await ethers.getContractAt("IERC20", USDC)) as IERC20;

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [usdcWhaleAddress],
    });

    usdcWhale = ethers.provider.getSigner(usdcWhaleAddress);
    // mint uad for whale
  });
  describe("jar", () => {
    it("deposit should work ", async () => {
      const secondAccountAdr = await secondAccount.getAddress();
      // usdc is only 6 decimals
      const amountToDeposit = ethers.utils.parseUnits("1000000", 6);

      const balWhaleUsdc = await usdcToken.balanceOf(usdcWhaleAddress);

      console.log(`

      balWhaleUsdc:${ethers.utils.formatUnits(balWhaleUsdc, 6)}
      `);

      await usdcToken.connect(usdcWhale).transfer(secondAccountAdr, amountToDeposit);

      const balUsdc1 = await usdcToken.balanceOf(secondAccountAdr);
      const balJar1 = await jar.balanceOf(secondAccountAdr);
      const ratio1 = await jar.getRatio();

      console.log(`
      ratio:${ethers.utils.formatEther(ratio1)}
      balJar:${ethers.utils.formatEther(balJar1)}
      balUsdc:${ethers.utils.formatUnits(balUsdc1, 6)}
      `);
      await usdcToken.connect(secondAccount).approve(jarUSDCAddr, amountToDeposit);
      await jar.connect(secondAccount).deposit(amountToDeposit);
      const balUsdc2 = await usdcToken.balanceOf(secondAccountAdr);
      const balJar2 = await jar.balanceOf(secondAccountAdr);
      const ratio2 = await jar.getRatio();

      console.log(`
      AFTER DEPOSIT
      ratio:${ethers.utils.formatEther(ratio2)}
      balJar:${ethers.utils.formatEther(balJar2)}
      balUsdc:${ethers.utils.formatUnits(balUsdc2, 6)}

      `);

      // ratio is jar balance + controller balance / jar token total supply
      expect(ratio2.gt(ratio1)).to.be.true;
      const balUSDCJar1 = await usdcToken.balanceOf(jarUSDCAddr);
      await jar.earn();
      const balUSDCController = await usdcToken.balanceOf(pickleControllerAddr);
      console.log(`

      balUSDCController:${ethers.utils.formatUnits(balUSDCController, 6)}

      `);
      const balUSDCJar2 = await usdcToken.balanceOf(jarUSDCAddr);
      const ratio3 = await jar.getRatio();
      console.log(`
      AFTER EARN
      balUSDCJar1:${ethers.utils.formatUnits(balUSDCJar1, 6)}
      balUSDCJar2:${ethers.utils.formatUnits(balUSDCJar2, 6)}
      ratio:${ethers.utils.formatEther(ratio3)}
      `);

      //  move in time and withdraw

      // await mineNBlock(100);
      // simulate yield + 100%
      await usdcToken.connect(usdcWhale).transfer(strategyYearnUsdcV2, amountToDeposit);
      await jar.earn();
      const ratio4 = await jar.getRatio();
      const tx = await jar.connect(secondAccount).withdrawAll();
      const balUsdcUserAfterWithdraw = await usdcToken.balanceOf(secondAccountAdr);
      const balUsdc3 = await usdcToken.balanceOf(secondAccountAdr);
      const balJar3 = await jar.balanceOf(secondAccountAdr);
      const ratio4After = await jar.getRatio();
      console.log(`
      AFTER Withdraw
      USDC amount deposited    : ${ethers.utils.formatUnits(amountToDeposit, 6)}
      balUsdcUserAfterWithdraw :${ethers.utils.formatUnits(balUsdcUserAfterWithdraw, 6)}
      net win : ${ethers.utils.formatUnits(balUsdcUserAfterWithdraw.sub(amountToDeposit), 6)}
      ratio4 :${ethers.utils.formatEther(ratio4)}
      ratio4After:${ethers.utils.formatEther(ratio4After)}
      balJar:${ethers.utils.formatEther(balJar3)}
      balUsdc:${ethers.utils.formatUnits(balUsdc3, 6)}

      `);
      // multiply the deposit by the percentage of increase in the ratio
      const calculatedWithdrawAmount = amountToDeposit.mul(ratio4).div(ratio1);
      expect(balUsdc3).to.equal(calculatedWithdrawAmount);
      /*  const isPrecise = isAmountEquivalent(
        balUsdc3.toString(),
        calculatedWithdrawAmount.toString(),
        "0.000000000000000001"
      );
      expect(isPrecise).to.be.true;
      console.log(`

      balUsdc3 :               ${balUsdc3.toString()}
      calculatedWithdrawAmount:${calculatedWithdrawAmount.toString()}


      `); */
      /*   const secondAccountDAIBalanceAfter = await daiToken.balanceOf(
        secondAccountAdr
      );
      const secondAccountuADBalanceAfter = await uAD.balanceOf(
        secondAccountAdr
      );
      expect(secondAccountDAIBalanceAfter).to.equal(
        secondAccountDAIBalanceBefore.sub(amountToSwap)
      );
      const expectedUAD = uAD2ndBalbeforeSWAP.add(dyUAD); */
    });
  });
});
