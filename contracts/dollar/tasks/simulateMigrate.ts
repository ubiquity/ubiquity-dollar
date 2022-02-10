/* eslint-disable @typescript-eslint/no-loop-func */
/* eslint-disable @typescript-eslint/restrict-template-expressions */
/* eslint-disable @typescript-eslint/no-unsafe-call */
/* eslint-disable @typescript-eslint/no-unsafe-member-access */
/* eslint-disable @typescript-eslint/no-unsafe-assignment */

import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import { expect } from "chai";
import { BigNumber, Signer } from "ethers";

import { BondingShareV2 } from "../artifacts/types/BondingShareV2";
import { MasterChefV2 } from "../artifacts/types/MasterChefV2";
import { BondingV2 } from "../artifacts/types/BondingV2";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";

const lastBlock = 13004900;

const tos = [
  "0x89eae71b865a2a39cba62060ab1b40bbffae5b0d",
  "0x4007ce2083c7f3e18097aeb3a39bb8ec149a341d",
  "0x7c76f4db70b7e2177de10de3e2f668dadcd11108",
  "0x0000ce08fa224696a819877070bf378e8b131acf",
  "0xa53a6fe2d8ad977ad926c485343ba39f32d3a3f6",
  "0xcefd0e73cc48b0b9d4c8683e52b7d7396600abb2",
];
const amounts = [
  "1301000000000000000",
  "74603879373206500005186",
  "44739174270101943975392",
  "1480607760433248019987",
  "9351040526163838324896",
  "8991650309086743220575",
];
const ids = [1, 2, 3, 4, 5, 6];

const toMigrateOriginals = [
  "0x89eae71b865a2a39cba62060ab1b40bbffae5b0d",
  "0xefc0e701a824943b469a694ac564aa1eff7ab7dd",
  "0xa53a6fe2d8ad977ad926c485343ba39f32d3a3f6",
  "0x7c76f4db70b7e2177de10de3e2f668dadcd11108",
  "0x4007ce2083c7f3e18097aeb3a39bb8ec149a341d",
  "0xf6501068a54f3eab46c1f145cb9d3fb91658b220",
  "0x10693e86f2e7151b3010469e33b6c1c2da8887d6",
  "0xcefd0e73cc48b0b9d4c8683e52b7d7396600abb2",
  "0xd028babbdc15949aaa35587f95f9e96c7d49417d",
  "0x9968efe1424d802e1f79fd8af8da67b0f08c814d",
  "0xd3bc13258e685df436715104882888d087f87ed8",
  "0x0709b103d46d71458a71e5d81230dd688809a53d",
  "0xe3e39161d35e9a81edec667a5387bfae85752854",
  "0x7c361828849293684ddf7212fd1d2cb5f0aade70",
  "0x9d3f4eeb533b8e3c8f50dbbd2e351d1bf2987908",
  "0x865dc9a621b50534ba3d17e0ea8447c315e31886",
  "0x324e0b53cefa84cf970833939249880f814557c6",
  "0xce156d5d62a8f82326da8d808d0f3f76360036d0",
  "0x26bdde6506bd32bd7b5cc5c73cd252807ff18568",
  "0xd6efc21d8c941aa06f90075de1588ac7e912fec6",
  "0xe0d62cc9233c7e2f1f23fe8c77d6b4d1a265d7cd",
  "0x0b54b916e90b8f28ad21da40638e0724132c9c93",
  "0x629cd43eaf443e66a9a69ed246728e1001289eac",
  "0x0709e442a5469b88bb090dd285b1b3a63fb0c226",
  "0x94a2ffdbdbd84984ac7967878c5c397126e7bbbe",
  "0x51ec66e63199176f59c80268e0be6ffa91fab220",
  "0x0a71e650f70b35fca8b70e71e4441df8d44e01e9",
  "0xc1b6052e707dff9017deab13ae9b89008fc1fc5d",
  "0x9be95ef84676393588e49ad8b99c9d4cdfdaa631",
  "0xfffff6e70842330948ca47254f2be673b1cb0db7",
  "0x0000ce08fa224696a819877070bf378e8b131acf",
  "0xc2cb4b1bcaebaa78c8004e394cf90ba07a61c8f7",
  "0xb2812370f17465ae096ced55679428786734a678",
  "0x3eb851c3959f0d37e15c2d9476c4adb46d5231d1",
  "0xad286cf287b91719ee85d3ba5cf3da483d631dba",
  "0xbd37a957773d883186b989f6b21c209459022252",
];

