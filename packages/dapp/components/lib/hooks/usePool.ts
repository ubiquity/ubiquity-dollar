import { useEffect, useState } from "react";
import useWeb3 from "@/components/lib/hooks/useWeb3";
import { getUniswapV3PoolContract } from "@/components/utils/contracts";
import { uCR_uAD_ADDRESS, uCR_USDC_ADDRESS, uCR_DAI_ADDRESS, uCR_USDT_ADDRESS } from "../utils"
import { PoolImmutables, PoolState } from "../types"

const usePool = (selectedToken: string): [PoolImmutables | undefined, PoolState | undefined] => {

    const [{ provider }] = useWeb3();
    const [immutables, setImmutables] = useState<PoolImmutables>();
    const [poolState, setPoolState] = useState<PoolState>();

    async function getPoolData() {
        let poolAddress;

        if (selectedToken === "USDC") {
            poolAddress = uCR_USDC_ADDRESS;
        } else if (selectedToken === "DAI") {
            poolAddress = uCR_DAI_ADDRESS;
        } else if (selectedToken === "USDT") {
            poolAddress = uCR_USDT_ADDRESS;
        } else {
            poolAddress = uCR_uAD_ADDRESS;
        }

        if (provider) {
            const poolContract = getUniswapV3PoolContract(poolAddress, provider);

            const [factory, token0, token1, fee, tickSpacing, maxLiquidityPerTick] = await Promise.all([
                poolContract.factory(),
                poolContract.token0(),
                poolContract.token1(),
                poolContract.fee(),
                poolContract.tickSpacing(),
                poolContract.maxLiquidityPerTick(),
            ])

            const [liquidity, slot] = await Promise.all([poolContract.liquidity(), poolContract.slot0()])

            const immutables: PoolImmutables = {
                factory,
                token0,
                token1,
                fee,
                tickSpacing,
                maxLiquidityPerTick,
            }

            const poolState: PoolState = {
                liquidity,
                sqrtPriceX96: slot[0],
                tick: slot[1],
                observationIndex: slot[2],
                observationCardinality: slot[3],
                observationCardinalityNext: slot[4],
                feeProtocol: slot[5],
                unlocked: slot[6],
            }

            setImmutables(immutables);
            setPoolState(poolState);
        }
    }

    useEffect(() => {
        getPoolData();
    }, [selectedToken]);

    return [immutables, poolState];
};

export default usePool;