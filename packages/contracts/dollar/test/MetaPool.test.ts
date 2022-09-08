import { ContractTransaction, Signer } from "ethers";
import { ethers, getNamedAccounts, network } from "hardhat";
import { describe, it } from "mocha";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { expect } from "./setup";
import { resetFork } from "./utils/hardhatNode";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { ERC20 } from "../artifacts/types/ERC20";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { ICurveFactory } from "../artifacts/types/ICurveFactory";
import { swapDAItoUAD, swapUADto3CRV, swapUADtoDAI } from "./utils/swap";

describe("MetaPool", () => {
  let metaPool: IMetaPool;
  let manager: UbiquityAlgorithmicDollarManager;
  let admin: Signer;
  let secondAccount: Signer;
  let daiToken: ERC20;
  let uAD: UbiquityAlgorithmicDollar;
  let DAI: string;
  let USDC: string;
  let USDT: string;
  let curvePoolFactory: ICurveFactory;
  let curveFactory: string;
  let curve3CrvBasePool: string;
  let curve3CrvToken: string;
  let crvToken: ERC20;
  let curveWhaleAddress: string;
  let daiWhaleAddress: string;
  let curveWhale: Signer;
  let twapOracle: TWAPOracle;

  beforeEach(async () => {
    ({ DAI, USDC, USDT, curveFactory, curve3CrvBasePool, curve3CrvToken, curveWhaleAddress, daiWhaleAddress } = await getNamedAccounts());
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
  describe("MetaPool", () => {
    it("should perform an exchange between DAI to UAD ", async () => {
      await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [daiWhaleAddress],
      });
      const daiWhale = ethers.provider.getSigner(daiWhaleAddress);
      const secondAccountAdr = await secondAccount.getAddress();
      const amountToSwap = ethers.utils.parseEther("10000");
      await daiToken.connect(daiWhale).transfer(secondAccountAdr, amountToSwap);

      // Performs an exchange between two tokens.
      const uAD2ndBalbeforeSWAP = await uAD.balanceOf(secondAccountAdr);
      const secondAccountDAIBalanceBefore = await daiToken.balanceOf(secondAccountAdr);
      // Exchange (swap) DAI to UAD
      const dyUAD = await swapDAItoUAD(metaPool, daiToken, amountToSwap, secondAccount);

      const secondAccountDAIBalanceAfter = await daiToken.balanceOf(secondAccountAdr);
      const secondAccountuADBalanceAfter = await uAD.balanceOf(secondAccountAdr);
      expect(secondAccountDAIBalanceAfter).to.equal(secondAccountDAIBalanceBefore.sub(amountToSwap));
      const expectedUAD = uAD2ndBalbeforeSWAP.add(dyUAD);

      // assert expected presision

      expect(secondAccountuADBalanceAfter).to.be.lte(expectedUAD);
      expect(secondAccountuADBalanceAfter).to.be.gte(expectedUAD.mul(9999).div(10000));
    });
    it("should perform an exchange between uAD and DAI", async () => {
      // Performs an exchange between two tokens.
      const uAD2ndBalbeforeSWAP = await uAD.balanceOf(await secondAccount.getAddress());

      // Exchange (swap)
      const dyuADtoDAI = await swapUADtoDAI(metaPool, uAD, ethers.utils.parseEther("1"), secondAccount);
      const secondAccountDAIBalance = await daiToken.balanceOf(await secondAccount.getAddress());
      const secondAccountuADBalance = await uAD.balanceOf(await secondAccount.getAddress());
      expect(secondAccountDAIBalance).to.equal(dyuADtoDAI);
      expect(secondAccountuADBalance).to.equal(uAD2ndBalbeforeSWAP.sub(ethers.utils.parseEther("1")));
    });
    it("should perform an exchange between uAD and 3CRV", async () => {
      // Performs an exchange between two tokens.
      const uAD2ndBalbeforeSWAP = await uAD.balanceOf(await secondAccount.getAddress());

      // Exchange (swap)
      const dyuADto3CRV = await swapUADto3CRV(metaPool, uAD, ethers.utils.parseEther("1"), secondAccount);

      const secondAccount3CRVBalance = await crvToken.balanceOf(await secondAccount.getAddress());
      const secondAccountuADBalance = await uAD.balanceOf(await secondAccount.getAddress());
      expect(secondAccount3CRVBalance).to.equal(dyuADto3CRV);
      expect(secondAccountuADBalance).to.equal(uAD2ndBalbeforeSWAP.sub(ethers.utils.parseEther("1")));
    });
    it("should return correct name", async () => {
      const name = await metaPool.name();
      expect(name).to.equal("Curve.fi Factory USD Metapool: Ubiquity Algorithmic Dollar");
      const symbol = await metaPool.symbol();
      expect(symbol).to.equal("uAD3CRV-f");
    });
    it("should return correct pool balance", async () => {
      const pool0bal = await metaPool.balances(0);
      const pool1bal = await metaPool.balances(1);
      expect(pool0bal).to.equal(ethers.utils.parseEther("10000"));
      expect(pool1bal).to.equal(ethers.utils.parseEther("10000"));
    });
    it("should return correct token price", async () => {
      await twapOracle.update();

      const dyuADto3CRV = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
      expect(dyuADto3CRV).to.equal("983945512295267596");
    });
    it("should return correct underlying token price", async () => {
      const dyuAD2USDT = await metaPool["get_dy_underlying(int128,int128,uint256)"](0, 3, ethers.utils.parseEther("1"));
      expect(dyuAD2USDT).to.equal("1001098");
      const dyDAI2USDT = await metaPool["get_dy_underlying(int128,int128,uint256)"](1, 3, ethers.utils.parseEther("1"));
      expect(dyDAI2USDT).to.equal("1000623");
      const dyuAD2DAI = await metaPool["get_dy_underlying(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
      expect(dyuAD2DAI).to.equal("1000011060260788055");
      const dyDAI2uAD = await metaPool["get_dy_underlying(int128,int128,uint256)"](1, 0, ethers.utils.parseEther("1"));
      expect(dyDAI2uAD).to.equal("998714251903486448");
    });
    it("deposit liquidity with only uAD should decrease its price", async () => {
      const dyuAD2USDT = await metaPool["get_dy_underlying(int128,int128,uint256)"](0, 3, ethers.utils.parseEther("1"));
      expect(dyuAD2USDT).to.equal("1001098");
      const dyuAD2CRV = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));

      const uAD2ndBalbeforeAddLiquidity = await uAD.balanceOf(await secondAccount.getAddress());
      const LP2ndBalbeforeAddLiquidity = await metaPool.balanceOf(await secondAccount.getAddress());
      // secondAccount need to approve metaPool for sending its uAD
      await uAD.connect(secondAccount).approve(metaPool.address, ethers.utils.parseEther("1"));

      const dyuAD2LP = await metaPool["calc_token_amount(uint256[2],bool)"]([ethers.utils.parseEther("1"), 0], true);
      await metaPool.connect(secondAccount)["add_liquidity(uint256[2],uint256)"]([ethers.utils.parseEther("1"), 0], dyuAD2LP.mul(99).div(100));
      const uAD2ndBalAfterAddLiquidity = await uAD.balanceOf(await secondAccount.getAddress());
      const LP2ndBalAfterAddLiquidity = await metaPool.balanceOf(await secondAccount.getAddress());

      expect(LP2ndBalAfterAddLiquidity).to.be.gt(LP2ndBalbeforeAddLiquidity);
      // it is less because calc_token_amount accounts for slippage, but not fees.
      // It should not be considered to be precise!
      expect(LP2ndBalAfterAddLiquidity).to.be.lt(LP2ndBalbeforeAddLiquidity.add(dyuAD2LP));
      expect(uAD2ndBalAfterAddLiquidity).to.equal(uAD2ndBalbeforeAddLiquidity.sub(ethers.utils.parseEther("1")));
      const dyuAD2USDTAfter = await metaPool["get_dy_underlying(int128,int128,uint256)"](0, 3, ethers.utils.parseEther("1"));
      expect(dyuAD2USDTAfter).to.be.lt(dyuAD2USDT);
      const dyuAD2CRVAfter = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
      expect(dyuAD2CRVAfter).to.be.lt(dyuAD2CRV);
    });
    it("remove liquidity should provide both tokens", async () => {
      const balanceLPAdminBefore = await metaPool.balanceOf(await admin.getAddress());
      const balanceuADAdminBefore = await uAD.balanceOf(await admin.getAddress());
      const balance3CRVAdminBefore = await crvToken.balanceOf(await admin.getAddress());
      const amount = ethers.utils.parseEther("500");
      const priceUADBefore = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));

      const dyLPtokenToBurn = await metaPool["calc_token_amount(uint256[2],bool)"]([amount, amount], false);

      await metaPool["remove_liquidity(uint256,uint256[2])"](dyLPtokenToBurn, [amount, amount]);
      const balanceLPAdminAfter = await metaPool.balanceOf(await admin.getAddress());
      const balanceuADAdminAfter = await uAD.balanceOf(await admin.getAddress());
      const balance3CRVAdminAfter = await crvToken.balanceOf(await admin.getAddress());
      const priceUADAfter = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
      expect(priceUADAfter).to.be.lt(priceUADBefore);
      expect(balanceLPAdminAfter).to.be.lt(balanceLPAdminBefore);
      expect(balanceuADAdminAfter).to.be.gt(balanceuADAdminBefore);
      expect(balance3CRVAdminAfter).to.be.gt(balance3CRVAdminBefore);
    });
    it("remove liquidity with only uAD should increase uAD price", async () => {
      const balanceLPAdminBefore = await metaPool.balanceOf(await admin.getAddress());
      const balanceuADAdminBefore = await uAD.balanceOf(await admin.getAddress());
      const balance3CRVAdminBefore = await crvToken.balanceOf(await admin.getAddress());
      const amount = ethers.utils.parseEther("1000");
      const priceUADBefore = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));

      const dyuAD = await metaPool["calc_withdraw_one_coin(uint256,int128)"](amount, 0);

      await metaPool["remove_liquidity_one_coin(uint256,int128,uint256)"](amount, 0, dyuAD.mul(99).div(100));
      const balanceLPAdminAfter = await metaPool.balanceOf(await admin.getAddress());
      const balanceuADAdminAfter = await uAD.balanceOf(await admin.getAddress());
      const balance3CRVAdminAfter = await crvToken.balanceOf(await admin.getAddress());
      const priceUADAfter = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
      expect(priceUADAfter).to.be.gt(priceUADBefore);
      expect(balanceLPAdminAfter).to.be.lt(balanceLPAdminBefore);
      expect(balanceuADAdminAfter).to.be.gt(balanceuADAdminBefore);
      expect(balance3CRVAdminAfter).to.equal(balance3CRVAdminBefore);
    });
  });
  describe("CurvePoolFactory", () => {
    it("should return correct number of coins and underlying coins within a pool", async () => {
      // Get the number of coins and underlying coins within a pool.
      const nCoins = await curvePoolFactory.get_n_coins(metaPool.address);
      expect(nCoins[0]).to.equal(2);
      expect(nCoins[1]).to.equal(4);
    });
    it("should return a list of the swappable coins within a pool", async () => {
      // Get a list of the swappable coins within a pool.
      const coins = await curvePoolFactory.get_coins(metaPool.address);
      expect(coins[0].toString()).to.equal(uAD.address);
      expect(coins[1].toString()).to.equal(curve3CrvToken);
    });
    it("should return a list of the swappable underlying coins within a pool", async () => {
      // Get a list of the swappable underlying coins within a pool.
      const underCoins = await curvePoolFactory.get_underlying_coins(metaPool.address);
      expect(underCoins[0].toString()).to.equal(uAD.address);
      expect(underCoins[1].toString()).to.equal(DAI);
      expect(underCoins[2].toString()).to.equal(USDC);
      expect(underCoins[3].toString()).to.equal(USDT);
    });
    it("should a list of decimal places for each coin within a pool.", async () => {
      // Get a list of decimal places for each coin within a pool.
      const decimalCoins = await curvePoolFactory.get_underlying_decimals(metaPool.address);
      expect(decimalCoins[0]).to.equal(18);
      expect(decimalCoins[1]).to.equal(18);
      expect(decimalCoins[2]).to.equal(6);
      expect(decimalCoins[3]).to.equal(6);
    });
    it("should convert coin addresses into indices for use with pool methods.", async () => {
      // Convert coin addresses into indices for use with pool methods.
      const indices = await curvePoolFactory.get_coin_indices(metaPool.address, DAI, USDT);
      expect(indices[2]).to.be.true;
      expect(indices[0]).to.equal(1);
      expect(indices[1]).to.equal(3);
    });
    it("should get available balances for each underlying coin within a pool.", async () => {
      // Get available balances for each coin within a pool.
      const balances = await curvePoolFactory.get_underlying_balances(metaPool.address);
      expect(balances[0]).to.equal(ethers.utils.parseEther("10000"));
      expect(balances[1]).to.equal("1448133382413680542224");
      expect(balances[2]).to.equal("5103950291");
      expect(balances[3]).to.equal("3623739270");
    });
    it("should get the exchange rates between coins and underlying coins within a pool.", async () => {
      // Get the exchange rates between coins and underlying coins within a pool, normalized to a 1e18 precision.
      const rates = await curvePoolFactory.get_rates(metaPool.address);
      expect(rates[0]).to.equal(ethers.utils.parseEther("1"));
      expect(rates[1]).to.equal(ethers.utils.parseEther("1.017504843248071274"));
    });
    it("should get virtual price.", async () => {
      // Getter virtual price.
      const virtPrice = await metaPool.get_virtual_price();
      expect(virtPrice).to.equal(ethers.utils.parseEther("1"));
    });
  });
});
