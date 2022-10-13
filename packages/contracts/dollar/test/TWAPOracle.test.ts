import { BigNumber, ContractTransaction, Signer } from "ethers";
import { ethers, getNamedAccounts, network } from "hardhat";
import { describe, it } from "mocha";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { expect } from "./setup";
import { mineBlock, resetFork } from "./utils/hardhatNode";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { ERC20 } from "../artifacts/types/ERC20";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { ICurveFactory } from "../artifacts/types/ICurveFactory";
import { swap3CRVtoUAD, swapUADto3CRV, swapUADtoDAI } from "./utils/swap";

describe("TWAPOracle", () => {
  let metaPool: IMetaPool;
  let manager: UbiquityAlgorithmicDollarManager;
  let admin: Signer;
  let secondAccount: Signer;
  let uAD: UbiquityAlgorithmicDollar;
  let DAI: string;
  let curvePoolFactory: ICurveFactory;
  let curveFactory: string;
  let curve3CrvBasePool: string;
  let curve3CrvToken: string;
  let crvToken: ERC20;
  let daiToken: ERC20;
  let curveWhaleAddress: string;
  let curveWhale: Signer;
  let twapOracle: TWAPOracle;

  beforeEach(async () => {
    ({
      DAI,

      curveFactory,
      curve3CrvBasePool,
      curve3CrvToken,
      curveWhaleAddress,
    } = await getNamedAccounts());
    [admin, secondAccount] = await ethers.getSigners();
    await resetFork(12592661);
    const Manager = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");
    manager = (await Manager.deploy(await admin.getAddress())) as UbiquityAlgorithmicDollarManager;

    const UAD = await ethers.getContractFactory("UbiquityAlgorithmicDollar");
    uAD = (await UAD.deploy(manager.address)) as UbiquityAlgorithmicDollar;

    // mint 10000 uAD each for admin and secondAccount
    const mintings = [await admin.getAddress(), await secondAccount.getAddress(), manager.address].map(
      async (signer): Promise<ContractTransaction> => uAD.connect(admin).mint(signer, ethers.utils.parseEther("10000"))
    );
    await Promise.all(mintings);

    await manager.connect(admin).setDollarTokenAddress(uAD.address);

    crvToken = (await ethers.getContractAt("ERC20", curve3CrvToken)) as ERC20;
    daiToken = (await ethers.getContractAt("ERC20", DAI)) as ERC20;
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [curveWhaleAddress],
    });

    curveWhale = ethers.provider.getSigner(curveWhaleAddress);
    // mint uad for whale
    await uAD.connect(admin).mint(curveWhaleAddress, ethers.utils.parseEther("10"));

    await crvToken.connect(curveWhale).transfer(manager.address, ethers.utils.parseEther("10000"));

    await manager.connect(admin).deployStableSwapPool(curveFactory, curve3CrvBasePool, crvToken.address, 10, 4000000);

    const metaPoolAddr = await manager.stableSwapMetaPoolAddress();
    metaPool = (await ethers.getContractAt("IMetaPool", metaPoolAddr)) as IMetaPool;

    const TWAPOracleDeployment = await ethers.getContractFactory("TWAPOracle");
    twapOracle = (await TWAPOracleDeployment.deploy(metaPoolAddr, uAD.address, curve3CrvToken)) as TWAPOracle;

    await manager.connect(admin).setTwapOracleAddress(twapOracle.address);

    curvePoolFactory = (await ethers.getContractAt("ICurveFactory", curveFactory)) as ICurveFactory;
  });
  describe("Oracle", () => {
    it("should return correct price of 1 usd at pool init", async () => {
      const pool0bal = await metaPool.balances(0);
      const pool1bal = await metaPool.balances(1);
      expect(pool0bal).to.equal(ethers.utils.parseEther("10000"));
      expect(pool1bal).to.equal(ethers.utils.parseEther("10000"));
      const oraclePriceuAD = await twapOracle.consult(uAD.address);
      const oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);
      expect(oraclePriceuAD).to.equal(ethers.utils.parseEther("1"));
      expect(oraclePrice3Crv).to.equal(ethers.utils.parseEther("1"));
    });
    it("should return a higher price for 3CRV after a swap from uAD to 3CRV", async () => {
      const pool0balBefore = await metaPool.balances(0);
      const pool1balBefore = await metaPool.balances(1);
      const balancesBefore = await curvePoolFactory.get_balances(metaPool.address);
      // take the 3CRV price at this moment
      const curve3CRVPriceBefore = await metaPool["get_dy(int128,int128,uint256)"](1, 0, ethers.utils.parseEther("1"));

      const curveUADPriceBefore = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));

      const amountOfuADToSwap = ethers.utils.parseEther("1000");
      const accountAdr = await secondAccount.getAddress();
      const accountUADBalanceBeforeSwap = await uAD.balanceOf(accountAdr);

      let oraclePriceuAD = await twapOracle.consult(uAD.address);
      let oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);
      expect(oraclePriceuAD).to.equal(ethers.utils.parseEther("1"));
      expect(oraclePrice3Crv).to.equal(ethers.utils.parseEther("1"));

      const account3CRVBalanceBeforeSwap = await crvToken.balanceOf(accountAdr);

      // Exchange (swap)  uAD=>  3CRV
      const dyUADto3CRV = await swapUADto3CRV(metaPool, uAD, amountOfuADToSwap.sub(BigNumber.from(1)), secondAccount);
      await twapOracle.update();
      const oraclePriceuADBefore = await twapOracle.consult(uAD.address);
      const oraclePrice3CrvBefore = await twapOracle.consult(curve3CrvToken);

      // the way TWAP work doesn't include the new price yet but we can have it
      // through dy
      const curve3CRVPriceAfterSwap = await metaPool["get_dy(int128,int128,uint256)"](1, 0, ethers.utils.parseEther("1"));

      const curveUADPriceAfterSwap = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));

      expect(curve3CRVPriceAfterSwap).to.be.gt(curve3CRVPriceBefore);
      expect(curveUADPriceAfterSwap).to.be.lt(curveUADPriceBefore);
      // to reflect the new price inside the TWAP we need one more swap
      await swapUADto3CRV(metaPool, uAD, BigNumber.from(1), secondAccount);
      dyUADto3CRV.add(BigNumber.from(1));

      await twapOracle.update();
      oraclePriceuAD = await twapOracle.consult(uAD.address);
      oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);

      // we now have more uAD than before wich means that uAD is worth less than before
      // and 3CRV is worth more than before
      expect(oraclePriceuAD).to.be.lt(oraclePriceuADBefore);
      expect(oraclePrice3Crv).to.be.gt(oraclePrice3CrvBefore);
      const pool0balAfter = await metaPool.balances(0);
      const pool1balAfter = await metaPool.balances(1);
      const balancesAfter = await curvePoolFactory.get_balances(metaPool.address);
      expect(pool0balAfter).to.equal(pool0balBefore.add(amountOfuADToSwap));

      // we now have less 3CRV
      expect(pool1balBefore.sub(pool1balAfter)).to.be.gt(0);
      const adminFee = await curvePoolFactory.get_admin_balances(metaPool.address);

      // in the basepool we should be short the 3CRV amount transfered to the user + admin fees (50% of trade fee)
      // for exchanges the fee is taken in the output currency and calculated against the final amount received.
      expect(pool1balAfter).to.equal(pool1balBefore.sub(dyUADto3CRV.add(adminFee[1])));
      // account 3crv Balance should be equal to the estimate swap amount
      const account3CRVBalanceAfterSwap = await crvToken.balanceOf(accountAdr);

      expect(account3CRVBalanceAfterSwap).to.be.equal(account3CRVBalanceBeforeSwap.add(dyUADto3CRV));
      const accountuADBalanceAfterSwap = await uAD.balanceOf(accountAdr);
      expect(accountuADBalanceAfterSwap).to.be.equal(accountUADBalanceBeforeSwap.sub(amountOfuADToSwap));
      // pool1Blance should be less than before the swap
      expect(pool1balBefore.sub(pool1balAfter)).to.be.gt(0);
      // UAD balance in the pool should be equal to before + amount
      expect(balancesAfter[0].sub(balancesBefore[0])).to.equal(amountOfuADToSwap);
      // 3CRV balance in the pool should be less than before the swap
      expect(balancesBefore[1].sub(balancesAfter[1])).to.be.gt(0);

      // we should have positive fee in 3CRV
      expect(adminFee[1]).to.be.gt(0);

      // if no swap after x block the price stays the same
      const LastBlockTimestamp = await metaPool.block_timestamp_last();
      const blockTimestamp = LastBlockTimestamp.toNumber() + 23 * 3600;
      await mineBlock(blockTimestamp);
      await twapOracle.update();
      const oraclePriceAfterMine = await twapOracle.consult(uAD.address);
      expect(oraclePriceuAD.sub(oraclePriceAfterMine)).to.equal(0);
    });
    it("should return a higher price for uAD after a swap from 3CRV to uad", async () => {
      const pool0balBefore = await metaPool.balances(0);
      const pool1balBefore = await metaPool.balances(1);
      expect(pool0balBefore).to.equal(ethers.utils.parseEther("10000"));
      expect(pool1balBefore).to.equal(ethers.utils.parseEther("10000"));
      const balancesBefore = await curvePoolFactory.get_balances(metaPool.address);
      const amountOf3CRVToSwap = ethers.utils.parseEther("1000");
      const whaleUADBalanceBeforeSwap = await uAD.balanceOf(curveWhaleAddress);

      let oraclePriceuAD = await twapOracle.consult(uAD.address);
      let oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);
      expect(oraclePriceuAD).to.equal(ethers.utils.parseEther("1"));
      expect(oraclePrice3Crv).to.equal(ethers.utils.parseEther("1"));
      const uADInstantPriceRelativeTo3CRVBefore = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));

      const whale3CRVBalanceBeforeSwap = await crvToken.balanceOf(curveWhaleAddress);

      // Exchange (swap)  3CRV => uAD
      const dy3CRVtouAD = await swap3CRVtoUAD(metaPool, crvToken, amountOf3CRVToSwap.sub(BigNumber.from(1)), curveWhale);
      await twapOracle.update();

      // the way TWAP work doesn't include the new price yet but we can have it
      // through dy
      const uADPrice = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
      const uADInstantPriceRelativeTo3CRVAfterFirstSwap = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
      expect(uADPrice).to.be.gt(ethers.utils.parseEther("1"));
      // to reflect the new price inside the TWAP we need one more swap
      await swap3CRVtoUAD(metaPool, crvToken, BigNumber.from(1), curveWhale);
      dy3CRVtouAD.add(BigNumber.from(1));

      await twapOracle.update();
      oraclePriceuAD = await twapOracle.consult(uAD.address);
      oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);
      // we now have more 3CRV  than uAD  wich means that 3CRV is worth less than uAD
      expect(oraclePriceuAD).to.be.gt(ethers.utils.parseEther("1"));
      expect(oraclePrice3Crv).to.be.lt(ethers.utils.parseEther("1"));
      const pool0balAfter = await metaPool.balances(0);
      const pool1balAfter = await metaPool.balances(1);
      const balancesAfter = await curvePoolFactory.get_balances(metaPool.address);
      expect(pool1balAfter).to.equal(pool1balBefore.add(amountOf3CRVToSwap));

      // we now have less uAD
      expect(pool0balBefore.sub(pool0balAfter)).to.be.gt(0);
      const adminFee = await curvePoolFactory.get_admin_balances(metaPool.address);

      // in the basepool we should be short the uAD amount transfered to the user + admin fees (50% of trade fee)
      // for exchanges the fee is taken in the output currency and calculated against the final amount received.
      expect(pool0balAfter).to.equal(pool0balBefore.sub(dy3CRVtouAD.add(adminFee[0])));
      // whale account uAD Balance should be equal to the estimate swap amount
      const whaleUADBalanceAfterSwap = await uAD.balanceOf(curveWhaleAddress);

      expect(whaleUADBalanceAfterSwap).to.be.equal(whaleUADBalanceBeforeSwap.add(dy3CRVtouAD));
      const whale3CRVBalanceAfterSwap = await crvToken.balanceOf(curveWhaleAddress);
      expect(whale3CRVBalanceAfterSwap).to.be.equal(whale3CRVBalanceBeforeSwap.sub(amountOf3CRVToSwap));
      // pool0Blance should be less than before the swap
      expect(pool0balBefore.sub(pool0balAfter)).to.be.gt(0);
      // 3CRV balance in the pool should be equal to before + 1
      expect(balancesAfter[1].sub(balancesBefore[1])).to.equal(amountOf3CRVToSwap);
      // uAD balance in the pool should be less than before the swap
      expect(balancesBefore[0].sub(balancesAfter[0])).to.be.gt(0);

      // we should have positive fee in UAD
      expect(adminFee[0]).to.be.gt(0);

      await twapOracle.update();
      const oraclePriceuADAfter = await twapOracle.consult(uAD.address);
      expect(oraclePriceuADAfter).to.be.gt(ethers.utils.parseEther("1"));
      expect(uADInstantPriceRelativeTo3CRVAfterFirstSwap).to.be.gt(uADInstantPriceRelativeTo3CRVBefore);
      // if no swap after x block the price stays the same
      const LastBlockTimestamp = await metaPool.block_timestamp_last();
      const blockTimestamp = LastBlockTimestamp.toNumber() + 23 * 3600;
      await mineBlock(blockTimestamp);
      await twapOracle.update();
      const oraclePriceAfterMine = await twapOracle.consult(uAD.address);
      expect(oraclePriceuADAfter.sub(oraclePriceAfterMine)).to.equal(0);
    });
    it("should return correct price after a swap for token", async () => {
      const pool0balBefore = await metaPool.balances(0);
      const pool1balBefore = await metaPool.balances(1);
      expect(pool0balBefore).to.equal(ethers.utils.parseEther("10000"));
      expect(pool1balBefore).to.equal(ethers.utils.parseEther("10000"));
      const balancesBefore = await curvePoolFactory.get_balances(metaPool.address);
      let oraclePriceuAD = await twapOracle.consult(uAD.address);
      let oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);
      expect(oraclePriceuAD).to.equal(ethers.utils.parseEther("1"));
      expect(oraclePrice3Crv).to.equal(ethers.utils.parseEther("1"));
      // Exchange (swap) uAD => 3CRV
      const dyuADto3CRV = await swapUADto3CRV(metaPool, uAD, ethers.utils.parseEther("1"), secondAccount);

      const secondAccount3CRVBalanceAfterSwap = await crvToken.balanceOf(await secondAccount.getAddress());
      await twapOracle.update();
      oraclePriceuAD = await twapOracle.consult(uAD.address);
      oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);
      // we now have more uAD than 3CRV wich means that uAD is worth less than 3CRV
      expect(oraclePriceuAD).to.be.lt(ethers.utils.parseEther("1"));
      expect(oraclePrice3Crv).to.be.gt(ethers.utils.parseEther("1"));
      const pool0balAfter = await metaPool.balances(0);
      const pool1balAfter = await metaPool.balances(1);
      const balancesAfter = await curvePoolFactory.get_balances(metaPool.address);
      expect(pool0balAfter).to.equal(pool0balBefore.add(ethers.utils.parseEther("1")));

      // we now have less 3CRV
      expect(pool1balBefore.sub(pool1balAfter)).to.be.gt(0);
      const adminFee = await curvePoolFactory.get_admin_balances(metaPool.address);

      // in the basepool 3CRV we should be short the dai amount transfered to the user + admin fees (50% of trade fee)
      // for exchanges the fee is taken in the output currency and calculated against the final amount received.
      expect(pool1balAfter).to.equal(pool1balBefore.sub(dyuADto3CRV.add(adminFee[1])));
      // second account DAI Balance should be equal to the estimate swap amount
      expect(secondAccount3CRVBalanceAfterSwap).to.be.equal(dyuADto3CRV);
      // pool1Blance should be less than before the swap
      expect(pool1balBefore.sub(pool1balAfter)).to.be.gt(0);
      // uAD balance in the pool should be equal to before + 1
      expect(balancesAfter[0].sub(balancesBefore[0])).to.equal(ethers.utils.parseEther("1"));
      // 3CRV balance in the pool should be less than before the swap
      expect(balancesBefore[1].sub(balancesAfter[1])).to.be.gt(0);

      // we should have positive fee in 3CRV
      expect(adminFee[1]).to.be.gt(0);

      await twapOracle.update();
      const oraclePriceuADAfter = await twapOracle.consult(uAD.address);
      expect(oraclePriceuADAfter).to.be.lt(ethers.utils.parseEther("1"));
      // if no swap after x block the price stays the same
      const LastBlockTimestamp = await metaPool.block_timestamp_last();
      const blockTimestamp = LastBlockTimestamp.toNumber() + 23 * 3600;
      await mineBlock(blockTimestamp);
      await twapOracle.update();
      const oraclePriceAfterMine = await twapOracle.consult(uAD.address);
      expect(oraclePriceuADAfter.sub(oraclePriceAfterMine)).to.equal(0);
    });
    it("should return correct price after a swap for underlying token", async () => {
      const pool0balBefore = await metaPool.balances(0);
      const pool1balBefore = await metaPool.balances(1);
      expect(pool0balBefore).to.equal(ethers.utils.parseEther("10000"));
      expect(pool1balBefore).to.equal(ethers.utils.parseEther("10000"));
      const balancesBefore = await curvePoolFactory.get_underlying_balances(metaPool.address);
      let oraclePriceuAD = await twapOracle.consult(uAD.address);
      let oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);
      expect(oraclePriceuAD).to.equal(ethers.utils.parseEther("1"));
      expect(oraclePrice3Crv).to.equal(ethers.utils.parseEther("1"));
      // Exchange (swap)
      const dyuADtoDAI = await swapUADtoDAI(metaPool, uAD, ethers.utils.parseEther("1"), secondAccount);
      const secondAccountDAIBalanceAfterSwap = await daiToken.balanceOf(await secondAccount.getAddress());
      await twapOracle.update();
      oraclePriceuAD = await twapOracle.consult(uAD.address);
      oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);
      // we now have more uAD than 3CRV wich means that uAD is worth less than 3CRV
      expect(oraclePriceuAD).to.be.lt(ethers.utils.parseEther("1"));
      expect(oraclePrice3Crv).to.be.gt(ethers.utils.parseEther("1"));
      const pool0balAfter = await metaPool.balances(0);
      const pool1balAfter = await metaPool.balances(1);
      const balancesAfter = await curvePoolFactory.get_underlying_balances(metaPool.address);
      expect(pool0balAfter).to.equal(pool0balBefore.add(ethers.utils.parseEther("1")));
      // we now have less 3CRV
      expect(pool1balBefore.sub(pool1balAfter)).to.be.gt(1);
      const adminFee = await curvePoolFactory.get_admin_balances(metaPool.address);

      // second account DAI Balance should be equal to the estimate swap amount
      expect(secondAccountDAIBalanceAfterSwap).to.be.equal(dyuADtoDAI);
      // pool1Blance should be less than before the swap
      expect(pool1balBefore.sub(pool1balAfter)).to.be.gt(0);
      // uAD balance in the pool should be equal to before + 1
      expect(balancesAfter[0].sub(balancesBefore[0])).to.equal(ethers.utils.parseEther("1"));
      // Dai balance in the pool should be less than before the swap
      expect(balancesBefore[1].sub(balancesAfter[1])).to.be.gt(0);
      // USDC balance in the pool should be less than before the swap
      expect(balancesBefore[2].sub(balancesAfter[2])).to.be.gt(0);
      // USDT balance in the pool should be less than before the swap
      expect(balancesBefore[3].sub(balancesAfter[3])).to.be.gt(0);
      // we should have positive fee in 3CRV
      expect(adminFee[1]).to.be.gt(0);

      await twapOracle.update();
      const oraclePriceuADAfter = await twapOracle.consult(uAD.address);
      expect(oraclePriceuADAfter).to.be.lt(ethers.utils.parseEther("1"));
      // if no swap after x block the price stays the same
      const LastBlockTimestamp = await metaPool.block_timestamp_last();
      const blockTimestamp = LastBlockTimestamp.toNumber() + 23 * 3600;
      await mineBlock(blockTimestamp);
      await twapOracle.update();
      const oraclePriceAfterMine = await twapOracle.consult(uAD.address);
      expect(oraclePriceuADAfter.sub(oraclePriceAfterMine)).to.equal(0);
    });
  });
});
