import { expect } from "chai";
import { ethers, deployments, artifacts } from "hardhat";
import { BigNumber, Signer } from "ethers";
import { impersonate, impersonateWithEther, resetFork, mineNBlock } from "./utils/hardhatNode";

import { MasterChefV2 } from "../artifacts/types/MasterChefV2";
import { BondingV2 } from "../artifacts/types/BondingV2";
import { BondingShareV2 } from "../artifacts/types/BondingShareV2";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { IERC20Ubiquity } from "../artifacts/types/IERC20Ubiquity";

const UBQ_MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE"));
const ten = BigNumber.from(10);
const one = ten.pow(18); // 1 ether

const startBlock = 13004900;
const adminAddress = "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd";
const managerAddress = "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98";
const newOneAddress = "0xd6efc21d8c941aa06f90075de1588ac7e912fec6";

let masterChefV2: MasterChefV2;
let bondingV2: BondingV2;
let bondingShareV2: BondingShareV2;
let UBQ: IERC20Ubiquity;

let admin: Signer;
let newOne: Signer;

describe("MasterChefV2.1", () => {
  beforeEach(async () => {
    await resetFork(startBlock);

    admin = await impersonate(adminAddress);
    newOne = await impersonate(newOneAddress);

    // await deployments.fixture(["MasterChefV2.1"]);
    // const masterChefV2Address = (await deployments.get("MasterChefV2")).address;
    const masterChefV2Address = "0xdae807071b5AC7B6a2a343beaD19929426dBC998";
    masterChefV2 = (await ethers.getContractAt("MasterChefV2", masterChefV2Address)) as MasterChefV2;

    const manager: UbiquityAlgorithmicDollarManager = (await ethers.getContractAt(
      "UbiquityAlgorithmicDollarManager",
      managerAddress
    )) as UbiquityAlgorithmicDollarManager;

    await manager.connect(admin).grantRole(UBQ_MINTER_ROLE, masterChefV2Address);
    await masterChefV2.connect(admin).setUGOVPerBlock(one);
    await manager.connect(admin).setMasterChefAddress(masterChefV2Address);

    bondingV2 = (await ethers.getContractAt("BondingV2", "0xC251eCD9f1bD5230823F9A0F99a44A87Ddd4CA38")) as BondingV2;
    bondingShareV2 = (await ethers.getContractAt("BondingShareV2", "0x2dA07859613C14F6f05c97eFE37B9B4F212b5eF5")) as BondingShareV2;
    UBQ = (await ethers.getContractAt("UbiquityGovernance", "0x4e38d89362f7e5db0096ce44ebd021c3962aa9a0")) as IERC20Ubiquity;
  });

  it("Should deploy", () => {
    expect(masterChefV2.address).to.be.properAddress;
  });

  it("Should have proper balances", async () => {
    const amounts = [
      "0",
      "1301000000000000000",
      "74603879373206500005186",
      "44739174270101943975392",
      "1480607760433248019987",
      "9351040526163838324896",
      "8991650309086743220575",
    ];

    for (let bondId = 0; bondId <= 6; bondId += 1) {
      // eslint-disable-next-line no-await-in-loop
      const bond = await bondingShareV2.getBond(bondId);

      // console.log(`BOND #${bondId} ${bond[0]}`);
      // console.log(`lpAmount ${ethers.utils.formatEther(bond[5])}`);

      expect(bond[5]).to.be.equal(amounts[bondId]);
    }
  });

  it("Should have proper values", async () => {
    let bondId = 1;

    expect(await masterChefV2.totalShares()).to.be.equal("139167653238992273546036");
    expect(await masterChefV2.pendingUGOV(bondId)).to.be.equal("613722535788000");
    let amount: BigNumber;
    let rewardDebt: BigNumber;
    [amount, rewardDebt] = await masterChefV2.getBondingShareInfo(bondId);
    expect(amount).to.be.equal("1301000000000000000");
    expect(rewardDebt).to.be.equal(0);
    expect(await bondingShareV2.totalSupply()).to.be.equal(6);

    await bondingV2.connect(admin).setMigrating(true);
    await (await bondingV2.connect(newOne).migrate()).wait();

    bondId = (await bondingShareV2.holderTokens(newOneAddress))[0].toNumber();

    // mine some blocks to get pendingUGOV
    await mineNBlock(10);

    expect(await masterChefV2.totalShares()).to.be.equal("164423351646027648930634");
    expect(await masterChefV2.pendingUGOV(bondId)).to.be.equal("1575610941338545019");
    [amount, rewardDebt] = await masterChefV2.getBondingShareInfo(bondId);
    expect(amount).to.be.equal("25255698407035375384598");
    expect(rewardDebt).to.be.equal("12286215194375831320");
    expect(await bondingShareV2.totalSupply()).to.be.equal(7);
  });

  it("Should get back UBQ", async () => {
    const user2 = "0x4007ce2083c7f3e18097aeb3a39bb8ec149a341d";
    await impersonateWithEther(user2, 100);
    const bond2Signer = ethers.provider.getSigner(user2);

    await mineNBlock(1000);

    const pendingUGOV1 = await masterChefV2.pendingUGOV(2);
    const bond1 = await bondingShareV2.getBond(2);
    const ubq1 = await UBQ.balanceOf(user2);

    // console.log("pendingUGOV", ethers.utils.formatEther(pendingUGOV1));
    // console.log("lpAmount", ethers.utils.formatEther(bond1[5]));
    // console.log("UBQ", ethers.utils.formatEther(ubq1));

    expect(pendingUGOV1).to.be.equal("585633375335031009566");
    expect(bond1[5]).to.be.equal("74603879373206500005186");
    expect(ubq1).to.be.equal("168394820774964495022850");
    expect(bond1[0].toLowerCase()).to.be.equal(user2.toLowerCase());

    await masterChefV2.connect(bond2Signer).getRewards(2);
    const pendingUGOV2 = await masterChefV2.pendingUGOV(2);
    const ubq2 = await UBQ.balanceOf(user2);

    // console.log("pendingUGOV", ethers.utils.formatEther(pendingUGOV2));
    // console.log("UBQ", ethers.utils.formatEther(ubq2));

    expect(pendingUGOV2).to.be.equal(0);
    expect(ubq1.add(pendingUGOV1).sub(ubq2)).to.be.lt(ten.pow(18));
  });

  it("Should set uGOVPerBlock and emit UGOVPerBlockModified event", async () => {
    await expect(masterChefV2.connect(admin).setUGOVPerBlock(one.mul(2)))
      .to.emit(masterChefV2, "UGOVPerBlockModified")
      .withArgs(one.mul(2));
    expect(await masterChefV2.uGOVPerBlock()).to.be.equal(one.mul(2));
  });

  it("Should set minPriceDiffToUpdateMultiplier emit MinPriceDiffToUpdateMultiplierModified event", async () => {
    const zz1 = BigNumber.from(10).pow(15); // 0.001 ether
    await expect(masterChefV2.connect(admin).setMinPriceDiffToUpdateMultiplier(zz1))
      .to.emit(masterChefV2, "MinPriceDiffToUpdateMultiplierModified")
      .withArgs(zz1);
    expect(await masterChefV2.minPriceDiffToUpdateMultiplier()).to.be.equal(zz1);
  });

  it("Should MasterchefV2.1 have at least same functions than MasterChefV2", async () => {
    // https://etherscan.io/address/0xB8Ec70D24306ECEF9D4aaf9986DCb1DA5736A997#code
    const abiV2 =
      '[{"inputs":[{"internalType":"address","name":"_manager","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":true,"internalType":"uint256","name":"bondingShareId","type":"uint256"}],"name":"Deposit","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"user","type":"address"},{"indexed":false,"internalType":"uint256","name":"amount","type":"uint256"},{"indexed":true,"internalType":"uint256","name":"bondingShareId","type":"uint256"}],"name":"Withdraw","type":"event"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"},{"internalType":"uint256","name":"_bondingShareID","type":"uint256"}],"name":"deposit","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"getBondingShareInfo","outputs":[{"internalType":"uint256[2]","name":"","type":"uint256[2]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"bondingShareID","type":"uint256"}],"name":"getRewards","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"lastPrice","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"manager","outputs":[{"internalType":"contract UbiquityAlgorithmicDollarManager","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"minPriceDiffToUpdateMultiplier","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"bondingShareID","type":"uint256"}],"name":"pendingUGOV","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"pool","outputs":[{"internalType":"uint256","name":"lastRewardBlock","type":"uint256"},{"internalType":"uint256","name":"accuGOVPerShare","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_minPriceDiffToUpdateMultiplier","type":"uint256"}],"name":"setMinPriceDiffToUpdateMultiplier","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_uGOVPerBlock","type":"uint256"}],"name":"setUGOVPerBlock","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_uGOVDivider","type":"uint256"}],"name":"setUGOVShareForTreasury","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"totalShares","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"uGOVDivider","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"uGOVPerBlock","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"uGOVmultiplier","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"_amount","type":"uint256"},{"internalType":"uint256","name":"_bondingShareID","type":"uint256"}],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"}]';
    const ifaceDeployed = new ethers.utils.Interface(abiV2);

    const artifactDev = await artifacts.readArtifact("contracts/MasterChefV2.sol:MasterChefV2");
    const ifaceDev = new ethers.utils.Interface(artifactDev.abi);

    // start from previous version, new version has new events and may have new functions
    ifaceDeployed.fragments.forEach((fragment) => {
      // constructor differs, do not compare
      if (fragment.type !== "constructor") {
        const index = ifaceDev.fragments.findIndex((frag) => frag.type !== "constructor" && frag.format() === fragment.format());
        // console.log(index, fragment.format());
        expect(index).to.be.gte(0);
      }
    });
  });
});
