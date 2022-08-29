import { expect } from "chai";
import { ethers, Signer, BigNumber } from "ethers";
import { BondingV2 } from "../artifacts/types/BondingV2";
import { BondingShareV2 } from "../artifacts/types/BondingShareV2";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { latestBlockNumber, mineNBlock } from "./utils/hardhatNode";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { ERC20 } from "../artifacts/types/ERC20";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { bondingSetupV2, deposit } from "./BondingSetupV2";
import { swapToUpdateOracle } from "./utils/swap";
import { MasterChefV2 } from "../artifacts/types/MasterChefV2";
import { BondingFormulas } from "../artifacts/types/BondingFormulas";
import { isAmountEquivalent } from "./utils/calc";

describe("bondingV2 price reset", () => {
  const one: BigNumber = BigNumber.from(10).pow(18); // one = 1 ether = 10^18
  let admin: Signer;
  let secondAccount: Signer;
  let fourthAccount: Signer;
  let bondingMaxAccount: Signer;
  let bondingMinAccount: Signer;
  let treasury: Signer;
  let secondAddress: string;
  let uAD: UbiquityAlgorithmicDollar;
  let metaPool: IMetaPool;
  let crvToken: ERC20;
  let twapOracle: TWAPOracle;
  let bondingV2: BondingV2;
  let bondingShareV2: BondingShareV2;
  let masterChefV2: MasterChefV2;
  let bondingFormulas: BondingFormulas;
  let bondMinId: ethers.BigNumber;
  let bondMaxId: ethers.BigNumber;
  let bondMin: {
    minter: string;
    lpFirstDeposited: BigNumber;
    creationBlock: BigNumber;
    lpRewardDebt: BigNumber;
    endBlock: BigNumber;
    lpAmount: BigNumber;
  };
  let bondMax: {
    minter: string;
    lpFirstDeposited: BigNumber;
    creationBlock: BigNumber;
    lpRewardDebt: BigNumber;
    endBlock: BigNumber;
    lpAmount: BigNumber;
  };
  beforeEach(async () => {
    ({
      secondAccount,
      fourthAccount,
      bondingMaxAccount,
      bondingMinAccount,
      uAD,
      admin,
      metaPool,
      bondingV2,
      crvToken,
      bondingShareV2,
      masterChefV2,
      twapOracle,
      bondingFormulas,
      treasury,
    } = await bondingSetupV2());
    secondAddress = await secondAccount.getAddress();
    // handle migration and remove liquidity because it is not the intend to test it here
    await bondingV2.connect(bondingMinAccount).migrate();
    const idsMin = await bondingShareV2.holderTokens(await bondingMinAccount.getAddress());
    [bondMinId] = idsMin;
    bondMin = await bondingShareV2.getBond(bondMinId);

    await bondingV2.connect(bondingMaxAccount).migrate();
    const idsMax = await bondingShareV2.holderTokens(await bondingMaxAccount.getAddress());
    [bondMaxId] = idsMax;
    bondMax = await bondingShareV2.getBond(bondMaxId);
  });
  it("onlyBondingManager can call uADPriceReset", async () => {
    await expect(bondingV2.connect(secondAccount).uADPriceReset(1)).to.be.revertedWith("not manager");
  });
  it("onlyBondingManager can call crvPriceReset", async () => {
    await expect(bondingV2.connect(secondAccount).crvPriceReset(1)).to.be.revertedWith("not manager");
  });
  it("crvPriceReset should work", async () => {
    const bondingUADBalanceBefore = await uAD.balanceOf(bondingV2.address);
    const pool0bal0 = await metaPool.balances(0);
    const pool1bal0 = await metaPool.balances(1);
    expect(pool0bal0).to.equal(ethers.utils.parseEther("10300"));
    expect(pool1bal0).to.equal(ethers.utils.parseEther("10300"));

    const amountOf3CRVforOneUADBefore = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
    // remove the pending rewards
    const treasuryAdr = await treasury.getAddress();
    // only leave 4.2 eth as lp rewards
    const firstLPRewards = ethers.utils.parseEther("4.2");
    await metaPool.connect(admin).transfer(bondingV2.address, firstLPRewards);
    const amountOfLpDeposited = one.mul(100);
    // deposit 100 uLP more tokens in addition to the 403.4995 already in the bonding contract
    const idSecond = (await deposit(secondAccount, amountOfLpDeposited, 1)).id;
    const bondBefore = await bondingShareV2.balanceOf(secondAddress, idSecond);
    const totalBondingLPDeposited = await bondingShareV2.totalLP();
    // value in LP of a bonding share
    const shareValueBefore = await bondingV2.currentShareValue();
    const sharesTotalSupply = await masterChefV2.totalShares();
    // amount of 3crv inside the treasury

    const treasury3CRVBalanceBeforeReset = await crvToken.balanceOf(treasuryAdr);
    //  priceBOND = totalLP / totalShares * TARGET_PRICE
    const calculatedShareValue = totalBondingLPDeposited.mul(one).div(sharesTotalSupply);
    expect(shareValueBefore).to.equal(calculatedShareValue);

    const amountOf3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](totalBondingLPDeposited, 1);

    const bondingSCBalanceBefore = await metaPool.balanceOf(bondingV2.address);
    await expect(bondingV2.crvPriceReset(totalBondingLPDeposited))
      .to.emit(crvToken, "Transfer")
      .withArgs(bondingV2.address, treasuryAdr, amountOf3CRV)
      .and.to.emit(bondingV2, "PriceReset")
      .withArgs(crvToken.address, amountOf3CRV, amountOf3CRV);
    const treasury3CRVBalanceAfterReset = await crvToken.balanceOf(treasuryAdr);
    expect(treasury3CRVBalanceAfterReset).to.equal(treasury3CRVBalanceBeforeReset.add(amountOf3CRV));
    const bondAfter = await bondingShareV2.balanceOf(secondAddress, idSecond);
    // bonding share should remain the same
    expect(bondBefore).to.equal(bondAfter);
    // amount of curve LP to be withdrawn should be less
    const shareValueAfter = await bondingV2.currentShareValue();

    const bondingSCBalanceAfter = await metaPool.balanceOf(bondingV2.address);

    expect(bondingSCBalanceAfter).to.equal(bondingSCBalanceBefore.sub(totalBondingLPDeposited));
    // share value is the same
    expect(shareValueAfter).to.equal(shareValueBefore);
    const bondingUADBalanceAfter = await uAD.balanceOf(bondingV2.address);
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
    expect(pool1bal).to.be.lt(pool1bal0.sub(amountOf3CRV));
    expect(pool0bal).to.equal(pool0bal0);
    await swapToUpdateOracle(metaPool, crvToken, uAD, admin);
    await twapOracle.update();
    const oraclePriceLatest = await twapOracle.consult(uAD.address);
    const oracleCRVPriceLatest = await twapOracle.consult(crvToken.address);
    // After update the TWAP price of uAD against 3CRV should be lower than before
    // the price of 3CRV against  price of uAD should be greater than before
    expect(oraclePriceLatest).to.be.lt(oraclePrice);
    expect(oracleCRVPriceLatest).to.be.gt(oracleCRVPrice);
    // user can't withdraw all his deposited LP token because of the price reset
    const lastBlockNum = await latestBlockNumber();
    const bond = await bondingShareV2.getBond(idSecond);
    const endOfLockingInBlock = bond.endBlock.toNumber() - lastBlockNum.number;
    await mineNBlock(endOfLockingInBlock);
    const bs = await masterChefV2.getBondingShareInfo(idSecond);

    await metaPool.connect(admin).transfer(bondingV2.address, ethers.utils.parseEther("10"));
    const bondingSCBalanceNew = await metaPool.balanceOf(bondingV2.address);
    let amountToWithdraw = bond.lpAmount.div(2);
    const sharesToRemove = await bondingFormulas.sharesForLP(bond, bs, amountToWithdraw);
    const pendingLpRewards = await bondingV2.pendingLpRewards(idSecond);
    // there is still less LP on bonding than the total LP deposited
    expect(pendingLpRewards).to.equal(0);

    const lpRewards = await bondingV2.lpRewards();
    const correctedAmount = amountToWithdraw.mul(bondingSCBalanceNew.sub(lpRewards)).div(totalBondingLPDeposited);

    const secondAccbalanceBeforeRemove = await metaPool.balanceOf(secondAddress);

    const accLpRewardPerShareBeforeLQTYRemove = await bondingV2.accLpRewardPerShare();
    await expect(bondingV2.connect(secondAccount).removeLiquidity(amountToWithdraw, idSecond))
      .to.emit(bondingV2, "RemoveLiquidityFromBond")
      .withArgs(secondAddress, idSecond, amountToWithdraw, correctedAmount, pendingLpRewards, sharesToRemove)
      .and.to.emit(metaPool, "Transfer")
      .withArgs(bondingV2.address, secondAddress, correctedAmount.add(pendingLpRewards));
    // user gets the corrected amount of LP
    const secondAccbalanceAfterRemove = await metaPool.balanceOf(secondAddress);
    expect(correctedAmount).to.be.lt(amountOfLpDeposited);
    expect(secondAccbalanceAfterRemove).to.equal(secondAccbalanceBeforeRemove.add(correctedAmount));
    const bsAfter = await masterChefV2.getBondingShareInfo(idSecond);
    const pendingLpRewardsAfterRemove = await bondingV2.pendingLpRewards(idSecond);
    expect(pendingLpRewardsAfterRemove).to.equal(0);
    // user looses the bonding shares corresponding to the amount asked for withdrawal
    expect(bsAfter[0]).to.equal(bs[0].sub(sharesToRemove));
    // bonding share is updated accordingly
    const bondAfterRemoveLQTY = await bondingShareV2.getBond(idSecond);
    expect(bondAfterRemoveLQTY.lpAmount).to.equal(bond.lpAmount.sub(amountToWithdraw));
    expect(bondAfterRemoveLQTY.minter).to.equal(bond.minter);

    expect(bondAfterRemoveLQTY.lpFirstDeposited).to.equal(bond.lpFirstDeposited);
    expect(bondAfterRemoveLQTY.creationBlock).to.equal(bond.creationBlock);
    expect(bondAfterRemoveLQTY.endBlock).to.equal(bond.endBlock);
    const accLpRewardPerShareAfterLQTYRemove = await bondingV2.accLpRewardPerShare();
    expect(accLpRewardPerShareAfterLQTYRemove).to.equal(accLpRewardPerShareBeforeLQTYRemove);
    const lpRewardDebtAfterLQTYRemove = bsAfter[0].mul(accLpRewardPerShareAfterLQTYRemove).div(BigNumber.from(1e12));
    expect(bondAfterRemoveLQTY.lpRewardDebt).to.equal(lpRewardDebtAfterLQTYRemove);
    expect(bondAfterRemoveLQTY.lpRewardDebt).to.be.lt(bond.lpRewardDebt);

    //  make sure that if LP are back on the bonding contract user can access rewards and its LP

    amountToWithdraw = bondAfterRemoveLQTY.lpAmount.div(5);
    const totLP = await bondingShareV2.totalLP();
    await metaPool.connect(admin).transfer(bondingV2.address, totLP);
    // spice things up by adding a deposit

    const bondFour = await deposit(fourthAccount, ethers.utils.parseEther("1"), 8);
    const bs2 = await masterChefV2.getBondingShareInfo(idSecond);
    const bs4 = await masterChefV2.getBondingShareInfo(bondFour.id);
    const bsmin = await masterChefV2.getBondingShareInfo(bondMinId);
    const bsmax = await masterChefV2.getBondingShareInfo(bondMaxId);
    const sharesToRemove2 = await bondingFormulas.sharesForLP(bondAfterRemoveLQTY, bs2, amountToWithdraw);
    const secondAccbalanceBeforeRemove2 = await metaPool.balanceOf(secondAddress);
    const pendingLpRewards2 = await bondingV2.pendingLpRewards(idSecond);
    const pendingLpRewards4 = await bondingV2.pendingLpRewards(bondFour.id);
    const pendingLpRewardsMin = await bondingV2.pendingLpRewards(bondMinId);
    const pendingLpRewardsMax = await bondingV2.pendingLpRewards(bondMaxId);
    expect(pendingLpRewards4).to.equal(0);
    expect(pendingLpRewards2).to.be.gt(0).and.to.be.lt(pendingLpRewardsMin);
    expect(await masterChefV2.totalShares()).to.equal(bs2[0].add(bs4[0]).add(bsmin[0]).add(bsmax[0]));
    const isPrecise = isAmountEquivalent(
      (await bondingV2.lpRewards()).toString(),
      pendingLpRewardsMin.add(pendingLpRewardsMax).add(pendingLpRewards2).add(pendingLpRewards4).toString(),
      "0.00000001"
    );
    expect(isPrecise).to.be.true;
    await expect(bondingV2.connect(secondAccount).removeLiquidity(amountToWithdraw, idSecond))
      .to.emit(bondingV2, "RemoveLiquidityFromBond")
      .withArgs(secondAddress, idSecond, amountToWithdraw, amountToWithdraw, pendingLpRewards2, sharesToRemove2);
    // user gets the corrected amount of LP
    const secondAccbalanceAfterRemove2 = await metaPool.balanceOf(secondAddress);

    expect(secondAccbalanceAfterRemove2).to.equal(secondAccbalanceBeforeRemove2.add(amountToWithdraw).add(pendingLpRewards2));
    const bsAfter2 = await masterChefV2.getBondingShareInfo(idSecond);

    // user looses the bonding shares corresponding to the amount asked for withdrawal
    expect(bsAfter2[0]).to.equal(bs2[0].sub(sharesToRemove2));
    // bonding share is updated accordingly
    const bondAfterRemoveLQTY2 = await bondingShareV2.getBond(idSecond);
    expect(bondAfterRemoveLQTY2.lpAmount).to.equal(bondAfterRemoveLQTY.lpAmount.sub(amountToWithdraw));
    expect(bondAfterRemoveLQTY2.minter).to.equal(bond.minter);

    expect(bondAfterRemoveLQTY2.lpFirstDeposited).to.equal(bondAfterRemoveLQTY.lpFirstDeposited);
    expect(bondAfterRemoveLQTY2.creationBlock).to.equal(bondAfterRemoveLQTY.creationBlock);
    expect(bondAfterRemoveLQTY2.endBlock).to.equal(bondAfterRemoveLQTY.endBlock);
    const accLpRewardPerShare = await bondingV2.accLpRewardPerShare();
    const lpRewardDebt = bsAfter2[0].mul(accLpRewardPerShare).div(BigNumber.from(1e12));
    expect(bondAfterRemoveLQTY2.lpRewardDebt).to.equal(lpRewardDebt);
  });
  it("crvPriceReset should work twice", async () => {
    const pool0bal0 = await metaPool.balances(0);
    const pool1bal0 = await metaPool.balances(1);
    expect(pool0bal0).to.equal(ethers.utils.parseEther("10300"));
    expect(pool1bal0).to.equal(ethers.utils.parseEther("10300"));

    // remove the pending rewards
    const treasuryAdr = await treasury.getAddress();
    // only leave 4.2 eth as lp rewards
    const firstLPRewards = ethers.utils.parseEther("4.2");
    await metaPool.connect(admin).transfer(bondingV2.address, firstLPRewards);
    const amountOfLpdeposited = one.mul(100);
    // deposit 100 uLP more tokens in addition to the 100 already in the bonding contract
    const idSecond = (await deposit(secondAccount, amountOfLpdeposited, 1)).id;
    const amountToPriceReset = amountOfLpdeposited.div(2);
    // we will remove half of the deposited LP
    // keep in mind that we also have 4.2eth as lp rewards
    const amountOf3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](amountToPriceReset, 1);
    await expect(bondingV2.crvPriceReset(amountToPriceReset))
      .to.emit(crvToken, "Transfer")
      .withArgs(bondingV2.address, treasuryAdr, amountOf3CRV)
      .and.to.emit(bondingV2, "PriceReset")
      .withArgs(crvToken.address, amountOf3CRV, amountOf3CRV);

    const pendingLpRewards = await bondingV2.pendingLpRewards(idSecond);
    // there is still less LP on bonding than the total LP deposited
    expect(pendingLpRewards).to.equal(0);

    // spice things up by adding a deposit
    const amountOf2ndLPdeposit = one.mul(10);
    const idFourth = (await deposit(fourthAccount, amountOf2ndLPdeposit, 8)).id;

    const amountTo2ndPriceReset = ethers.utils.parseEther("8");
    // now we should have 4.2 +403 +100 -50 +10 -8 = 56.2 for total bond of 110

    const totalLPDeposited = await bondingShareV2.totalLP();
    expect(totalLPDeposited).to.equal(bondMin.lpAmount.add(bondMax.lpAmount).add(amountOfLpdeposited.add(amountOf2ndLPdeposit)));
    // we will remove half of the deposited LP
    // keep in mind that we also have 4.2eth as lp rewards
    const amountOf2nd3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](amountTo2ndPriceReset, 1);
    await expect(bondingV2.crvPriceReset(amountTo2ndPriceReset))
      .to.emit(crvToken, "Transfer")
      .withArgs(bondingV2.address, treasuryAdr, amountOf2nd3CRV)
      .and.to.emit(bondingV2, "PriceReset")
      .withArgs(crvToken.address, amountOf2nd3CRV, amountOf2nd3CRV);
    const bondingLPBalance = await metaPool.balanceOf(bondingV2.address);
    expect(bondingLPBalance).to.equal(totalLPDeposited.add(firstLPRewards).sub(amountToPriceReset).sub(amountTo2ndPriceReset));

    const amountToWithdraw = amountOfLpdeposited.div(2);
    const bs2 = await masterChefV2.getBondingShareInfo(idSecond);
    const bond = await bondingShareV2.getBond(idSecond);
    const sharesToRemove2 = await bondingFormulas.sharesForLP(bond, bs2, amountToWithdraw);

    const bondingSCBalanceBeforeRemove2 = await metaPool.balanceOf(bondingV2.address);
    const secondAccbalanceBeforeRemove2 = await metaPool.balanceOf(secondAddress);
    const totalBondingLPDeposited2 = await bondingShareV2.totalLP();

    const pendingLpRewards2 = await bondingV2.pendingLpRewards(idSecond);

    expect(pendingLpRewards2).to.equal(0);
    const pendingLpRewards4 = await bondingV2.pendingLpRewards(idFourth);
    expect(pendingLpRewards4).to.equal(0);
    const lpRewards = await bondingV2.lpRewards();
    const correctedAmount2 = amountToWithdraw.mul(bondingSCBalanceBeforeRemove2.sub(lpRewards)).div(totalBondingLPDeposited2);
    const bondAfterRemoveLQTY = await bondingShareV2.getBond(idSecond);

    const lastBlockNum = await latestBlockNumber();
    const endOfLockingInBlock = bond.endBlock.toNumber() - lastBlockNum.number;
    await mineNBlock(endOfLockingInBlock);
    await expect(bondingV2.connect(secondAccount).removeLiquidity(amountToWithdraw, idSecond))
      .to.emit(bondingV2, "RemoveLiquidityFromBond")
      .withArgs(secondAddress, idSecond, amountToWithdraw, correctedAmount2, pendingLpRewards2, sharesToRemove2);
    // user gets the corrected amount of LP
    const secondAccbalanceAfterRemove2 = await metaPool.balanceOf(secondAddress);
    const bondingSCBalanceAfterRemove2 = await metaPool.balanceOf(bondingV2.address);
    // we have transferred the corrected amount not the amount we asked
    expect(bondingSCBalanceAfterRemove2).to.equal(bondingSCBalanceBeforeRemove2.sub(correctedAmount2));
    expect(secondAccbalanceAfterRemove2).to.equal(secondAccbalanceBeforeRemove2.add(correctedAmount2));
    const bsAfter2 = await masterChefV2.getBondingShareInfo(idSecond);

    // user looses the bonding shares corresponding to the amount asked for withdrawal
    expect(bsAfter2[0]).to.equal(bs2[0].sub(sharesToRemove2));
    // bonding share is updated accordingly
    const bondAfterRemoveLQTY2 = await bondingShareV2.getBond(idSecond);
    expect(bondAfterRemoveLQTY2.lpAmount).to.equal(bondAfterRemoveLQTY.lpAmount.sub(amountToWithdraw));
    expect(bondAfterRemoveLQTY2.minter).to.equal(bond.minter);

    expect(bondAfterRemoveLQTY2.lpFirstDeposited).to.equal(bondAfterRemoveLQTY.lpFirstDeposited);
    expect(bondAfterRemoveLQTY2.creationBlock).to.equal(bondAfterRemoveLQTY.creationBlock);
    expect(bondAfterRemoveLQTY2.endBlock).to.equal(bondAfterRemoveLQTY.endBlock);
    const accLpRewardPerShare = await bondingV2.accLpRewardPerShare();
    const lpRewardDebt = bsAfter2[0].mul(accLpRewardPerShare).div(BigNumber.from(1e12));
    expect(bondAfterRemoveLQTY2.lpRewardDebt).to.equal(lpRewardDebt);
  });
  it("uADPriceReset should work", async () => {
    const bondingUADBalanceBefore = await uAD.balanceOf(bondingV2.address);
    const pool0bal0 = await metaPool.balances(0);
    const pool1bal0 = await metaPool.balances(1);
    expect(pool0bal0).to.equal(ethers.utils.parseEther("10300"));
    expect(pool1bal0).to.equal(ethers.utils.parseEther("10300"));

    const amountOf3CRVforOneUADBefore = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
    // remove the pending rewards
    const treasuryAdr = await treasury.getAddress();
    // only leave 4.2 eth as lp rewards

    const amountOfLpdeposited = one.mul(100);
    // deposit 100 uLP more tokens in addition to the 100 already in the bonding contract
    const idSecond = (await deposit(secondAccount, amountOfLpdeposited, 1)).id;
    const bondBefore = await bondingShareV2.balanceOf(secondAddress, idSecond);
    const totalBondingLPDeposited = await bondingShareV2.totalLP();
    // value in LP of a bonding share
    const shareValueBefore = await bondingV2.currentShareValue();
    const sharesTotalSupply = await masterChefV2.totalShares();
    // amount of uAD inside the treasury
    const treasuryUADBalanceBeforeReset = await uAD.balanceOf(treasuryAdr);
    //  priceBOND = totalLP / totalShares * TARGET_PRICE
    const calculatedShareValue = totalBondingLPDeposited.mul(one).div(sharesTotalSupply);
    expect(shareValueBefore).to.equal(calculatedShareValue);
    // const amountToTreasury = ethers.utils.parseEther("196.586734740380915533");
    const amountOfUAD = await metaPool["calc_withdraw_one_coin(uint256,int128)"](totalBondingLPDeposited, 0);
    const bondingSCBalanceBefore = await metaPool.balanceOf(bondingV2.address);
    await expect(bondingV2.uADPriceReset(totalBondingLPDeposited))
      .to.emit(uAD, "Transfer")
      .withArgs(bondingV2.address, treasuryAdr, amountOfUAD)
      .and.to.emit(bondingV2, "PriceReset")
      .withArgs(uAD.address, amountOfUAD, amountOfUAD);
    const treasuryUADBalanceAfterReset = await uAD.balanceOf(treasuryAdr);
    expect(treasuryUADBalanceAfterReset).to.equal(treasuryUADBalanceBeforeReset.add(amountOfUAD));
    const bondAfter = await bondingShareV2.balanceOf(secondAddress, idSecond);
    // bonding share should remain the same
    expect(bondBefore).to.equal(bondAfter);
    // amount of curve LP to be withdrawn should be less
    const shareValueAfter = await bondingV2.currentShareValue();
    const bondingSCBalanceAfter = await metaPool.balanceOf(bondingV2.address);

    expect(bondingSCBalanceAfter).to.equal(bondingSCBalanceBefore.sub(totalBondingLPDeposited));
    // share value is the same
    expect(shareValueAfter).to.equal(shareValueBefore);
    const bondingUADBalanceAfter = await uAD.balanceOf(bondingV2.address);
    const oraclePrice = await twapOracle.consult(uAD.address);
    const amountOf3CRVforOneUADAfter = await metaPool["get_dy(int128,int128,uint256)"](0, 1, ethers.utils.parseEther("1"));
    const oracleCRVPrice = await twapOracle.consult(crvToken.address);
    // price of uAD against 3CRV should be greater than before
    // meaning for a uAD you can have more 3CRV
    expect(amountOf3CRVforOneUADAfter).to.be.gt(amountOf3CRVforOneUADBefore);
    const pool0bal = await metaPool.balances(0);
    const pool1bal = await metaPool.balances(1);
    expect(bondingUADBalanceBefore).to.equal(0);
    expect(bondingUADBalanceAfter).to.equal(0);
    expect(pool1bal).to.equal(pool1bal0);
    expect(pool0bal).to.be.lt(pool0bal0.sub(amountOfUAD));
    await swapToUpdateOracle(metaPool, crvToken, uAD, admin);

    await twapOracle.update();
    const oraclePriceLatest = await twapOracle.consult(uAD.address);
    const oracleCRVPriceLatest = await twapOracle.consult(crvToken.address);
    // After update the TWAP price of uAD against 3CRV should be greater than before
    // the price of uAD against  price of 3CRV should be greater than before
    expect(oraclePriceLatest).to.be.gt(oraclePrice);
    expect(oracleCRVPriceLatest).to.be.lt(oracleCRVPrice);
    // user can't withdraw all his deposited LP token because of the price reset
    const lastBlockNum = await latestBlockNumber();
    const bond = await bondingShareV2.getBond(idSecond);
    const endOfLockingInBlock = bond.endBlock.toNumber() - lastBlockNum.number;

    await mineNBlock(endOfLockingInBlock);

    const bs = await masterChefV2.getBondingShareInfo(idSecond);

    await metaPool.connect(admin).transfer(bondingV2.address, ethers.utils.parseEther("10"));
    const bondingSCBalanceNew = await metaPool.balanceOf(bondingV2.address);
    let amountToWithdraw = bond.lpAmount.div(2);
    const sharesToRemove = await bondingFormulas.sharesForLP(bond, bs, amountToWithdraw);
    const pendingLpRewards = await bondingV2.pendingLpRewards(idSecond);
    // there is still less LP on bonding than the total LP deposited
    expect(pendingLpRewards).to.equal(0);

    const correctedAmount = amountToWithdraw.mul(bondingSCBalanceNew.sub(pendingLpRewards)).div(totalBondingLPDeposited);

    const secondAccbalanceBeforeRemove = await metaPool.balanceOf(secondAddress);
    await expect(bondingV2.connect(secondAccount).removeLiquidity(amountToWithdraw, idSecond))
      .to.emit(bondingV2, "RemoveLiquidityFromBond")
      .withArgs(secondAddress, idSecond, amountToWithdraw, correctedAmount, pendingLpRewards, sharesToRemove);
    // user gets the corrected amount of LP
    const secondAccbalanceAfterRemove = await metaPool.balanceOf(secondAddress);
    expect(secondAccbalanceAfterRemove).to.equal(secondAccbalanceBeforeRemove.add(correctedAmount));
    const bsAfter = await masterChefV2.getBondingShareInfo(idSecond);

    // user looses the bonding shares corresponding to the amount asked for withdrawal
    expect(bsAfter[0]).to.equal(bs[0].sub(sharesToRemove));
    // bonding share is updated accordingly
    const bondAfterRemoveLQTY = await bondingShareV2.getBond(idSecond);
    expect(bondAfterRemoveLQTY.lpAmount).to.equal(bond.lpAmount.sub(amountToWithdraw));
    expect(bondAfterRemoveLQTY.minter).to.equal(bond.minter);

    expect(bondAfterRemoveLQTY.lpFirstDeposited).to.equal(bond.lpFirstDeposited);
    expect(bondAfterRemoveLQTY.creationBlock).to.equal(bond.creationBlock);
    expect(bondAfterRemoveLQTY.endBlock).to.equal(bond.endBlock);
    expect(bondAfterRemoveLQTY.lpRewardDebt).to.equal(bond.lpRewardDebt);

    /**
     * make sure that if LP are back on the bonding contract user can access rewards and its LP
     */

    amountToWithdraw = bondAfterRemoveLQTY.lpAmount.div(5);
    const totLP = await bondingShareV2.totalLP();
    await metaPool.connect(admin).transfer(bondingV2.address, totLP);
    // spice things up by adding a deposit

    const bondFour = await deposit(fourthAccount, ethers.utils.parseEther("1"), 8);
    const bs2 = await masterChefV2.getBondingShareInfo(idSecond);
    const bs4 = await masterChefV2.getBondingShareInfo(bondFour.id);
    const bsmin = await masterChefV2.getBondingShareInfo(bondMinId);
    const bsmax = await masterChefV2.getBondingShareInfo(bondMaxId);
    const sharesToRemove2 = await bondingFormulas.sharesForLP(bondAfterRemoveLQTY, bs2, amountToWithdraw);
    const secondAccbalanceBeforeRemove2 = await metaPool.balanceOf(secondAddress);
    const pendingLpRewards2 = await bondingV2.pendingLpRewards(idSecond);
    const pendingLpRewards4 = await bondingV2.pendingLpRewards(bondFour.id);
    const pendingLpRewardsMin = await bondingV2.pendingLpRewards(bondMinId);
    const pendingLpRewardsMax = await bondingV2.pendingLpRewards(bondMaxId);
    expect(pendingLpRewards4).to.equal(0);
    expect(pendingLpRewards2).to.be.gt(0).and.to.be.lt(pendingLpRewardsMin);
    expect(await masterChefV2.totalShares()).to.equal(bs2[0].add(bs4[0]).add(bsmin[0]).add(bsmax[0]));
    const isPrecise = isAmountEquivalent(
      (await bondingV2.lpRewards()).toString(),
      pendingLpRewardsMin.add(pendingLpRewardsMax).add(pendingLpRewards2).add(pendingLpRewards4).toString(),
      "0.00000001"
    );

    expect(isPrecise).to.be.true;

    await expect(bondingV2.connect(secondAccount).removeLiquidity(amountToWithdraw, idSecond))
      .to.emit(bondingV2, "RemoveLiquidityFromBond")
      .withArgs(secondAddress, idSecond, amountToWithdraw, amountToWithdraw, pendingLpRewards2, sharesToRemove2);
    // user gets the corrected amount of LP
    const secondAccbalanceAfterRemove2 = await metaPool.balanceOf(secondAddress);

    expect(secondAccbalanceAfterRemove2).to.equal(secondAccbalanceBeforeRemove2.add(amountToWithdraw).add(pendingLpRewards2));
    const bsAfter2 = await masterChefV2.getBondingShareInfo(idSecond);

    // user looses the bonding shares corresponding to the amount asked for withdrawal
    expect(bsAfter2[0]).to.equal(bs2[0].sub(sharesToRemove2));
    // bonding share is updated accordingly
    const bondAfterRemoveLQTY2 = await bondingShareV2.getBond(idSecond);
    expect(bondAfterRemoveLQTY2.lpAmount).to.equal(bondAfterRemoveLQTY.lpAmount.sub(amountToWithdraw));
    expect(bondAfterRemoveLQTY2.minter).to.equal(bond.minter);

    expect(bondAfterRemoveLQTY2.lpFirstDeposited).to.equal(bondAfterRemoveLQTY.lpFirstDeposited);
    expect(bondAfterRemoveLQTY2.creationBlock).to.equal(bondAfterRemoveLQTY.creationBlock);
    expect(bondAfterRemoveLQTY2.endBlock).to.equal(bondAfterRemoveLQTY.endBlock);
    const accLpRewardPerShare = await bondingV2.accLpRewardPerShare();
    const lpRewardDebt = bsAfter2[0].mul(accLpRewardPerShare).div(BigNumber.from(1e12));
    expect(bondAfterRemoveLQTY2.lpRewardDebt).to.equal(lpRewardDebt);
  });
  it("uADPriceReset should work twice", async () => {
    const pool0bal0 = await metaPool.balances(0);
    const pool1bal0 = await metaPool.balances(1);
    expect(pool0bal0).to.equal(ethers.utils.parseEther("10300"));
    expect(pool1bal0).to.equal(ethers.utils.parseEther("10300"));

    // remove the pending rewards
    const treasuryAdr = await treasury.getAddress();
    // only leave 4.2 eth as lp rewards
    const firstLPRewards = ethers.utils.parseEther("4.2");
    await metaPool.connect(admin).transfer(bondingV2.address, firstLPRewards);
    const amountOfLpdeposited = one.mul(100);
    // deposit 100 uLP more tokens in addition to the 100 already in the bonding contract
    const idSecond = (await deposit(secondAccount, amountOfLpdeposited, 1)).id;

    const amountToPriceReset = amountOfLpdeposited.div(2);

    // we will remove half of the deposited LP
    // keep in mind that we also have 4.2eth as lp rewards
    const amountOfUAD = await metaPool["calc_withdraw_one_coin(uint256,int128)"](amountToPriceReset, 0);
    await expect(bondingV2.uADPriceReset(amountToPriceReset))
      .to.emit(uAD, "Transfer")
      .withArgs(bondingV2.address, treasuryAdr, amountOfUAD)
      .and.to.emit(bondingV2, "PriceReset")
      .withArgs(uAD.address, amountOfUAD, amountOfUAD);

    const pendingLpRewards = await bondingV2.pendingLpRewards(idSecond);
    // there is still less LP on bonding than the total LP deposited
    expect(pendingLpRewards).to.equal(0);

    // spice things up by adding a deposit
    const amountOf2ndLPdeposit = one.mul(10);
    const idFourth = (await deposit(fourthAccount, amountOf2ndLPdeposit, 8)).id;

    const amountTo2ndPriceReset = ethers.utils.parseEther("8");
    // now we should have 4.2 +100 -50 +10 -8 = 56.2 for total bond of 110

    const totalLPDeposited = await bondingShareV2.totalLP();
    expect(totalLPDeposited).to.equal(bondMin.lpAmount.add(bondMax.lpAmount).add(amountOfLpdeposited.add(amountOf2ndLPdeposit)));

    // we will remove half of the deposited LP
    // keep in mind that we also have 4.2eth as lp rewards
    const amountOf2ndUAD = await metaPool["calc_withdraw_one_coin(uint256,int128)"](amountTo2ndPriceReset, 0);
    await expect(bondingV2.uADPriceReset(amountTo2ndPriceReset))
      .to.emit(uAD, "Transfer")
      .withArgs(bondingV2.address, treasuryAdr, amountOf2ndUAD)
      .and.to.emit(bondingV2, "PriceReset")
      .withArgs(uAD.address, amountOf2ndUAD, amountOf2ndUAD);
    const bondingLPBalance = await metaPool.balanceOf(bondingV2.address);
    expect(bondingLPBalance).to.equal(totalLPDeposited.add(firstLPRewards).sub(amountToPriceReset).sub(amountTo2ndPriceReset));

    const amountToWithdraw = amountOfLpdeposited.div(2);
    const bs2 = await masterChefV2.getBondingShareInfo(idSecond);
    const bond = await bondingShareV2.getBond(idSecond);
    const sharesToRemove2 = await bondingFormulas.sharesForLP(bond, bs2, amountToWithdraw);

    const bondingSCBalanceBeforeRemove2 = await metaPool.balanceOf(bondingV2.address);
    const secondAccbalanceBeforeRemove2 = await metaPool.balanceOf(secondAddress);
    const totalBondingLPDeposited2 = await bondingShareV2.totalLP();

    const pendingLpRewards2 = await bondingV2.pendingLpRewards(idSecond);

    expect(pendingLpRewards2).to.equal(0);
    const pendingLpRewards4 = await bondingV2.pendingLpRewards(idFourth);
    expect(pendingLpRewards4).to.equal(0);
    const lpRewards = await bondingV2.lpRewards();
    const correctedAmount2 = amountToWithdraw.mul(bondingSCBalanceBeforeRemove2.sub(lpRewards)).div(totalBondingLPDeposited2);

    const bondAfterRemoveLQTY = await bondingShareV2.getBond(idSecond);

    const lastBlockNum = await latestBlockNumber();
    const endOfLockingInBlock = bond.endBlock.toNumber() - lastBlockNum.number;

    await mineNBlock(endOfLockingInBlock);
    await expect(bondingV2.connect(secondAccount).removeLiquidity(amountToWithdraw, idSecond))
      .to.emit(bondingV2, "RemoveLiquidityFromBond")
      .withArgs(secondAddress, idSecond, amountToWithdraw, correctedAmount2, pendingLpRewards2, sharesToRemove2);
    // user gets the corrected amount of LP
    const secondAccbalanceAfterRemove2 = await metaPool.balanceOf(secondAddress);
    const bondingSCBalanceAfterRemove2 = await metaPool.balanceOf(bondingV2.address);
    // we have transferred the corrected amount not the amount we asked
    expect(bondingSCBalanceAfterRemove2).to.equal(bondingSCBalanceBeforeRemove2.sub(correctedAmount2));
    expect(secondAccbalanceAfterRemove2).to.equal(secondAccbalanceBeforeRemove2.add(correctedAmount2));
    const bsAfter2 = await masterChefV2.getBondingShareInfo(idSecond);

    // user looses the bonding shares corresponding to the amount asked for withdrawal
    expect(bsAfter2[0]).to.equal(bs2[0].sub(sharesToRemove2));
    // bonding share is updated accordingly
    const bondAfterRemoveLQTY2 = await bondingShareV2.getBond(idSecond);
    expect(bondAfterRemoveLQTY2.lpAmount).to.equal(bondAfterRemoveLQTY.lpAmount.sub(amountToWithdraw));
    expect(bondAfterRemoveLQTY2.minter).to.equal(bond.minter);

    expect(bondAfterRemoveLQTY2.lpFirstDeposited).to.equal(bondAfterRemoveLQTY.lpFirstDeposited);
    expect(bondAfterRemoveLQTY2.creationBlock).to.equal(bondAfterRemoveLQTY.creationBlock);
    expect(bondAfterRemoveLQTY2.endBlock).to.equal(bondAfterRemoveLQTY.endBlock);
    const accLpRewardPerShare = await bondingV2.accLpRewardPerShare();
    const lpRewardDebt = bsAfter2[0].mul(accLpRewardPerShare).div(BigNumber.from(1e12));
    expect(bondAfterRemoveLQTY2.lpRewardDebt).to.equal(lpRewardDebt);
  });
});
