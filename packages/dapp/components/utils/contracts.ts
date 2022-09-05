import { ethers } from "ethers";
import { simpleRpcProvider } from "utils/provider";
import erc20ABI from "config/abi/erc20.json";

const getContract = (
    chainId: number,
    abi: any,
    address: string,
    signer?: ethers.Signer | ethers.providers.Provider
) => {
    const signerOrProvider = signer ?? simpleRpcProvider(chainId);
    return new ethers.Contract(address, abi, signerOrProvider);
};

export const getERC20Contract = (
    chainId: number,
    address: string,
    signer?: ethers.Signer | ethers.providers.Provider
) => {
    return getContract(chainId, erc20ABI, address, signer);
};