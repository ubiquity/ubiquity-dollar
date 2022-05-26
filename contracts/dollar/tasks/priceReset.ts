import { task, types } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import { Signer } from "ethers";
import * as dotenv from "dotenv";


import { ICurveFactory } from "../artifacts/types/ICurveFactory";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { BondingV2 } from "../artifacts/types/BondingV2";
import { ERC20 } from "../artifacts/types/ERC20";
import pressAnyKey from "../utils/flow";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { EthereumProvider } from "hardhat/types";
import { JsonRpcProvider } from "@ethersproject/providers";

dotenv.config();

const {
  API_KEY_ALCHEMY
} = process.env;

task(
  "priceReset",
  "PriceReset can push uAD price lower or higher by burning LP token for uAD or 3CRV from the bonding contract"
)
  .addParam("amount", "The amount of uAD-3CRV LP token to be withdrawn")
  .addOptionalParam(
    "pushhigher",
    "if false will withdraw 3CRV to push uAD price lower",
    true,
    types.boolean
  )
  .addOptionalParam(
    "dryrun",
    "if false will use account 0 to execute price reset",
    true,
    types.boolean
  )
  .addOptionalParam(
    "blockheight",
    "block height for the fork",
    14800000,
    types.int
  )
  .setAction(
    async (
      taskArgs: {
        amount: string;
        pushhigher: boolean;
        dryrun: boolean;
        blockheight: number;
      },
      { ethers, network, getNamedAccounts }
    ) => {
      const net = await ethers.provider.getNetwork();
      const resetFork = async (blockNumber: number): Promise<void> => {
        await network.provider.request({
          method: "hardhat_reset",
          params: [
            {
              forking: {
                jsonRpcUrl: `https://eth-mainnet.alchemyapi.io/v2/${API_KEY_ALCHEMY || ""
                  }`,
                blockNumber,
              },
            },
          ],
        });
      };

      let admin: Signer;
      let adminAdr: string;
      if (taskArgs.dryrun) {
        // await resetFork(taskArgs.blockheight);
        adminAdr = "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd";
        const impersonate = async (account: string): Promise<Signer> => {
          let provider = new ethers.providers.JsonRpcProvider(
            "http://localhost:8545"
          );
          await provider.send("hardhat_impersonateAccount", [account]);
          return provider.getSigner(account);
        };
        admin = await impersonate(adminAdr);
      } else {
        const accounts = await ethers.getSigners();
        adminAdr = await accounts[0].getAddress();
        [admin] = accounts;
      }

      const amount = ethers.utils.parseEther(taskArgs.amount);
      console.log(`---account addr:${adminAdr}  `);
      let curve3CrvToken = "";
      ({ curve3CrvToken } = await getNamedAccounts());
      if (net.name === "hardhat") {
        console.warn("You are running the task with Hardhat network");
      }
      console.log(`net chainId: ${net.chainId}  `);
      const manager = (await ethers.getContractAt(
        "UbiquityAlgorithmicDollarManager",
        "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98"
      )) as UbiquityAlgorithmicDollarManager;
      const uADAdr = await manager.dollarTokenAddress();
      const uAD = (await ethers.getContractAt(
        "UbiquityAlgorithmicDollar",
        uADAdr
      )) as UbiquityAlgorithmicDollar;
      const curveToken = (await ethers.getContractAt(
        "ERC20",
        curve3CrvToken
      )) as ERC20;
      const treasuryAddr = await manager.treasuryAddress();
      console.log(`---treasury Address:${treasuryAddr}  `);
      const bondingAddr = await manager.bondingContractAddress();
      console.log(`---bonding Contract Address:${bondingAddr}  `);
      const bonding = (await ethers.getContractAt(
        "BondingV2",
        bondingAddr
      )) as BondingV2;
      const metaPoolAddr = await manager.stableSwapMetaPoolAddress();
      console.log(`---metaPoolAddr:${metaPoolAddr}  `);
      const metaPool = (await ethers.getContractAt(
        "IMetaPool",
        metaPoolAddr
      )) as IMetaPool;
      let curveFactory = "";
      let DAI = "";
      let USDC = "";
      let USDT = "";

      ({ curveFactory, DAI, USDC, USDT } = await getNamedAccounts());
      const curvePoolFactory = (await ethers.getContractAt(
        "ICurveFactory",
        curveFactory
      )) as ICurveFactory;

      const uadTreasuryBalanceBefore = await uAD.balanceOf(treasuryAddr);
      const crvTreasuryBalanceBefore = await curveToken.balanceOf(treasuryAddr);
      const bondingMetapoolLPBalanceBefore = await metaPool.balanceOf(
        bondingAddr
      );
      const LPBal = ethers.utils.formatEther(bondingMetapoolLPBalanceBefore);
      const expectedUAD = await metaPool[
        "calc_withdraw_one_coin(uint256,int128)"
      ](amount, 0);

      const expectedUADStr = ethers.utils.formatEther(expectedUAD);
      const expectedCRV = await metaPool[
        "calc_withdraw_one_coin(uint256,int128)"
      ](amount, 1);

      const expectedCRVStr = ethers.utils.formatEther(expectedCRV);
      let coinIndex = 0;
      if (taskArgs.pushhigher) {
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
      const indices = await curvePoolFactory.get_coin_indices(
        metaPool.address,
        DAI,
        USDT
      );

      const indices2 = await curvePoolFactory.get_coin_indices(
        metaPool.address,
        uAD.address,
        USDC
      );
      let dyDAI2USDT = await metaPool[
        "get_dy_underlying(int128,int128,uint256)"
      ](indices[0], indices[1], ethers.utils.parseEther("1"));

      let dyuAD2USDC = await metaPool[
        "get_dy_underlying(int128,int128,uint256)"
      ](indices2[0], indices2[1], ethers.utils.parseEther("1"));

      let dyuAD2DAI = await metaPool[
        "get_dy_underlying(int128,int128,uint256)"
      ](indices2[0], indices[0], ethers.utils.parseEther("1"));

      let dyuAD2USDT = await metaPool[
        "get_dy_underlying(int128,int128,uint256)"
      ](indices2[0], indices[1], ethers.utils.parseEther("1"));

      const mgrtwapOracleAddress = await manager.twapOracleAddress();
      const twapOracle = (await ethers.getContractAt(
        "TWAPOracle",
        mgrtwapOracleAddress
      )) as TWAPOracle;
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
      await pressAnyKey(
        "Press any key if you are sure you want to continue ..."
      );

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
      const uadTreasuryBalanceAfter = await uAD.balanceOf(treasuryAddr);
      const crvTreasuryBalanceAfter = await curveToken.balanceOf(treasuryAddr);
      const metapoolLPBalanceAfter = await metaPool.balanceOf(bondingAddr);
      const LPBalAfter = ethers.utils.formatEther(metapoolLPBalanceAfter);
      console.log(`from ${LPBal} to ${LPBalAfter} uAD-3CRV LP token
      `);

      const crvTreasuryBalanceBeforeStr = ethers.utils.formatEther(
        crvTreasuryBalanceBefore
      );
      const crvTreasuryBalanceAfterStr = ethers.utils.formatEther(
        crvTreasuryBalanceAfter
      );
      console.log(`Treasury 3CRV balance from ${crvTreasuryBalanceBeforeStr} to ${crvTreasuryBalanceAfterStr}
        `);
      const balTreasuryUadBeforeStr = ethers.utils.formatEther(
        uadTreasuryBalanceBefore
      );
      const balTreasuryUadAfterStr = ethers.utils.formatEther(
        uadTreasuryBalanceAfter
      );
      console.log(`Treasury uAD balance from ${balTreasuryUadBeforeStr} to ${balTreasuryUadAfterStr}
        `);
      dyDAI2USDT = await metaPool["get_dy_underlying(int128,int128,uint256)"](
        indices[0],
        indices[1],
        ethers.utils.parseEther("1")
      );

      dyuAD2USDC = await metaPool["get_dy_underlying(int128,int128,uint256)"](
        indices2[0],
        indices2[1],
        ethers.utils.parseEther("1")
      );

      dyuAD2DAI = await metaPool["get_dy_underlying(int128,int128,uint256)"](
        indices2[0],
        indices[0],
        ethers.utils.parseEther("1")
      );

      dyuAD2USDT = await metaPool["get_dy_underlying(int128,int128,uint256)"](
        indices2[0],
        indices[1],
        ethers.utils.parseEther("1")
      );
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
      // for (let i = 0; i < 5; ++i) {
      tx = await metaPool
        .connect(admin)
      ["remove_liquidity_one_coin(uint256,int128,uint256)"](1, coinIndex, 0);
      // }
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
    }
  );