task("simulateMigrate", "simulate migration of one address")
  .addOptionalParam("address", "The address to simulate migration")
  .setAction(async (taskArgs: { address: string }, { ethers, network }) => {
    const { address: paramAddress } = taskArgs;

    const UBQ_MINTER_ROLE = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE")
    );

    const UbiquityAlgorithmicDollarManagerAddress =
      "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98";
    let manager: UbiquityAlgorithmicDollarManager;

    const adminAddress = "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd";
    let admin: Signer;

    // const BondingShareV2BlockCreation = 12931486;
    const BondingShareV2Address = "0x2dA07859613C14F6f05c97eFE37B9B4F212b5eF5";
    let bondingShareV2: BondingShareV2;

    let masterChefV2: MasterChefV2;

    // const BondingV2BlockCreation = 12931495;
    const BondingV2Address = "0xC251eCD9f1bD5230823F9A0F99a44A87Ddd4CA38";
    let bondingV2: BondingV2;

    const mineBlock = async (timestamp: number): Promise<void> => {
      await network.provider.request({
        method: "evm_mine",
        params: [timestamp],
      });
    };

    const mineNBlock = async (
      blockCount: number,
      secondsBetweenBlock?: number
    ): Promise<void> => {
      const blockBefore = await ethers.provider.getBlock("latest");
      const maxMinedBlockPerBatch = 5000;
      let blockToMine = blockCount;
      let blockTime = blockBefore.timestamp;
      while (blockToMine > maxMinedBlockPerBatch) {
        // eslint-disable-next-line @typescript-eslint/no-loop-func
        const minings = [...Array(maxMinedBlockPerBatch).keys()].map(
          (_v, i) => {
            const newTs = blockTime + i + (secondsBetweenBlock || 1);
            return mineBlock(newTs);
          }
        );
        // eslint-disable-next-line no-await-in-loop
        await Promise.all(minings);
        blockToMine -= maxMinedBlockPerBatch;
        blockTime =
          blockTime +
          maxMinedBlockPerBatch -
          1 +
          maxMinedBlockPerBatch * (secondsBetweenBlock || 1);
      }
      const minings = [...Array(blockToMine).keys()].map((_v, i) => {
        const newTs = blockTime + i + (secondsBetweenBlock || 1);
        return mineBlock(newTs);
      });
      // eslint-disable-next-line no-await-in-loop
      await Promise.all(minings);
    };

    const resetFork = async (blockNumber: number): Promise<void> => {
      await network.provider.request({
        method: "hardhat_reset",
        params: [
          {
            forking: {
              jsonRpcUrl: `https://eth-mainnet.alchemyapi.io/v2/${
                process.env.ALCHEMY_API_KEY || ""
              }`,
              blockNumber,
            },
          },
        ],
      });
    };

    const newMasterChefV2 = async (): Promise<MasterChefV2> => {
      // deploy a NEW MasterChefV2 to debug
      // const newChefV2: MasterChefV2 = (await (
      //   await ethers.getContractFactory("MasterChefV2")
      // ).deploy(
      //   UbiquityAlgorithmicDollarManagerAddress,
      //   tos,
      //   amounts,
      //   ids
      // )) as MasterChefV2;
      const newChefV2: MasterChefV2 = (await ethers.getContractAt(
        "MasterChefV2",
        "0xdae807071b5AC7B6a2a343beaD19929426dBC998"
      )) as MasterChefV2;

      await manager.connect(admin).setMasterChefAddress(newChefV2.address);
      await manager
        .connect(admin)
        .grantRole(UBQ_MINTER_ROLE, newChefV2.address);

      return newChefV2;
    };

    const init = async (block: number): Promise<void> => {
      await resetFork(block);
      await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [adminAddress],
      });

      admin = ethers.provider.getSigner(adminAddress);

      manager = (await ethers.getContractAt(
        "UbiquityAlgorithmicDollarManager",
        UbiquityAlgorithmicDollarManagerAddress
      )) as UbiquityAlgorithmicDollarManager;

      bondingShareV2 = (await ethers.getContractAt(
        "BondingShareV2",
        BondingShareV2Address
      )) as BondingShareV2;

      masterChefV2 = await newMasterChefV2();

      bondingV2 = (await ethers.getContractAt(
        "BondingV2",
        BondingV2Address
      )) as BondingV2;
    };

    const query = async (
      bondId: number,
      log = false
    ): Promise<
      [
        BigNumber,
        BigNumber,
        BigNumber,
        BigNumber,
        BigNumber,
        BigNumber,
        BigNumber,
        BigNumber,
        BigNumber,
        number
      ]
    > => {
      const block = await ethers.provider.getBlockNumber();
      const uGOVmultiplier = await masterChefV2.uGOVmultiplier();
      const totalShares = await masterChefV2.totalShares();
      const [lastRewardBlock, accuGOVPerShare] = await masterChefV2.pool();
      const totalSupply = await bondingShareV2.totalSupply();
      const totalLP = await bondingShareV2.totalLP();

      const pendingUGOV = await masterChefV2.pendingUGOV(bondId);
      const [amount, rewardDebt] = await masterChefV2.getBondingShareInfo(
        bondId
      );
      const bond = await bondingShareV2.getBond(bondId);

      if (log) {
        console.log(`BLOCK:${block}`);
        console.log("uGOVmultiplier", ethers.utils.formatEther(uGOVmultiplier));
        console.log("totalShares", ethers.utils.formatEther(totalShares));
        console.log("lastRewardBlock", lastRewardBlock.toString());
        console.log(
          "accuGOVPerShare",
          ethers.utils.formatUnits(accuGOVPerShare.toString(), 12)
        );
        console.log("totalSupply", totalSupply.toString());
        console.log("totalLP", totalLP.toString());

        if (bondId) {
          console.log(`BOND:${bondId}`);
          console.log("pendingUGOV", ethers.utils.formatEther(pendingUGOV));
          console.log("amount", ethers.utils.formatEther(amount));
          console.log("rewardDebt", ethers.utils.formatEther(rewardDebt));
          console.log("bond", bond.toString());
        }
      }
      return [
        totalShares,
        accuGOVPerShare,
        pendingUGOV,
        amount,
        rewardDebt,
        totalSupply,
        totalLP,
        uGOVmultiplier,
        lastRewardBlock,
        block,
      ];
    };

    const migrate = async (_address: string) => {
      console.log(`\n>> Address ${_address}`);

      const whaleAdress = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
      await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [_address],
      });
      await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [whaleAdress],
      });
      const whale = ethers.provider.getSigner(whaleAdress);
      const account = ethers.provider.getSigner(_address);
      await whale.sendTransaction({
        to: _address,
        value: BigNumber.from(10).pow(18).mul(10),
      });

      await bondingV2.connect(admin).setMigrating(true);
      try {
        const tx = await bondingV2.connect(account).migrate();

        const { events } = await tx.wait();
        const args = events?.find((event) => event.event === "Migrated")?.args;
        const user = args && args[0]?.toString();
        const id = args && args[1].toString();
        const lpsAmount = args && ethers.utils.formatEther(args[2]);
        const sharesAmount = args && args[3];
        const weeks = args && args[4];

        expect(user?.toLowerCase()).to.be.equal(_address.toLowerCase());
        expect(id).to.be.equal(
          (await bondingShareV2.holderTokens(_address))[0].toString()
        );

        // mine some blocks to get pendingUGOV
        await mineNBlock(100);

        const res = await query(id);
        expect(res[3]).to.be.equal(sharesAmount);

        const totalShares = ethers.utils.formatEther(res[0]);
        const accuGOVPerShare = ethers.utils.formatUnits(res[1], 12);
        const pendingUGOV = ethers.utils.formatEther(res[2]);
        const amount = ethers.utils.formatEther(res[3]);
        // const rewardDebt = ethers.utils.formatEther(res[4]);
        const totalSupply = res[5];
        const totalLP = ethers.utils.formatEther(res[6]);
        const uGOVmultiplier = ethers.utils.formatEther(res[7]);
        const lastRewardBlock = res[8].toString();
        const block = res[9];

        console.log(
          `>> ${lpsAmount} uAD3CRV-f locked ${weeks} weeks Migrated to Bond #${id}`
        );
        console.log(`>> ${amount} UBQ  and ${pendingUGOV} UBQ pending`);
        console.log(
          `== Block ${block}  Last Reward Block ${lastRewardBlock}  Total Bond ${totalSupply}  UBQ Rewards per Block ${uGOVmultiplier}`
        );
        console.log(
          `== Total uAD3CRV-f ${totalLP}  Total UBQ ${totalShares}  Total UBQ Accumulated per Share ${accuGOVPerShare}`
        );
      } catch (e) {
        console.log(`** ERROR ${(e as Error).message}`);
      }
    };

    await init(lastBlock);
    if (paramAddress) {
      await migrate(paramAddress);
    } else {
      for (let i = 0; i < toMigrateOriginals.length; i += 1) {
        // eslint-disable-next-line no-await-in-loop
        await migrate(toMigrateOriginals[i]);
      }
    }
  });
