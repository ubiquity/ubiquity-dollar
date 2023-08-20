import { ImpersonateAccountParameters, IncreaseTimeParameters, MineParameters, SetBalanceParameters, SetStorageAtParameters, StopImpersonatingAccountParameters, createTestClient, http } from 'viem'
import { foundry } from 'viem/chains'
import { BytesLike } from "ethers";

const testClient = createTestClient({
  chain: foundry,
  mode: 'anvil',
  transport: http(), 
})

export const prank = async (address: ImpersonateAccountParameters) => {
      await testClient.impersonateAccount(address)
    }
  
export const stopPrank = async (address: StopImpersonatingAccountParameters) => {
      await testClient.stopImpersonatingAccount(address)
    }
  
export const deal = async ({address, value}: SetBalanceParameters) => {
      await testClient.setBalance(address, value)
    }
  
export const setStorageAt = async ({address, index, value}: SetStorageAtParameters) => {
      await testClient.setStorageAt({
        address: address,
        index: index,
        value: value
      })
    }
  
export const warpTime = async (seconds: IncreaseTimeParameters) => {
      await testClient.increaseTime(seconds)
    }

export const rollBlocks = async (height: MineParameters) => {
    await testClient.mine(height)
}

export const dumpState = async () => {
      const tx = await testClient.request({
        method: 'anvil_dumpState',
        params: []
      })
      // needs written to file
      console.log(tx) 
    }

export const loadState = async (state: string) => {
    await testClient.request({
        method: 'anvil_loadState',
        params: [state]
    })
}

export const AllMethods = [
        {
            name: 'prank',
            method: prank,
            params: ['address']
        },
        {
            name: 'stopPrank',
            method: stopPrank,
            params: ['address']
        },
        {
            name: 'deal',
            method: deal,
            params: ['address', 'amt']
        },
        {
            name: 'setStorageAt',
            method: setStorageAt,
            params: ['address', 'index', 'value']
        },
        {
            name: 'warpTime',
            method: warpTime,
            params: ['sec']
        },
        {
            name: 'rollBlocks',
            method: rollBlocks,
            params: ['height']
        },
        {
            name: 'loadState',
            method: loadState,
            params: ['state']
        },
        {
            name: 'dumpState',
            method: dumpState,
            params: []
        }
    ]