import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { BigNumber } from "ethers";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { BondingShareV2 } from "../artifacts/types/BondingShareV2";
import { Bonding } from "../artifacts/types/Bonding";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { BondingFormulas } from "../artifacts/types/BondingFormulas";
import { MasterChefV2 } from "../artifacts/types/MasterChefV2";
import { BondingV2 } from "../artifacts/types/BondingV2";
import { mineNBlock, resetFork } from "../test/utils/hardhatNode";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts, ethers, network } = hre;

  // MIGRATION
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
  const toMigrateLpBalances = [
    "1301000000000000000",
    "3500000000000000000000",
    "9351040526163838324896",
    "44739174270101943975392",
    "74603879373206500005186",
    "2483850000000000000000",
    "1878674425540571814543",
    "8991650309086743220575",
    "1111050988607803612915",
    "4459109737462155546375",
    "21723000000000000000000",
    "38555895255762442000000",
    "5919236274824521937931",
    "1569191092350025897388",
    "10201450658519659933880",
    "890339946944155414434",
    "5021119790948940093253",
    "761000000000000000000",
    "49172294677407855270013",
    "25055256356185888278372",
    "1576757078627228869179",
    "3664000000000000000000",
    "1902189597146391302863",
    "34959771702943278635904",
    "9380006436252701023610",
    "6266995559166564365470",
    "100000000000000000000",
    "3696476262155265118082",
    "740480000000000000000",
    "2266000000000000000000",
    "1480607760433248019987",
    "24702171480214199310951",
    "605000000000000000000",
    "1694766661387270251234",
    "14857000000000000000000",
    "26000000000000000000",
  ];
  const toMigrateWeeks = [
    "1",
    "30",
    "208",
    "208",
    "208",
    "32",
    "208",
    "208",
    "4",
    "1",
    "67",
    "208",
    "208",
    "109",
    "12",
    "29",
    "1",
    "1",
    "3",
    "4",
    "7",
    "1",
    "128",
    "2",
    "4",
    "3",
    "208",
    "6",
    "1",
    "208",
    "2",
    "1",
    "12",
    "208",
    "4",
    "208",
  ];

  let ubq = "";
  let tester = "";
  ({ ubq, tester } = await getNamedAccounts());
  /**
   *  hardhat local
   *  */
  await resetFork(12926140);

  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [ubq],
  });

  const ubqAccount = ethers.provider.getSigner(ubq);
  const ubqAdr = await ubqAccount.getAddress();
  deployments.log(
    `*****
    ubqAdr address :`,
    ubqAdr,
    `
  `
  );
  const [admin] = await ethers.getSigners();
  const adminAdr = admin.address;
  const opts = {
    from: adminAdr,
    log: true,
  };

  let mgrAdr = "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98";
  let bondingV2deployAddress = "";
  let bondingFormulasdeployAddress = "";
  let bondingShareV2deployAddress = "";
  let masterchefV2deployAddress = "";

  // calculate end locking period block number
  // 1 week = 45361 blocks = 2371753*7/366

  const UBQ_MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE"));
  const UBQ_BURNER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_BURNER_ROLE"));

  const PAUSER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("PAUSER_ROLE"));

  if (mgrAdr.length === 0) {
    const mgr = await deployments.deploy("UbiquityAlgorithmicDollarManager", {
      args: [adminAdr],
      ...opts,
    });
    mgrAdr = mgr.address;
  }

  const mgrFactory = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");

  const manager: UbiquityAlgorithmicDollarManager = mgrFactory.attach(
    mgrAdr // mgr.address
  ) as UbiquityAlgorithmicDollarManager;

  const ubqFactory = await ethers.getContractFactory("UbiquityGovernance");
  const ubqGovAdr = "0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0";
  const ubiquityGovernance: UbiquityGovernance = ubqFactory.attach(ubqGovAdr) as UbiquityGovernance;

  deployments.log(`UbiquityAlgorithmicDollarManager deployed at:`, manager.address);
  const currentBondingAdr = await manager.bondingContractAddress();
  deployments.log("current Bonding Adr :", currentBondingAdr);
  const currentMSAdr = await manager.masterChefAddress();
  deployments.log("current Masterchef Adr :", currentMSAdr);
  let tx = await manager.connect(ubqAccount).revokeRole(UBQ_MINTER_ROLE, currentMSAdr);
  await tx.wait();
  tx = await manager.connect(ubqAccount).revokeRole(UBQ_MINTER_ROLE, currentBondingAdr);
  await tx.wait();
  tx = await manager.connect(ubqAccount).revokeRole(UBQ_BURNER_ROLE, currentBondingAdr);
  await tx.wait();

  const isMSMinter = await manager.connect(ubqAccount).hasRole(UBQ_MINTER_ROLE, currentMSAdr);
  deployments.log("Master Chef Is minter ?:", isMSMinter);
  const isBSMinter = await manager.connect(ubqAccount).hasRole(UBQ_MINTER_ROLE, currentBondingAdr);
  deployments.log("Bonding Is minter ?:", isBSMinter);

  // BondingShareV2
  const uri = `{
    "name": "Bonding Share",
    "description": "Ubiquity Bonding Share V2",
    "image": "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/"
  }`;
  if (bondingShareV2deployAddress.length === 0) {
    const bondingShareV2deploy = await deployments.deploy("BondingShareV2", {
      args: [manager.address, uri],
      ...opts,
    });

    bondingShareV2deployAddress = bondingShareV2deploy.address;
  }
  /* */
  const bondingShareV2Factory = await ethers.getContractFactory("BondingShareV2");

  const bondingShareV2: BondingShareV2 = bondingShareV2Factory.attach(bondingShareV2deployAddress) as BondingShareV2;
  deployments.log("BondingShareV2 deployed at:", bondingShareV2.address);
  tx = await manager.connect(ubqAccount).setBondingShareAddress(bondingShareV2.address);
  await tx.wait();
  const managerBondingShareAddress = await manager.bondingShareAddress();
  deployments.log("BondingShareV2 in Manager is set to:", managerBondingShareAddress);
  // MasterchefV2

  if (masterchefV2deployAddress.length === 0) {
    const masterchefV2deploy = await deployments.deploy("MasterChefV2", {
      args: [manager.address],
      ...opts,
    });

    masterchefV2deployAddress = masterchefV2deploy.address;
  }
  /* */
  const masterChefV2Factory = await ethers.getContractFactory("MasterChefV2");

  const masterChefV2: MasterChefV2 = masterChefV2Factory.attach(masterchefV2deployAddress) as MasterChefV2;
  deployments.log("MasterChefV2 deployed at:", masterChefV2.address);
  tx = await manager.connect(ubqAccount).setMasterChefAddress(masterChefV2.address);
  await tx.wait();
  tx = await manager.connect(ubqAccount).grantRole(UBQ_MINTER_ROLE, masterChefV2.address);
  await tx.wait();
  const managerMasterChefV2Address = await manager.masterChefAddress();
  deployments.log("masterChefAddress in Manager is set to:", managerMasterChefV2Address);
  // Bonding Formula

  if (bondingFormulasdeployAddress.length === 0) {
    const bondingFormulas = await deployments.deploy("BondingFormulas", {
      args: [],
      ...opts,
    });
    bondingFormulasdeployAddress = bondingFormulas.address;
  }

  const bondingFormulasFactory = await ethers.getContractFactory("BondingFormulas");

  const bf: BondingFormulas = bondingFormulasFactory.attach(bondingFormulasdeployAddress) as BondingFormulas;
  deployments.log("BondingFormulas deployed at:", bf.address);
  // BondingV2

  deployments.log("bondingFormulasdeployAddress :", bondingFormulasdeployAddress);
  deployments.log("manager.address :", manager.address);
  if (bondingV2deployAddress.length === 0) {
    const bondingV2deploy = await deployments.deploy("BondingV2", {
      args: [manager.address, bondingFormulasdeployAddress, toMigrateOriginals, toMigrateLpBalances, toMigrateWeeks],
      ...opts,
    });

    bondingV2deployAddress = bondingV2deploy.address;
  }
  deployments.log("bondingV2deployAddress :", bondingV2deployAddress);
  /* */
  const bondingV2Factory = await ethers.getContractFactory("BondingV2");

  const bondingV2: BondingV2 = bondingV2Factory.attach(bondingV2deployAddress) as BondingV2;
  deployments.log("bondingV2 deployed at:", bondingV2.address);
  tx = await bondingV2.setMigrating(true);
  await tx.wait();
  deployments.log("setMigrating to true");
  // send the LP token from bonding V1 to V2 to prepare the migration
  const bondingFactory = await ethers.getContractFactory("Bonding");
  const metaPoolAddr = await manager.connect(admin).stableSwapMetaPoolAddress();
  const metaPool = (await ethers.getContractAt("IMetaPool", metaPoolAddr)) as IMetaPool;

  const bondingLPBal = await metaPool.balanceOf(currentBondingAdr);
  deployments.log("bondingLPBal :", ethers.utils.formatEther(bondingLPBal));
  const bonding: Bonding = bondingFactory.attach(currentBondingAdr) as Bonding;
  await bonding.connect(ubqAccount).sendDust(bondingV2.address, metaPool.address, bondingLPBal);
  const bondingV2LPBal = await metaPool.balanceOf(bondingV2.address);
  deployments.log("all bondingLPBal sent to bondingV2... bondingV2LPBal:", ethers.utils.formatEther(bondingV2LPBal));
  // bondingV2 should have the UBQ_MINTER_ROLE to mint bonding shares
  const isUBQPauser = await manager.connect(ubqAccount).hasRole(PAUSER_ROLE, ubqAdr);
  deployments.log("UBQ Is pauser ?:", isUBQPauser);

  tx = await manager.connect(ubqAccount).grantRole(UBQ_MINTER_ROLE, bondingV2.address);
  await tx.wait();
  tx = await bondingV2.connect(ubqAccount).setBlockCountInAWeek(46550);
  await tx.wait();
  const blockCountInAWeek = await bondingV2.blockCountInAWeek();
  deployments.log("bondingV2 blockCountInAWeek:", blockCountInAWeek);
  tx = await manager.connect(ubqAccount).setBondingContractAddress(bondingV2.address);
  await tx.wait();
  const managerBondingV2Address = await manager.bondingContractAddress();
  deployments.log("BondingV2 in Manager is set to:", managerBondingV2Address);

  const ismasterChefV2Minter = await manager.connect(ubqAccount).hasRole(UBQ_MINTER_ROLE, masterChefV2.address);
  deployments.log("MasterChef V2 Is minter ?:", ismasterChefV2Minter);
  const isbondingShareV2Minter = await manager.connect(ubqAccount).hasRole(UBQ_MINTER_ROLE, bondingV2.address);
  deployments.log("Bonding V2 Is minter ?:", isbondingShareV2Minter);

  // try to migrate test

  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [tester],
  });
  const testAccount = ethers.provider.getSigner(tester);
  const idsBefore = await bondingShareV2.holderTokens(tester);
  deployments.log("idsBefore:", idsBefore);
  const testerLPBalBeforeMigrate = await metaPool.balanceOf(tester);
  const totalLpToMigrateBeforeMigrate = await bondingV2.totalLpToMigrate();
  tx = await bondingV2.connect(testAccount).migrate();
  await tx.wait();
  const totalLpToMigrateAfterMigrate = await bondingV2.totalLpToMigrate();
  const idsAfter = await bondingShareV2.holderTokens(tester);
  const testerLPRewardsAfterMigrate = await bondingV2.pendingLpRewards(idsAfter[0]);
  deployments.log("idsAfter:", idsAfter[0].toNumber());
  let bond = await bondingShareV2.getBond(idsAfter[0]);
  deployments.log(`bond id:${idsAfter[0].toNumber()}
           minter:${bond.minter}
           lpAmount:${ethers.utils.formatEther(bond.lpAmount)}
           lpFirstDeposited:${ethers.utils.formatEther(bond.lpFirstDeposited)}
           endBlock:${bond.endBlock.toNumber()}
           tx:${tx.blockNumber ? tx.blockNumber.toString() : ""}
  `);

  const pendingUGOV = await masterChefV2.pendingUGOV(idsAfter[0]);
  const bondingShareInfo = await masterChefV2.getBondingShareInfo(idsAfter[0]);
  deployments.log(`pendingUGOV :${ethers.utils.formatEther(pendingUGOV)}
  bondingShareInfo-0 :${ethers.utils.formatEther(bondingShareInfo[0])}
  bondingShareInfo-1 :${ethers.utils.formatEther(bondingShareInfo[1])}
`);
  const ubqBalBefore = await ubiquityGovernance.balanceOf(tester);
  await mineNBlock(blockCountInAWeek.toNumber());

  const pendingUGOV2 = await masterChefV2.pendingUGOV(idsAfter[0]);
  const bondingShareInfo2 = await masterChefV2.getBondingShareInfo(idsAfter[0]);
  deployments.log(`pendingUGOV2 :${ethers.utils.formatEther(pendingUGOV2)}
  bondingShareInfo2-0 :${ethers.utils.formatEther(bondingShareInfo2[0])}
  bondingShareInfo2-1 :${ethers.utils.formatEther(bondingShareInfo2[1])}
`);
  tx = await masterChefV2.connect(testAccount).getRewards(idsAfter[0]);
  await tx.wait();
  const ubqBalAfter = await ubiquityGovernance.balanceOf(tester);
  deployments.log(`
  ubqBalBefore  :${ethers.utils.formatEther(ubqBalBefore)}
  ubqBalAfter  :${ethers.utils.formatEther(ubqBalAfter)}
  bond.endblock:${bond.endBlock.toString()}
  tx:${tx.blockNumber ? tx.blockNumber.toString() : ""}
`);
  tx = await bondingV2.connect(testAccount).removeLiquidity(bond.lpAmount, idsAfter[0]);
  await tx.wait();
  bond = await bondingShareV2.getBond(idsAfter[0]);
  deployments.log(`old bond id:${idsAfter[0].toNumber()}
  minter:${bond.minter}
  lpAmount:${ethers.utils.formatEther(bond.lpAmount)}
  lpFirstDeposited:${ethers.utils.formatEther(bond.lpFirstDeposited)}
  endBlock:${bond.endBlock.toNumber()}
  tx:${tx.blockNumber ? tx.blockNumber.toString() : ""}
`);

  const testerLPRewardsAfterRemove = await bondingV2.pendingLpRewards(idsAfter[0]);
  deployments.log(`
  testerLPRewardsAfterMigrate  :${ethers.utils.formatEther(testerLPRewardsAfterMigrate)}
  testerLPRewardsAfterRemove  :${ethers.utils.formatEther(testerLPRewardsAfterRemove)}
`);
  const testerLPBalAfterMigrate = await metaPool.balanceOf(tester);
  deployments.log(`
  LPBalBefore  :${ethers.utils.formatEther(testerLPBalBeforeMigrate)}
  LPBalAfter  :${ethers.utils.formatEther(testerLPBalAfterMigrate)}
`);
  deployments.log(`
totalLpToMigrateBeforeMigrate  :${ethers.utils.formatEther(totalLpToMigrateBeforeMigrate)}
totalLpToMigrateAfterMigrate  :${ethers.utils.formatEther(totalLpToMigrateAfterMigrate)}
`);

  tx = await metaPool.connect(testAccount).approve(bondingV2.address, testerLPBalAfterMigrate);
  await tx.wait();
  const addAmount = testerLPBalAfterMigrate.div(BigNumber.from(2));
  deployments.log(`
  addAmount  :${ethers.utils.formatEther(addAmount)}

  `);
  tx = await bondingV2.connect(testAccount).addLiquidity(addAmount, idsAfter[0], 42);
  await tx.wait();
  const testerLPBalAfterAdd = await metaPool.balanceOf(tester);
  tx = await bondingV2.connect(testAccount).deposit(testerLPBalAfterAdd, 208);
  await tx.wait();
  const testerBsIds = await bondingShareV2.holderTokens(tester);
  deployments.log(`
  testerBsIds length  :${testerBsIds.length}
  idsAfter[0]  :${idsAfter[0].toString()}
  testerBsIds[0]  :${testerBsIds[0].toString()}
  testerBsIds[1]  :${testerBsIds[1].toString()}
  `);
  bond = await bondingShareV2.getBond(idsAfter[0]);
  deployments.log(`old bond id:${idsAfter[0].toNumber()}
  minter:${bond.minter}
  lpAmount:${ethers.utils.formatEther(bond.lpAmount)}
  lpFirstDeposited:${ethers.utils.formatEther(bond.lpFirstDeposited)}
  endBlock:${bond.endBlock.toNumber()}
  tx:${tx.blockNumber ? tx.blockNumber.toString() : ""}
`);

  const bond1 = await bondingShareV2.getBond(testerBsIds[0]);
  deployments.log(`bond1 id:${testerBsIds[0].toNumber()}
  minter:${bond1.minter}
  lpAmount:${ethers.utils.formatEther(bond1.lpAmount)}
  lpFirstDeposited:${ethers.utils.formatEther(bond1.lpFirstDeposited)}
  endBlock:${bond1.endBlock.toNumber()}
  tx:${tx.blockNumber ? tx.blockNumber.toString() : ""}
`);
  const bond2 = await bondingShareV2.getBond(testerBsIds[1]);
  deployments.log(`bond2 id:${testerBsIds[1].toNumber()}
  minter:${bond2.minter}
  lpAmount:${ethers.utils.formatEther(bond2.lpAmount)}
  lpFirstDeposited:${ethers.utils.formatEther(bond2.lpFirstDeposited)}
  endBlock:${bond2.endBlock.toNumber()}
  tx:${tx.blockNumber ? tx.blockNumber.toString() : ""}
`);

  await mineNBlock(blockCountInAWeek.toNumber());

  const pendingBond1 = await masterChefV2.pendingUGOV(testerBsIds[0]);
  const pendingBond2 = await masterChefV2.pendingUGOV(testerBsIds[1]);
  const bondingShareInfoBond1 = await masterChefV2.getBondingShareInfo(testerBsIds[0]);
  const bondingShareInfoBond2 = await masterChefV2.getBondingShareInfo(testerBsIds[1]);
  const totalShares = await masterChefV2.totalShares();
  deployments.log(`

  pendingBond1 :${ethers.utils.formatEther(pendingBond1)}
  pendingBond2 :${ethers.utils.formatEther(pendingBond2)}
  bondingShareInfoBond1-0 :${ethers.utils.formatEther(bondingShareInfoBond1[0])}
  bondingShareInfoBond1-1 :${ethers.utils.formatEther(bondingShareInfoBond1[1])}
  bondingShareInfoBond2-0 :${ethers.utils.formatEther(bondingShareInfoBond2[0])}
  bondingShareInfoBond2-1 :${ethers.utils.formatEther(bondingShareInfoBond2[1])}
  totalShares :${ethers.utils.formatEther(totalShares)}
`);

  deployments.log(`
    That's all folks !
    `);
};
export default func;
func.tags = ["V2Test"];
