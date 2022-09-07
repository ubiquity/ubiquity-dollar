import { expect } from "chai";
import { BigNumber } from "ethers";
import { UbiquityFormulas } from "../artifacts/types/UbiquityFormulas";
import { bondingSetup } from "./BondingSetup";

describe("UbiquityFormulas", () => {
  const one: BigNumber = BigNumber.from(10).pow(18); // one = 1 ether = 10^18
  const ten9: BigNumber = BigNumber.from(10).pow(9); // ten9 = 10^-9 ether = 10^9
  const zzz1: BigNumber = BigNumber.from(10).pow(15); // zzz1 = zerozerozero1 = 0.0001 ether = 10^15

  let ubiquityFormulas: UbiquityFormulas;

  before(async () => {
    ({ ubiquityFormulas } = await bondingSetup());
  });

  describe("durationMultiply", () => {
    // durationMultiply(_uLP, _weeks, _multiplier) => (1 + _multiplier * _weeks ^ 3 / 2) * _uLP

    it("durationMultiply of 0 should be 1", async () => {
      const mult = await ubiquityFormulas.durationMultiply(one, 0, zzz1);

      expect(mult).to.eq(one);
    });

    it("durationMultiply of 1 should be 1.001", async () => {
      // 1.001000000 * 10**18 = 10**9 * 1001000000
      const mult = BigNumber.from(await ubiquityFormulas.durationMultiply(one, 1, zzz1));
      const epsilon = ten9.mul(1001000000).sub(mult);

      // 10**-9 expected precision on following calculations
      expect(epsilon.div(ten9)).to.be.equal(0);
    });

    it("durationMultiply of 6 should be 1.014696938", async () => {
      // 1.014696938 * 10**18 = 10**9 * 1014696938
      const mult = BigNumber.from(await ubiquityFormulas.durationMultiply(one, 6, zzz1));
      const epsilon = ten9.mul(1014696938).sub(mult);

      expect(epsilon.div(ten9)).to.be.equal(0);
    });

    it("durationMultiply of 24 should be 1.117575507", async () => {
      // 1.117575507 * 10**18 = 10**9 * 1117575507
      const mult = BigNumber.from(await ubiquityFormulas.durationMultiply(one, 24, zzz1));
      const epsilon = ten9.mul(1117575507).sub(mult);

      expect(epsilon.div(ten9)).to.be.equal(0);
    });

    it("durationMultiply of 52 should be 1.374977332", async () => {
      // 1.3749773326 * 10**18 = 10**9 * 1374977332
      const mult = BigNumber.from(await ubiquityFormulas.durationMultiply(one, 52, zzz1));
      const epsilon = ten9.mul(1374977332).sub(mult);

      expect(epsilon.div(ten9)).to.be.equal(0);
    });

    it("durationMultiply of 520 should be 12.857824421", async () => {
      // 12.857824421 * 10**18 = 10**10 * 12857824421
      const mult = BigNumber.from(await ubiquityFormulas.durationMultiply(one, 520, zzz1));
      const epsilon = ten9.mul(12857824421).sub(mult);

      expect(epsilon.div(ten9)).to.be.equal(0);
    });
  });

  describe("ugovMultiply", () => {
    // ugovMultiply(_multiplier, _price) => _multiplier * (1.05 / (1 + abs(1 - _price)))

    it("ugovMultiply of 0 should be 0", async () => {
      expect(await ubiquityFormulas.ugovMultiply(0, one)).to.be.equal(0);
    });
    it("ugovMultiply of 1 at price 1 should be 1.05", async () => {
      expect(await ubiquityFormulas.ugovMultiply(one, one)).to.be.equal(one.div(100).mul(105));
    });
    it("ugovMultiply of 2 at price 1 should be 2.1", async () => {
      expect(await ubiquityFormulas.ugovMultiply(one.mul(2), one)).to.be.equal(one.div(100).mul(210));
    });
    it("ugovMultiply of 4.99 at price 1 should be unchanged as above 5", async () => {
      expect(await ubiquityFormulas.ugovMultiply(one.div(100).mul(499), one)).to.be.equal(one.div(100).mul(499));
    });
    it("ugovMultiply of 0.35 at price 2 should be unchanged as bellow 0.2", async () => {
      expect(await ubiquityFormulas.ugovMultiply(one.div(100).mul(35), one.mul(2))).to.be.equal(one.div(100).mul(35));
    });
    it("ugovMultiply of 10 should be unchanged as above 5", async () => {
      expect(await ubiquityFormulas.ugovMultiply(one.mul(10), one)).to.be.equal(one.mul(10));
    });
    it("ugovMultiply of 1 at price 2.1 should be 0.5", async () => {
      expect(await ubiquityFormulas.ugovMultiply(one, one.div(100).mul(210))).to.be.equal(one.div(100).mul(50));
    });
    it("ugovMultiply of 3.46 at price 1.23 should be 2.953658536", async () => {
      expect((await ubiquityFormulas.ugovMultiply(one.div(100).mul(346), one.div(100).mul(123))).sub(ten9.mul(2953658536))).to.be.lt(ten9);
    });
  });
});
