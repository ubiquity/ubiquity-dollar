import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import { BigNumber } from "ethers";
import {
  ChainId,
  Route,
  Pair,
  Trade,
  Token,
  TokenAmount,
  TradeType,
} from "@uniswap/sdk";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { UbiquityAutoRedeem } from "../artifacts/types/UbiquityAutoRedeem";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { DollarMintingCalculator } from "../artifacts/types/DollarMintingCalculator";
import { DebtCoupon } from "../artifacts/types/DebtCoupon";
import { BondingShare } from "../artifacts/types/BondingShare";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { SushiSwapPool } from "../artifacts/types/SushiSwapPool";
import { IUniswapV2Pair } from "../artifacts/types/IUniswapV2Pair";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
// This file is only here to make interacting with the Dapp easier,
// feel free to ignore it if you don't need it.

task("token", "Get info about tokens").setAction(
  async (taskArgs: { receiver: string; manager: string }, { ethers }) => {
    const net = await ethers.provider.getNetwork();

    if (net.name === "hardhat") {
      console.warn("You are running the   task with Hardhat network");
    }
    console.log(`net chainId: ${net.chainId}  `);
    const manager = (await ethers.getContractAt(
      "UbiquityAlgorithmicDollarManager",
      "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98"
    )) as UbiquityAlgorithmicDollarManager;

    const treasury = await manager.treasuryAddress();
    const uADAdr = await manager.dollarTokenAddress();

    const uAD = (await ethers.getContractAt(
      "UbiquityAlgorithmicDollar",
      uADAdr
    )) as UbiquityAlgorithmicDollar;

    console.log(`
uAD
treasury balance:${ethers.utils.formatEther(await uAD.balanceOf(treasury))}
address:${uADAdr}
name:${await uAD.name()}
symbol:${await uAD.symbol()}
total supply:${ethers.utils.formatEther(await uAD.totalSupply())} uAD
      `);

    const dollarMintingCalculatorAddress =
      await manager.dollarMintingCalculatorAddress();
    const dollarMintingCalculator = (await ethers.getContractAt(
      "DollarMintingCalculator",
      dollarMintingCalculatorAddress
    )) as DollarMintingCalculator;
    const mgrtwapOracleAddress = await manager.twapOracleAddress();
    const twapOracle = (await ethers.getContractAt(
      "TWAPOracle",
      mgrtwapOracleAddress
    )) as TWAPOracle;
    const oraclePriceuAD = await twapOracle.consult(uAD.address);
    if (oraclePriceuAD.gt(ethers.utils.parseEther("1"))) {
      const dollarsToMint = await dollarMintingCalculator.getDollarsToMint();

      console.log(`
      Dollar to be minted
      ${ethers.utils.formatEther(dollarsToMint)} uAD
        `);
    } else {
      console.log(`twapPrice :${ethers.utils.formatEther(
        oraclePriceuAD
      )} can't calculate dollars to mint
        `);
    }

    const uGOVAdr = await manager.governanceTokenAddress();

    const uGOV = (await ethers.getContractAt(
      "UbiquityGovernance",
      uGOVAdr
    )) as UbiquityGovernance;

    console.log(`
Governance
treasury balance:${ethers.utils.formatEther(await uGOV.balanceOf(treasury))}
address:${uGOVAdr}
name:${await uGOV.name()}
symbol:${await uGOV.symbol()}
total supply:${ethers.utils.formatEther(await uGOV.totalSupply())} UBQ
          `);

    const uARAdr = await manager.autoRedeemTokenAddress();

    const uAR = (await ethers.getContractAt(
      "UbiquityAutoRedeem",
      uARAdr
    )) as UbiquityAutoRedeem;

    console.log(`
uAR
treasury balance:${ethers.utils.formatEther(await uAR.balanceOf(treasury))}
address:${uARAdr}
name:${await uAR.name()}
symbol:${await uAR.symbol()}
total supply:${ethers.utils.formatEther(await uAR.totalSupply())} uAR
                            `);

    const bondingShareAdr = await manager.bondingShareAddress();
    const bondingShare = (await ethers.getContractAt(
      "BondingShare",
      bondingShareAdr
    )) as BondingShare;

    const treasuryIds = await bondingShare.holderTokens(treasury);

    const balanceOfs = treasuryIds.map((id) => {
      return bondingShare.balanceOf(treasury, id);
    });
    const balances = await Promise.all(balanceOfs);
    let fullBalance = BigNumber.from(0);
    if (balances.length > 0) {
      fullBalance = balances.reduce((prev, cur) => {
        return prev.add(cur);
      });
    }
    const bondingSharesInEth = ethers.utils.formatEther(
      await bondingShare.totalSupply()
    );
    console.log(`
bondingShare
treasury balance:${ethers.utils.formatEther(fullBalance)}
address:${bondingShareAdr}
total supply:${bondingSharesInEth} bondingShares
                                                                `);

    const debtCouponAdr = await manager.debtCouponAddress();
    const debtCoupon = (await ethers.getContractAt(
      "DebtCoupon",
      debtCouponAdr
    )) as DebtCoupon;
    const totOutstandingDebtInEth = ethers.utils.formatEther(
      await debtCoupon.getTotalOutstandingDebt()
    );
    console.log(`
debtCoupon
address:${debtCouponAdr}
Total OutstandingDebt: ${totOutstandingDebtInEth} debtCoupon
                                        `);
    console.log(`---LP Tokens`);
    const metaPoolAddr = await manager.stableSwapMetaPoolAddress();
    const metaPool = (await ethers.getContractAt(
      "IMetaPool",
      metaPoolAddr
    )) as IMetaPool;
    const metaPoolInEth = ethers.utils.formatEther(
      await metaPool.totalSupply()
    );
    console.log(`
uAD-3CRV Curve LP
address:${metaPoolAddr}
treasury balance:${ethers.utils.formatEther(await metaPool.balanceOf(treasury))}
name:${await metaPool.name()}
symbol:${await metaPool.symbol()}
total supply:${metaPoolInEth} ${await metaPool.symbol()}`);

    const sushiSwapAddr = await manager.sushiSwapPoolAddress();
    const sushiSwap = (await ethers.getContractAt(
      "SushiSwapPool",
      sushiSwapAddr
    )) as SushiSwapPool;

    const pairAdr = await sushiSwap.pair();
    const ugovUadPair = (await ethers.getContractAt(
      "IUniswapV2Pair",
      pairAdr
    )) as IUniswapV2Pair;
    const reserves = await ugovUadPair.getReserves();
    const treasuryLPInEth = ethers.utils.formatEther(
      await ugovUadPair.balanceOf(treasury)
    );

    const sushiLPInEth = ethers.utils.formatEther(
      await ugovUadPair.totalSupply()
    );
    const price0CumulativeLast = ethers.utils.formatEther(
      await ugovUadPair.price0CumulativeLast()
    );
    const price1CumulativeLast = ethers.utils.formatEther(
      await ugovUadPair.price1CumulativeLast()
    );

    console.log(`
uAD-uGOV Sushi LP
SushiSwap pool pair:${pairAdr}
sushiSwap address:${sushiSwapAddr}
treasury balance:${treasuryLPInEth}
name:${await ugovUadPair.name()}
symbol:${await ugovUadPair.symbol()}
total supply:${sushiLPInEth} ${await ugovUadPair.symbol()}
reserves [0]:${ethers.utils.formatEther(reserves[0])}
reserves [1]:${ethers.utils.formatEther(reserves[1])}
price0CumulativeLast:${price0CumulativeLast}
price1CumulativeLast:${price1CumulativeLast}
token [0]:${await ugovUadPair.token0()}
token [1]:${await ugovUadPair.token1()}
`);

    const uniUBQ = new Token(ChainId.MAINNET, uGOV.address, 18);
    const uniUAD = new Token(ChainId.MAINNET, uAD.address, 18);
    const uniPair = new Pair(
      new TokenAmount(uniUBQ, reserves[1].toString()),
      new TokenAmount(uniUAD, reserves[0].toString())
    );
    const UAD_TO_UBQ = new Route([uniPair], uniUAD);

    const trade = new Trade(
      UAD_TO_UBQ,
      new TokenAmount(uniUAD, ethers.utils.parseEther("1").toString()),
      TradeType.EXACT_INPUT
    );

    console.log("Mid Price UAD --> UBQ:", UAD_TO_UBQ.midPrice.toSignificant(6));
    console.log(
      "Mid Price UBQ --> UAD:",
      UAD_TO_UBQ.midPrice.invert().toSignificant(6)
    );
    console.log("-".repeat(45));
    console.log(
      "Execution Price UAD --> UBQ:",
      trade.executionPrice.toSignificant(6)
    );
    console.log(
      "Mid Price after trade UAD --> UBQ:",
      trade.nextMidPrice.toSignificant(6)
    );
  }
);
