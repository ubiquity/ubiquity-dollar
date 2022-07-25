import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { expect } from "chai";

import { ABDKTest } from "../artifacts/types/ABDKTest";

describe("ADBK", () => {
  let abdk: ABDKTest;

  const maxABDK = BigNumber.from("0xffffffffffffffffffffffffffff800000000000000000000000000000000000");

  before(async () => {
    // deploy manager
    const abdkFactory = await ethers.getContractFactory("ABDKTest");
    abdk = (await abdkFactory.deploy()) as ABDKTest;
  });
  it("should return max uint128 at maximum", async () => {
    const max = await abdk.max();
    expect(max).to.be.lt(ethers.constants.MaxUint256);
    expect(max).to.equal(maxABDK);
  });
  it("should revert if overflow", async () => {
    const amountOK = BigNumber.from("11150372599265311570767859136324180752990207");
    const amountNOK = BigNumber.from("11150372599265311570767859136324180752990208");
    await expect(abdk.add(amountNOK)).to.be.reverted;
    const max = await abdk.add(amountOK);
    expect(max).to.equal(maxABDK);
  });
});
