import { expect } from "chai";
import { ethers, deployments, getNamedAccounts, network, getChainId } from "hardhat";
import { Signer, BigNumber, utils } from "ethers";
import { TheUbiquityStick } from "../types/TheUbiquityStick";
import { TheUbiquityStickSale } from "../types/TheUbiquityStickSale";

const { provider } = ethers;

const one = BigNumber.from(10).pow(18);
const gwei = BigNumber.from(10).pow(9);
const gas = gwei.mul(100000);

const MAXIMUM_SUPPLY = 1024;
const count = 34;
const price = one.mul(3);

describe("TheUbiquityStickSale", () => {
  let theUbiquityStick: TheUbiquityStick;
  let theUbiquityStickSale: TheUbiquityStickSale;

  let minter: string;
  let tester1: string;
  let tester2: string;
  let random: string;
  let treasury: string;

  let minterSigner: Signer;
  let tester1Signer: Signer;
  let randomSigner: Signer;

  const mint = async (signer: Signer, count: number, price: BigNumber): Promise<BigNumber> => {
    const signerAddress = await signer.getAddress();
    const totalSupplyBefore = await theUbiquityStick.totalSupply();

    await (await theUbiquityStickSale.setAllowance(signerAddress, count, price)).wait();

    await expect(
      signer.sendTransaction({
        to: theUbiquityStickSale.address,
        value: price.mul(count).add(gas),
      })
    )
      .to.emit(theUbiquityStickSale, "Mint")
      .withArgs(signerAddress, count, price.mul(count));

    const totalSupplyAfter = await theUbiquityStick.totalSupply();

    console.log(`${totalSupplyBefore} ${totalSupplyAfter}`);
    return totalSupplyAfter.sub(totalSupplyBefore);
  };

  before(async () => {
    const chainId = Number(await getChainId());
    console.log("network", chainId, network.name, network.live);

    const namedAccounts = await getNamedAccounts();
    ({ minter, tester1, tester2, random, treasury } = namedAccounts);

    minterSigner = provider.getSigner(minter);
    tester1Signer = provider.getSigner(tester1);
    randomSigner = provider.getSigner(random);

    if (!(await ethers.getContractOrNull("TheUbiquityStickSale"))) {
      console.log("Deploy TheUbiquityStickSale...");
      await deployments.fixture(["TheUbiquityStickSale"]);
    }
    theUbiquityStickSale = await ethers.getContract("TheUbiquityStickSale", minterSigner);
    theUbiquityStick = await ethers.getContract("TheUbiquityStick", minterSigner);
  });

  it("Check contract ok", async () => {
    expect(theUbiquityStickSale.address).to.be.properAddress;
    expect(await theUbiquityStickSale.owner()).to.be.properAddress;
  });

  describe("TheUbiquityStickSale view functions", () => {
    it("Check MAXIMUM_SUPPLY", async () => {
      expect(await theUbiquityStickSale.MAXIMUM_SUPPLY()).to.be.equal(MAXIMUM_SUPPLY);
    });
    it("Check tokenContract", async () => {
      expect(await theUbiquityStickSale.tokenContract()).to.be.equal(theUbiquityStick.address);
    });
    it("Check fundsAddress", async () => {
      expect(await theUbiquityStickSale.fundsAddress()).to.be.equal(treasury);
    });
    it("Check allowance", async () => {
      const allow = await theUbiquityStickSale.allowance(random);
      expect(allow.count).to.be.equal(0);
      expect(allow.price).to.be.equal(0);
    });
    it("Check owner", async () => {
      expect(await theUbiquityStickSale.owner()).to.be.equal(minter);
    });
  });

  describe("TheUbiquityStickSale set functions", () => {
    it("Check setTokenContract", async () => {
      await (await theUbiquityStickSale.setTokenContract(random)).wait();
      expect(await theUbiquityStickSale.tokenContract()).to.be.equal(random);
    });
    it("Check setFundsAddress", async () => {
      await (await theUbiquityStickSale.setFundsAddress(random)).wait();
      expect(await theUbiquityStickSale.fundsAddress()).to.be.equal(random);
    });
    it("Check setAllowance", async () => {
      await (await theUbiquityStickSale.setAllowance(random, count, price)).wait();
      const allow = await theUbiquityStickSale.allowance(random);
      expect(allow.count).to.be.equal(count);
      expect(allow.price).to.be.equal(price);
    });
    it("Check batchSetAllowances", async () => {
      await (await theUbiquityStickSale.batchSetAllowances([tester1, tester2], [count, count * 2], [one, price])).wait();
      const allow1 = await theUbiquityStickSale.allowance(tester1);
      expect(allow1.count).to.be.equal(count);
      expect(allow1.price).to.be.equal(one);
      const allow2 = await theUbiquityStickSale.allowance(tester2);
      expect(allow2.count).to.be.equal(count * 2);
      expect(allow2.price).to.be.equal(price);
    });
  });

  describe("TheUbiquityStickSale modifiers", () => {
    it("Check onlyOwner", async () => {
      await expect(theUbiquityStickSale.connect(tester1Signer).setTokenContract(random)).to.be.revertedWith("Ownable: caller is not the owner");
      await expect(theUbiquityStickSale.connect(tester1Signer).setFundsAddress(random)).to.be.revertedWith("Ownable: caller is not the owner");
      await expect(theUbiquityStickSale.connect(tester1Signer).setAllowance(random, count, one)).to.be.revertedWith("Ownable: caller is not the owner");
      await expect(
        theUbiquityStickSale.connect(tester1Signer).batchSetAllowances([tester1, tester2], [count, count * 2], [one, one.mul(3)])
      ).to.be.revertedWith("Ownable: caller is not the owner");
      await expect(theUbiquityStickSale.connect(tester1Signer).withdraw()).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("TheUbiquityStickSale Minting", () => {
    before(async () => {
      await (await theUbiquityStickSale.setTokenContract(theUbiquityStick.address)).wait();
      await (await theUbiquityStickSale.setFundsAddress(treasury)).wait();
    });

    afterEach(async () => {
      console.log(`Minted ${await theUbiquityStick.totalSupply()}`);
      console.log(`Balance Minter    ${utils.formatEther(await provider.getBalance(random))}`);
      console.log(`Balance Stick     ${utils.formatEther(await provider.getBalance(theUbiquityStickSale.address))}`);
      console.log(`Balance Treasury  ${utils.formatEther(await provider.getBalance(treasury))}`);
    });

    it("Check Mint 1", async () => {
      const totalSupplyBefore = await theUbiquityStick.totalSupply();
      await (await theUbiquityStickSale.setAllowance(random, 1, one)).wait();

      await (await randomSigner.sendTransaction({ to: theUbiquityStickSale.address, value: one.add(gas) })).wait();

      const totalSupplyAfter = await theUbiquityStick.totalSupply();
      expect(totalSupplyAfter.sub(totalSupplyBefore)).to.be.eq(1);
    });

    it("Check Mint 1 for free", async () => {
      const totalSupplyBefore = await theUbiquityStick.totalSupply();
      await (await theUbiquityStickSale.setAllowance(random, 1, 0)).wait();

      await (await randomSigner.sendTransaction({ to: theUbiquityStickSale.address, value: one.add(gas) })).wait();

      const totalSupplyAfter = await theUbiquityStick.totalSupply();
      expect(totalSupplyAfter.sub(totalSupplyBefore)).to.be.eq(1);
    });

    it("Check Mint 1 at double price", async () => {
      const totalSupplyBefore = await theUbiquityStick.totalSupply();
      await (await theUbiquityStickSale.setAllowance(random, 1, one.mul(2))).wait();

      await (await randomSigner.sendTransaction({ to: theUbiquityStickSale.address, value: one.mul(2).add(gas) })).wait();

      const totalSupplyAfter = await theUbiquityStick.totalSupply();
      expect(totalSupplyAfter.sub(totalSupplyBefore)).to.be.eq(1);
    });

    it("Check Mint not possible without allowance", async () => {
      await expect(randomSigner.sendTransaction({ to: theUbiquityStickSale.address, value: one.add(gas) })).to.be.revertedWith(
        "Not Whitelisted For The Sale Or Insufficient Allowance"
      );
    });

    it("Check Mint 10 maximum per transaction", async () => {
      const totalSupplyBefore = await theUbiquityStick.totalSupply();
      await (await theUbiquityStickSale.setAllowance(random, 100, one)).wait();

      await (await randomSigner.sendTransaction({ to: theUbiquityStickSale.address, value: one.mul(20).add(gas) })).wait();

      const totalSupplyAfter = await theUbiquityStick.totalSupply();
      expect(totalSupplyAfter.sub(totalSupplyBefore)).to.be.eq(10);
    });

    it("Check Mint not possible without enough funds", async () => {
      await (await theUbiquityStickSale.setAllowance(random, 1, one.mul(51))).wait();
      await expect(randomSigner.sendTransaction({ to: theUbiquityStickSale.address, value: one.mul(50).add(gas) })).to.be.revertedWith("Not enough Funds");
    });

    it("Check Mint and emit Mint event", async () => {
      const totalSupplyBefore = await theUbiquityStick.totalSupply();
      await (await theUbiquityStickSale.setAllowance(random, 2, one)).wait();

      await expect(randomSigner.sendTransaction({ to: theUbiquityStickSale.address, value: one.mul(2).add(gas) }))
        .to.emit(theUbiquityStickSale, "Mint")
        .withArgs(random, 2, one.mul(2));

      const totalSupplyAfter = await theUbiquityStick.totalSupply();
      expect(totalSupplyAfter.sub(totalSupplyBefore)).to.be.eq(2);
    });

    it("Check Mint emit Payback event", async () => {
      const balanceBefore = await provider.getBalance(random);
      const totalSupplyBefore = await theUbiquityStick.totalSupply();
      await (await theUbiquityStickSale.setAllowance(random, 3, one)).wait();

      await expect(randomSigner.sendTransaction({ to: theUbiquityStickSale.address, value: one.mul(4).add(gas) }))
        .to.emit(theUbiquityStickSale, "Payback")
        .withArgs(random, one.mul(1).add(gas));

      const totalSupplyAfter = await theUbiquityStick.totalSupply();
      expect(totalSupplyAfter.sub(totalSupplyBefore)).to.be.eq(3);

      const balanceAfter = await provider.getBalance(random);
      expect(balanceBefore.sub(balanceAfter)).to.be.gt(one.mul(3)).and.lt(one.mul(301).div(100));
    });

    it("Check intermediate withdraw", async () => {
      await expect(theUbiquityStickSale.withdraw()).to.be.not.reverted;
    });

    it("Check Mint not possible when Sold out", async () => {
      await (await theUbiquityStickSale.setAllowance(random, MAXIMUM_SUPPLY * 2, one)).wait();
      let i: number;
      for (i = 0; i < 101; i++) {
        process.stdout.write(`${i} `);
        await randomSigner.sendTransaction({ to: theUbiquityStickSale.address, value: one.mul(12).add(gas) });
      }
      console.log(i);
      await expect(randomSigner.sendTransaction({ to: theUbiquityStickSale.address, value: gas })).to.be.revertedWith("Sold Out");
      expect(await theUbiquityStick.totalSupply()).to.be.equal(MAXIMUM_SUPPLY);
    });

    it("Check final withdraw", async () => {
      await expect(theUbiquityStickSale.withdraw()).to.be.not.reverted;
    });
  });
});
