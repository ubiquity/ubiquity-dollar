import { Signer } from "ethers";
import "hardhat-deploy";
import { ActionType } from "hardhat/types";
import { ICurveFactory } from "../../../artifacts/types/ICurveFactory";
import { TWAPOracle } from "../../../artifacts/types/TWAPOracle";
import pressAnyKey from "../../utils/flow";
import { afterBalances } from "./afterBalances";
import { balancesAndCalculations } from "./balancesAndCalculations";
import { dryRunner } from "./dryRunner";
import { getAddresses } from "./getAddresses";
import { read3crvInfo } from "./read3crvInfo";
import { setDefaultParams } from "./setDefaultParams";
import { TaskArgs } from "../price-reset-i";

export const priceResetter = (): ActionType<any> => async (taskArgs: TaskArgs, { ethers, network, getNamedAccounts }) => {
  setDefaultParams(taskArgs);

  const net = await ethers.provider.getNetwork();
  const resetFork = async (blockNumber: number): Promise<void> => {
    await network.provider.request({
      method: "hardhat_reset",
      params: [{ forking: { jsonRpcUrl: `https://eth-mainnet.alchemyapi.io/v2/${process.env.API_KEY_ALCHEMY || ""}`, blockNumber } }],
    });
  };

  var admin: Signer;
  var adminAdr: string;

  if (taskArgs.dryRun) {
    ({ adminAdr, admin } = await dryRunner({ resetFork, taskArgs, network, ethers }));
  } else {
    const accounts = await ethers.getSigners();
    adminAdr = await accounts[0].getAddress();
    [admin] = accounts;
  }

  const amount = ethers.utils.parseEther(taskArgs.amount);
  console.log(`---account addr:${adminAdr}  `);
  var { curveFactory, DAI, USDC, USDT, uAD, treasuryAddr, curveToken, metaPool, bondingAddr, manager, curve3CrvToken, bonding } = await getAddresses({
    getNamedAccounts,
    net,
    ethers,
  });
  ({ curveFactory, DAI, USDC, USDT } = await getNamedAccounts());
  const curvePoolFactory = (await ethers.getContractAt("ICurveFactory", curveFactory)) as ICurveFactory;
  const { LPBal, expectedUADStr, expectedCRVStr, crvTreasuryBalanceBefore, uadTreasuryBalanceBefore } = await balancesAndCalculations({
    uAD,
    treasuryAddr,
    curveToken,
    metaPool,
    bondingAddr,
    ethers,
    amount,
  });

  let coinIndex = 0;
  if (taskArgs.pushHigher) {
    console.warn(`we will remove :${taskArgs.amount} uAD-3CRV LP token from ${LPBal} uAD3CRV balance
                      sitting inside the bonding contract for an expected ${expectedUADStr} uAD unilateraly
                      This will have the immediate effect of
                      pushing the uAD price HIGHER`);
  } else {
    console.warn(`we will remove :${taskArgs.amount} uAD-3CRV LP token from ${LPBal} uAD3CRV balance
                      sitting inside the bonding contract for an expected ${expectedCRVStr} 3CRV unilateraly
                      This will have the immediate effect of
                      pushing the uAD price LOWER`);
    coinIndex = 1;
  }
  var { dyDAI2USDT, dyuAD2USDC, dyuAD2DAI, dyuAD2USDT, indices, indices2 } = await read3crvInfo({ curvePoolFactory, metaPool, DAI, USDT, uAD, USDC, ethers });

  const mgrtwapOracleAddress = await manager.twapOracleAddress();
  const twapOracle = (await ethers.getContractAt("TWAPOracle", mgrtwapOracleAddress)) as TWAPOracle;
  let oraclePriceuAD = await twapOracle.consult(uAD.address);
  let oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);
  console.log(`
    TWAP PRICE
    1 uAD => ${ethers.utils.formatEther(oraclePriceuAD)} 3CRV
    1 3CRV => ${ethers.utils.formatEther(oraclePrice3Crv)} uAD
      `);

  console.log(`
      Swap Price:
      1 DAI => ${ethers.utils.formatUnits(dyDAI2USDT, "mwei")} USDT
      1 uAD => ${ethers.utils.formatUnits(dyuAD2USDC, "mwei")} USDC
      1 uAD => ${ethers.utils.formatEther(dyuAD2DAI)} DAI
      1 uAD => ${ethers.utils.formatUnits(dyuAD2USDT, "mwei")} USDT
        `);
  let pool0UADbal = await metaPool.balances(0);
  let pool1CRVbal = await metaPool.balances(1);

  console.log(`
        pool0UADbal:${ethers.utils.formatEther(pool0UADbal)}
        pool1CRVbal:${ethers.utils.formatEther(pool1CRVbal)}
          `);
  await pressAnyKey("Press any key if you are sure you want to continue ...");

  let tx;
  if (coinIndex === 1) {
    tx = await bonding.connect(admin).crvPriceReset(amount);
  } else {
    tx = await bonding.connect(admin).uADPriceReset(amount);
  }

  console.log(`price reset waiting for confirmation`);
  let receipt = tx.wait(1);
  console.log(
    `tx ${(await receipt).status === 0 ? "FAIL" : "SUCCESS"}
        hash:${tx.hash}
        `
  );

  await afterBalances({
    uAD,
    treasuryAddr,
    curveToken,
    metaPool,
    bondingAddr,
    ethers,
    LPBal,
    crvTreasuryBalanceBefore,
    uadTreasuryBalanceBefore,
  });
  console.log(`test`);
  dyDAI2USDT = await metaPool["get_dy_underlying(int128,int128,uint256)"](indices[0], indices[1], ethers.utils.parseEther("1"));
  dyuAD2USDC = await metaPool["get_dy_underlying(int128,int128,uint256)"](indices2[0], indices2[1], ethers.utils.parseEther("1"));
  dyuAD2DAI = await metaPool["get_dy_underlying(int128,int128,uint256)"](indices2[0], indices[0], ethers.utils.parseEther("1"));
  dyuAD2USDT = await metaPool["get_dy_underlying(int128,int128,uint256)"](indices2[0], indices[1], ethers.utils.parseEther("1"));
  oraclePriceuAD = await twapOracle.consult(uAD.address);
  oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);

  console.log(`
    TWAP PRICE that doesn't reflect the remove liquidity yet
    1 uAD => ${ethers.utils.formatEther(oraclePriceuAD)} 3CRV
    1 3CRV => ${ethers.utils.formatEther(oraclePrice3Crv)} uAD
      `);
  console.log(`
      Swap Price:
        1 DAI => ${ethers.utils.formatUnits(dyDAI2USDT, "mwei")} USDT
        1 uAD => ${ethers.utils.formatUnits(dyuAD2USDC, "mwei")} USDC
        1 uAD => ${ethers.utils.formatEther(dyuAD2DAI)} DAI
        1 uAD => ${ethers.utils.formatUnits(dyuAD2USDT, "mwei")} USDT
          `);
  tx = await metaPool.connect(admin)["remove_liquidity_one_coin(uint256,int128,uint256)"](1, coinIndex, 0);
  console.log(`We execute another action (swap,deposit,withdraw etc..)
                   on the curve pool to update the twap price`);
  receipt = tx.wait(1);
  oraclePriceuAD = await twapOracle.consult(uAD.address);
  oraclePrice3Crv = await twapOracle.consult(curve3CrvToken);

  console.log(`
    TWAP PRICE Updated
    1 uAD => ${ethers.utils.formatEther(oraclePriceuAD)} 3CRV
    1 3CRV => ${ethers.utils.formatEther(oraclePrice3Crv)} uAD
      `);
  pool0UADbal = await metaPool.balances(0);
  pool1CRVbal = await metaPool.balances(1);

  console.log(`
        pool0UADbal:${ethers.utils.formatEther(pool0UADbal)}
        pool1CRVbal:${ethers.utils.formatEther(pool1CRVbal)}
          `);
};
