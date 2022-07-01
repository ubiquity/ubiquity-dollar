// Should test UBQ claiming after migration

import { expect } from "chai";
import { ethers, network, getNamedAccounts } from "hardhat";
import { Signer } from "ethers";
import { MasterChef } from "../artifacts/types/MasterChef";
import { Staking } from "../artifacts/types/Staking";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { resetFork } from "./utils/hardhatNode";
import { IMetaPool } from "../artifacts/types/IMetaPool";

let masterChef: MasterChef;
let staking: Staking;
let metaPool: IMetaPool;

let ubq: string;
let MasterChefAddress: string;
let MetaPoolAddress: string;
let StakingAddress: string;
let StakingV2Address: string;
let UbqWhaleAddress: string;
let UbiquityAlgorithmicDollarManagerAddress: string;

let ubqAdmin: Signer;
let ubqWhale: Signer;
let manager: UbiquityAlgorithmicDollarManager;

const UBQ_MINTER_ROLE = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE")
);
const UBQ_BURNER_ROLE = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("UBQ_BURNER_ROLE")
);
const STAKING_MANAGER = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("STAKING_MANAGER")
);

describe("MasterChef UBQ rewards", () => {
  after(async () => {
    await resetFork(12592661);
  });
  beforeEach(async () => {
    await resetFork(12910000);
    ({
      ubq,
      UbqWhaleAddress,
      MasterChefAddress,
      MetaPoolAddress,
      StakingAddress,
      StakingV2Address,
      UbiquityAlgorithmicDollarManagerAddress,
    } = await getNamedAccounts());

    masterChef = (await ethers.getContractAt(
      "MasterChef",
      MasterChefAddress
    )) as MasterChef;

    manager = (await ethers.getContractAt(
      "UbiquityAlgorithmicDollarManager",
      UbiquityAlgorithmicDollarManagerAddress
    )) as UbiquityAlgorithmicDollarManager;

    staking = (await ethers.getContractAt(
      "Staking",
      StakingAddress
    )) as Staking;

    metaPool = (await ethers.getContractAt(
      "IMetaPool",
      MetaPoolAddress
    )) as IMetaPool;

    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [UbqWhaleAddress],
    });
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [ubq],
    });

    ubqAdmin = ethers.provider.getSigner(ubq);
    ubqWhale = ethers.provider.getSigner(UbqWhaleAddress);
  });

  describe("Claiming UBQ before migration", () => {
    it("Should get pending UBQ from whale address", async () => {
      expect(await masterChef.pendingUGOV(UbqWhaleAddress)).to.be.gt(1000);
    });

    it("Should claim UBQ rewards", async () => {
      await (await masterChef.connect(ubqWhale).getRewards()).wait();
      expect(await masterChef.pendingUGOV(UbqWhaleAddress)).to.be.equal(0);
    });
  });

  describe("Claiming UBQ after migration", () => {
    describe("Without MasterChef ROLES", () => {
      it("Should fail without MINTER_ROLE", async () => {
        const pendingUGOV = await masterChef.pendingUGOV(UbqWhaleAddress);
        await manager
          .connect(ubqAdmin)
          .revokeRole(UBQ_MINTER_ROLE, MasterChefAddress);

        await expect(
          masterChef.connect(ubqWhale).getRewards()
        ).to.be.revertedWith("Governance token: not minter");

        expect(await masterChef.pendingUGOV(UbqWhaleAddress)).to.be.gte(
          pendingUGOV
        );
      });

      it("Should work without BURNER_ROLE", async () => {
        await manager
          .connect(ubqAdmin)
          .revokeRole(UBQ_BURNER_ROLE, MasterChefAddress);

        await (await masterChef.connect(ubqWhale).getRewards()).wait();
        expect(await masterChef.pendingUGOV(UbqWhaleAddress)).to.be.equal(0);
      });
    });

    describe("Without Staking ROLES", () => {
      it("Should work without MINTER_ROLE", async () => {
        await manager
          .connect(ubqAdmin)
          .revokeRole(UBQ_MINTER_ROLE, StakingAddress);

        await (await masterChef.connect(ubqWhale).getRewards()).wait();
        expect(await masterChef.pendingUGOV(UbqWhaleAddress)).to.be.equal(0);
      });

      it("Should work without BURNER_ROLE", async () => {
        await manager
          .connect(ubqAdmin)
          .revokeRole(UBQ_BURNER_ROLE, StakingAddress);

        await (await masterChef.connect(ubqWhale).getRewards()).wait();
        expect(await masterChef.pendingUGOV(UbqWhaleAddress)).to.be.equal(0);
      });
    });

    describe("Without LP tokens", () => {
      it("Should work without LP tokens", async () => {
        const totalLP = await metaPool.balanceOf(StakingAddress);
        expect(totalLP).to.be.gt(0);

        await staking
          .connect(ubqAdmin)
          .sendDust(StakingV2Address, MetaPoolAddress, totalLP);

        expect(await metaPool.balanceOf(StakingAddress)).to.be.equal(0);

        await (await masterChef.connect(ubqWhale).getRewards()).wait();
        expect(await masterChef.pendingUGOV(UbqWhaleAddress)).to.be.equal(0);
      });
    });

    describe("Without LP, without MasterChef and Staking BURNER_ROLE, without Staking MINTER_ROLE", () => {
      it("Should work in real conditions", async () => {
        await manager.connect(ubqAdmin).grantRole(STAKING_MANAGER, ubq);
        await staking
          .connect(ubqAdmin)
          .sendDust(
            StakingV2Address,
            MetaPoolAddress,
            await metaPool.balanceOf(StakingAddress)
          );

        await manager
          .connect(ubqAdmin)
          .revokeRole(UBQ_BURNER_ROLE, MasterChefAddress);

        await manager
          .connect(ubqAdmin)
          .revokeRole(UBQ_BURNER_ROLE, StakingAddress);

        await manager
          .connect(ubqAdmin)
          .revokeRole(UBQ_MINTER_ROLE, StakingAddress);

        await (await masterChef.connect(ubqWhale).getRewards()).wait();
        expect(await masterChef.pendingUGOV(UbqWhaleAddress)).to.be.equal(0);
      });
    });
  });
});
