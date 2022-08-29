import { expect } from "chai";
import { Signer, BigNumber, ethers } from "ethers";
import { BondingShare } from "../artifacts/types/BondingShare";
import { bondingSetup, deposit } from "./BondingSetup";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { Bonding } from "../artifacts/types/Bonding";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { ERC20 } from "../artifacts/types/ERC20";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { swapToUpdateOracle } from "./utils/swap";

describe("Bonding.Price.Reset", () => {
  const one: BigNumber = BigNumber.from(10).pow(18);
  let admin: Signer;
  let secondAccount: Signer;
  let treasury: Signer;
  let secondAddress: string;
  let bondingShare: BondingShare;
  let uAD: UbiquityAlgorithmicDollar;
  let bonding: Bonding;
  let metaPool: IMetaPool;
  let crvToken: ERC20;
  let twapOracle: TWAPOracle;
  beforeEach(async () => {
    ({ admin, secondAccount, bondingShare, bonding, metaPool, uAD, treasury, crvToken, twapOracle } = await bondingSetup());
    secondAddress = await secondAccount.getAddress();
  });

  it("for uAD should work and push uAD price higher", async () => {
    const bondingUADBalanceBefore = await uAD.balanceOf(bonding.address);
    const pool0bal0 = await metaPool.balances(0);
    const pool1bal0 = await metaPool.balances(1);
    expect(pool0bal0).to.equal(ethers.utils.parseEther("10000"));
    expect(pool1bal0).to.equal(ethers.utils.parseEther("10000"));

    const amountOf3CRVforOneUADBefore = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
    // deposit 100 uLP more tokens in addition to the 100 already in the bonding contract
    const idSecond = (await deposit(secondAccount, one.mul(100), 1)).id;
    const bondBefore = await bondingShare.balanceOf(secondAddress, idSecond);
    const bondingSCBalance = await metaPool.balanceOf(bonding.address);

    // value in LP of a bonding share
    const shareValueBefore = await bonding.currentShareValue();
    const bondingShareTotalSupply = await bondingShare.totalSupply();
    // amount of uAD inside the treasury
    const treasuryAdr = await treasury.getAddress();
    const treasuryUADBalanceBeforeReset = await uAD.balanceOf(treasuryAdr);
    //  priceBOND = totalLP / totalShares * TARGET_PRICE
    const calculatedShareValue = bondingSCBalance.mul(one).div(bondingShareTotalSupply);
    expect(shareValueBefore).to.equal(calculatedShareValue);
    const amountToTreasury = ethers.utils.parseEther("199.709062633936701658");

    await expect(bonding.uADPriceReset(bondingSCBalance)).to.emit(uAD, "Transfer").withArgs(bonding.address, treasuryAdr, amountToTreasury);

    const treasuryUADBalanceAfterReset = await uAD.balanceOf(treasuryAdr);
    expect(treasuryUADBalanceAfterReset).to.equal(treasuryUADBalanceBeforeReset.add(amountToTreasury));

    const bondAfter = await bondingShare.balanceOf(secondAddress, idSecond);
    // bonding share should remain the same
    expect(bondBefore).to.equal(bondAfter);
    // amount of curve LP to be withdrawn should be less
    const shareValueAfter = await bonding.currentShareValue();

    const bondingSCBalanceAfter = await metaPool.balanceOf(bonding.address);
    expect(bondingSCBalanceAfter).to.equal(0);
    expect(shareValueAfter).to.equal(0);
    const bondingUADBalanceAfter = await uAD.balanceOf(bonding.address);
    const oraclePrice = await twapOracle.consult(uAD.address);
    const amountOf3CRVforOneUADAfter = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
    // price of uAD against 3CRV should be less than before
    // meaning for a uAD you can have more 3CRV
    expect(amountOf3CRVforOneUADAfter).to.be.gt(amountOf3CRVforOneUADBefore);
    const oracleCRVPrice = await twapOracle.consult(crvToken.address);

    const pool0bal = await metaPool.balances(0);
    const pool1bal = await metaPool.balances(1);
    expect(bondingUADBalanceBefore).to.equal(0);
    expect(bondingUADBalanceAfter).to.equal(0);
    expect(pool0bal).to.equal(ethers.utils.parseEther("9800.270823277548456538"));
    expect(pool1bal).to.equal(ethers.utils.parseEther("10000"));
    await swapToUpdateOracle(metaPool, crvToken, uAD, admin);

    await twapOracle.update();
    const oraclePriceLatest = await twapOracle.consult(uAD.address);
    const oracleCRVPriceLatest = await twapOracle.consult(crvToken.address);
    // After update the TWAP price of uAD against 3CRV should be greater than before
    // the price of 3CRV against  price of uAD should be lower than before
    expect(oraclePriceLatest).to.be.gt(oraclePrice);
    expect(oracleCRVPriceLatest).to.be.lt(oracleCRVPrice);
  });
  it("for 3CRV should work and push uAD price lower", async () => {
    const bondingUADBalanceBefore = await uAD.balanceOf(bonding.address);
    const pool0bal0 = await metaPool.balances(0);
    const pool1bal0 = await metaPool.balances(1);
    expect(pool0bal0).to.equal(ethers.utils.parseEther("10000"));
    expect(pool1bal0).to.equal(ethers.utils.parseEther("10000"));

    const amountOf3CRVforOneUADBefore = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
    // deposit 100 uLP more tokens in addition to the 100 already in the bonding contract
    const idSecond = (await deposit(secondAccount, one.mul(100), 1)).id;
    const bondBefore = await bondingShare.balanceOf(secondAddress, idSecond);
    const bondingSCBalance = await metaPool.balanceOf(bonding.address);
    // value in LP of a bonding share
    const shareValueBefore = await bonding.currentShareValue();
    const bondingShareTotalSupply = await bondingShare.totalSupply();
    // amount of 3crv inside the treasury
    const treasuryAdr = await treasury.getAddress();
    const treasury3CRVBalanceBeforeReset = await crvToken.balanceOf(treasuryAdr);
    //  priceBOND = totalLP / totalShares * TARGET_PRICE
    const calculatedShareValue = bondingSCBalance.mul(one).div(bondingShareTotalSupply);
    expect(shareValueBefore).to.equal(calculatedShareValue);
    const amountToTreasury = ethers.utils.parseEther("196.586734740380915533");
    await expect(bonding.crvPriceReset(bondingSCBalance)).to.emit(crvToken, "Transfer").withArgs(bonding.address, treasuryAdr, amountToTreasury);
    const treasury3CRVBalanceAfterReset = await crvToken.balanceOf(treasuryAdr);
    expect(treasury3CRVBalanceAfterReset).to.equal(treasury3CRVBalanceBeforeReset.add(amountToTreasury));
    const bondAfter = await bondingShare.balanceOf(secondAddress, idSecond);
    // bonding share should remain the same
    expect(bondBefore).to.equal(bondAfter);
    // amount of curve LP to be withdrawn should be less
    const shareValueAfter = await bonding.currentShareValue();

    const bondingSCBalanceAfter = await metaPool.balanceOf(bonding.address);
    expect(bondingSCBalanceAfter).to.equal(0);
    expect(shareValueAfter).to.equal(0);
    const bondingUADBalanceAfter = await uAD.balanceOf(bonding.address);

    const oraclePrice = await twapOracle.consult(uAD.address);
    const amountOf3CRVforOneUADAfter = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
    const oracleCRVPrice = await twapOracle.consult(crvToken.address);
    // price of uAD against 3CRV should be lower than before
    // meaning for a uAD you can have less  3CRV
    expect(amountOf3CRVforOneUADAfter).to.be.lt(amountOf3CRVforOneUADBefore);
    const pool0bal = await metaPool.balances(0);
    const pool1bal = await metaPool.balances(1);
    expect(bondingUADBalanceBefore).to.equal(0);
    expect(bondingUADBalanceAfter).to.equal(0);
    expect(pool1bal).to.equal(ethers.utils.parseEther("9803.393775449769704549"));
    expect(pool0bal).to.equal(ethers.utils.parseEther("10000"));
    await swapToUpdateOracle(metaPool, crvToken, uAD, admin);

    await twapOracle.update();
    const oraclePriceLatest = await twapOracle.consult(uAD.address);
    const oracleCRVPriceLatest = await twapOracle.consult(crvToken.address);
    // After update the TWAP price of uAD against 3CRV should be lower than before
    // the price of 3CRV against  price of uAD should be greater than before
    expect(oraclePriceLatest).to.be.lt(oraclePrice);
    expect(oracleCRVPriceLatest).to.be.gt(oracleCRVPrice);
  });

  it("for uAD should revert if not admin", async () => {
    const bondingSCBalance = await metaPool.balanceOf(bonding.address);
    await expect(bonding.connect(secondAccount).uADPriceReset(bondingSCBalance)).to.be.revertedWith("Caller is not a bonding manager");
  });
  it("for 3CRV should revert if not admin", async () => {
    const bondingSCBalance = await metaPool.balanceOf(bonding.address);
    await expect(bonding.connect(secondAccount).crvPriceReset(bondingSCBalance)).to.be.revertedWith("Caller is not a bonding manager");
  });
});
