import type { Signer, Contract } from "ethers";
import type { LP } from "types/LP";
import type { UAR } from "types/UAR";
import type { SimpleBond } from "types/SimpleBond";
import type { TheUbiquityStick } from "types/TheUbiquityStick";
import type { SignerWithAddress } from "hardhat-deploy-ethers/signers";

import { expect } from "chai";
import { ethers, deployments } from "hardhat";
import { BigNumber, utils } from "ethers";

import { mineNBlocks } from "./utils";

const zeroAddress = "0x0000000000000000000000000000000000000000";
const ten = BigNumber.from(10);
const bigOne = ten.pow(18);
const amountToMint = bigOne.mul(1000);
const allowance = bigOne.mul(500);
const rewardsRatio = ten.pow(6).mul(1732);

describe("SimpleBond", function () {
  let signer: SignerWithAddress;
  let treasury: SignerWithAddress;

  let lp: LP;
  let uAR: UAR;
  let simpleBond: SimpleBond;
  let theUbiquityStick: TheUbiquityStick;

  before(async () => {
    ({ deployer: signer, treasury } = await ethers.getNamedSigners());
    console.log(signer.address, "signer");
    console.log(treasury.address, "treasury");

    // Deploy contract if not already
    if (!(await ethers.getContractOrNull("SimpleBond"))) {
      console.log("Deploying...");
      await deployments.fixture(["SimpleBond"]);
    }

    simpleBond = await ethers.getContract("SimpleBond", signer);
    uAR = await ethers.getContract("UAR", signer);

    const uarOwner = await uAR.owner();
    console.log("uAR owner", uarOwner);

    lp = await ethers.getContract("LP", signer);
    console.log(lp.address, "lp");

    // MINT 1000 LP tokens
    await (await lp.mint(amountToMint)).wait();
    console.log("lp balance signer", String(await lp.balanceOf(signer.address)));

    // APPROVE 500 LP tokens to be spent by simpleBond
    await (await lp.approve(simpleBond.address, allowance)).wait();

    // SET REWARDS
    await (await simpleBond.setRewards(lp.address, rewardsRatio)).wait();

    theUbiquityStick = await ethers.getContract("TheUbiquityStick");
  });

  afterEach(async () => {
    console.log("BLOCK", await ethers.provider.getBlockNumber());

    const bondsCount = Number(await simpleBond.bondsCount(signer.address));
    for (let index = 0; index < bondsCount; index++) {
      console.log(`\nBOND #${index}`);
      const bond = await simpleBond.bonds(signer.address, index);
      console.log(`${utils.formatEther(bond.amount)} amount`);
      console.log(`${utils.formatEther(bond.rewards)} rewards`);
      console.log(`${utils.formatEther(bond.claimed)} claimed`);
      console.log(`${bond.block} block`);
      console.log(`${bond.token.substring(0, 6)}... token`);
    }

    console.log(`\n${bondsCount} BOND${bondsCount > 1 ? "s" : ""}`);
    const [rewards, rewardsClaimed, rewardsClaimable] = await simpleBond.rewardsOf(signer.address);
    console.log(`${utils.formatEther(rewards)} rewards`);
    console.log(`${utils.formatEther(rewardsClaimed)} rewardsClaimed`);
    console.log(`${utils.formatEther(rewardsClaimable)} rewardsClaimable`);

    console.log(`\n`);
  });

  it("Should be ok", async function () {
    expect(signer.address).to.be.properAddress;
    expect(simpleBond.address).to.be.properAddress;
    expect(theUbiquityStick.address).to.be.properAddress;
    expect(uAR.address).to.be.properAddress;
    expect(lp.address).to.be.properAddress;
  });

  it("Should bond if no Sticker NFT set ", async function () {
    await (await simpleBond.setSticker(zeroAddress)).wait();
    await (await simpleBond.bond(lp.address, bigOne.mul(100))).wait();
    expect(await simpleBond.bondsCount(signer.address)).to.be.equal(1);
  });

  it("Should not bond without Sticker NFT", async function () {
    await (await simpleBond.setSticker(theUbiquityStick.address)).wait();
    await expect(simpleBond.bond(lp.address, bigOne.mul(100))).to.be.revertedWith("Not NFT Stick owner");
  });

  it("Should bond with Sticker NFT", async function () {
    await expect((await theUbiquityStick.connect(signer).safeMint(signer.address)).wait()).to.be.not.reverted;
    await (await simpleBond.bond(lp.address, bigOne.mul(100))).wait();
    expect(await simpleBond.bondsCount(signer.address)).to.be.equal(2);
  });

  it("Wait 2 000 blocks to 2 000+", async function () {
    await mineNBlocks(2000);
  });

  it("Should claim rewards", async function () {
    await simpleBond.claim();
  });

  it("Wait 2 000 blocks to 4 000+", async function () {
    await mineNBlocks(2000);
  });
  it("Wait 20 000 blocks to 24 000+", async function () {
    await mineNBlocks(20000);
  });
  it("Wait 20 000 blocks to 44 000+", async function () {
    await mineNBlocks(20000);
  });

  it("Should claim rewards", async function () {
    console.log("uAR owner", await uAR.owner());
    await simpleBond.claim();
  });

  it("Should bond again", async function () {
    await simpleBond.bond(lp.address, bigOne.mul(100));
  });

  it("Wait 2000 blocks", async function () {
    await mineNBlocks(2000);
  });

  it("Wait 30000 blocks", async function () {
    await mineNBlocks(30000);
  });

  it("Should withdraw LPs", async function () {
    await simpleBond.withdraw(lp.address, bigOne.mul(200));
  });

  it("Should claim rewards", async function () {
    await simpleBond.claim();
  });

  it("Should set rewards ratio", async function () {
    expect(await simpleBond.rewardsRatio(lp.address)).to.be.equal(rewardsRatio);

    const newRewardsRatio = ten.pow(5).mul(48);
    await (await simpleBond.setRewards(lp.address, newRewardsRatio)).wait();
    expect(await simpleBond.rewardsRatio(lp.address)).to.be.equal(newRewardsRatio);

    await (await simpleBond.setRewards(lp.address, rewardsRatio)).wait();
    expect(await simpleBond.rewardsRatio(lp.address)).to.be.equal(rewardsRatio);
  });

  it("Should pause bonding and claiming", async function () {
    await simpleBond.bond(lp.address, bigOne);

    await expect(simpleBond.pause()).to.be.not.reverted;

    await expect(simpleBond.bond(lp.address, bigOne)).to.be.revertedWith("Pausable: paused");
    await expect(simpleBond.claim()).to.be.revertedWith("Pausable: paused");
    await expect(simpleBond.claimBond(0)).to.be.revertedWith("Pausable: paused");

    await expect(simpleBond.unpause()).to.be.not.reverted;

    await expect(simpleBond.bond(lp.address, bigOne)).to.be.not.reverted;
    await expect(simpleBond.claim()).to.be.not.reverted;
  });
});
