import { BigNumber, Signer } from "ethers";
import { ethers, getNamedAccounts } from "hardhat";
import { expect } from "chai";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { MockuADToken } from "../artifacts/types/MockuADToken";
import { MockTWAPOracle } from "../artifacts/types/MockTWAPOracle";
import { DollarMintingCalculator } from "../artifacts/types/DollarMintingCalculator";
import { calcDollarsToMint, isAmountEquivalent } from "./utils/calc";

describe("DollarMintingCalculator", () => {
  let metaPoolAddr: string;
  let curve3CrvToken: string;
  let manager: UbiquityAlgorithmicDollarManager;
  let twapOracle: MockTWAPOracle;
  let dollarMintingCalculator: DollarMintingCalculator;
  let admin: Signer;
  let uAD: MockuADToken;

  const setup = async (uADTotalSupply: BigNumber, priceUAD: BigNumber, price3CRV: BigNumber) => {
    // set uAD Mock
    const UAD = await ethers.getContractFactory("MockuADToken");
    uAD = (await UAD.deploy(uADTotalSupply)) as MockuADToken;

    await manager.setDollarTokenAddress(uAD.address);
    // set TWAP Oracle Mock

    const TWAPOracleFactory = await ethers.getContractFactory("MockTWAPOracle");
    twapOracle = (await TWAPOracleFactory.deploy(metaPoolAddr, uAD.address, curve3CrvToken, priceUAD, price3CRV)) as MockTWAPOracle;

    await manager.setTwapOracleAddress(twapOracle.address);
  };

  beforeEach(async () => {
    ({ curve3CrvToken } = await getNamedAccounts());
    // list of accounts
    [admin] = await ethers.getSigners();
    // deploy manager
    const UADMgr = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");
    manager = (await UADMgr.deploy(await admin.getAddress())) as UbiquityAlgorithmicDollarManager;

    // setup the oracle
    metaPoolAddr = await manager.stableSwapMetaPoolAddress();

    // set Dollar Minting Calculator
    const dollarMintingCalculatorFactory = await ethers.getContractFactory("DollarMintingCalculator");
    dollarMintingCalculator = (await dollarMintingCalculatorFactory.deploy(manager.address)) as DollarMintingCalculator;
    await manager.setDollarMintingCalculatorAddress(dollarMintingCalculator.address);
  });
  it("getDollarsToMint should revert with price less than 1$", async () => {
    const totSupply = ethers.utils.parseEther("10000");
    const uadPrice = ethers.utils.parseEther("0.9");
    const price3CRV = ethers.utils.parseEther("1");
    await setup(totSupply, uadPrice, price3CRV);
    await expect(dollarMintingCalculator.getDollarsToMint()).to.be.reverted;
  });
  it("getDollarsToMint should return zero with price equal to 1$", async () => {
    const totSupply = ethers.utils.parseEther("10000");
    const uadPrice = ethers.utils.parseEther("1");
    await setup(totSupply, uadPrice, uadPrice);
    const toMint = await dollarMintingCalculator.getDollarsToMint();
    expect(toMint).to.equal(0);
  });
  it("getDollarsToMint should return 10% of total supply with price equal to 1.1$", async () => {
    const totSupply = ethers.utils.parseEther("10000");
    const uadPrice = ethers.utils.parseEther("1.1");
    await setup(totSupply, uadPrice, uadPrice);
    const toMint = await dollarMintingCalculator.getDollarsToMint();
    expect(toMint).to.equal(ethers.utils.parseEther("1000"));
  });
  it("getDollarsToMint should work with price above 1$", async () => {
    const totSupply = ethers.utils.parseEther("10000");
    const uadPrice = ethers.utils.parseEther("1.054678911145683254");
    await setup(totSupply, uadPrice, uadPrice);
    const toMint = await dollarMintingCalculator.getDollarsToMint();
    const calculatedToMint = calcDollarsToMint(totSupply.toString(), uadPrice.toString());
    expect(toMint).to.equal(calculatedToMint);
  });
  it("getDollarsToMint lose precision if supply is too large", async () => {
    const totSupply = ethers.utils.parseEther("99999999999999999999");

    const uadPrice = ethers.utils.parseEther("1.05467891114568354");
    await setup(totSupply, uadPrice, uadPrice);
    // check tfor overflow revert
    const toMint = await dollarMintingCalculator.getDollarsToMint();
    const calculatedToMint = calcDollarsToMint(totSupply.toString(), uadPrice.toString());

    // assert expected precision
    const isPrecise = isAmountEquivalent(calculatedToMint.toString(), toMint.toString());
    expect(isPrecise).to.be.true;
    expect(toMint).not.to.equal(calculatedToMint);
  });
  it("getDollarsToMint should work if supply is no too large", async () => {
    const totSupply = ethers.utils.parseEther("999999999999999");

    const uadPrice = ethers.utils.parseEther("1.054678911145683254");
    await setup(totSupply, uadPrice, uadPrice);
    // check tfor overflow revert
    const toMint = await dollarMintingCalculator.getDollarsToMint();
    const calculatedToMint = calcDollarsToMint(totSupply.toString(), uadPrice.toString());
    expect(toMint).to.equal(calculatedToMint);
  });
});
