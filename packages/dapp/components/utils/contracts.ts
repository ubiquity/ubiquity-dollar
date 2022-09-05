import { ethers } from "ethers";
import UniswapV2PairABI from "../config/abis/UniswapV2Pair.json"
import UniswapV3PoolABI from "../config/abis/UniswapV3Pool.json"
import ChainlinkPriceFeedABI from "../config/abis/ChainlinkPriceFeed.json"
import ERC20ABI from "../config/abis/ERC20.json"

const getContract = (
    abi: any,
    address: string,
    provider: ethers.providers.Provider
) => {
    return new ethers.Contract(address, abi, provider);
};

export const getUniswapV2FactoryContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(UniswapV2PairABI, address, provider);
}

export const getUniswapV3PoolContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(UniswapV3PoolABI, address, provider);
}

export const getChainlinkPriceFeedContract = (address: string, provider: ethers.providers.Provider): ethers.Contract => {
    return getContract(ChainlinkPriceFeedABI, address, provider);
}

export const getERC20Contract = (
    address: string,
    provider: ethers.providers.Provider
) => {
    return getContract(ERC20ABI, address, provider);
};