// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "forge-std/Script.sol";

import "src/dollar/interfaces/IMetaPool.sol";
import "src/dollar/Staking.sol";
import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "src/dollar/core/TWAPOracleDollar3pool.sol";
import "src/dollar/core/UbiquityDollarManager.sol";

contract migrateFunds is Script {
	function run() public virtual {

		
		IMetaPool v2Metapool = IMetaPool(0x20955CB69Ae1515962177D164dfC9522feef567E);
		IMetaPool v3Metapool = IMetaPool(0x9558b18f021FC3cBa1c9B777603829A42244818b);
		IERC20 USD3CRVToken = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
		IERC20 uAD = IERC20(0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6);
		Staking staking = Staking(payable(0xC251eCD9f1bD5230823F9A0F99a44A87Ddd4CA38));
		UbiquityDollarManager manager = UbiquityDollarManager(0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98);

		TWAPOracleDollar3pool twapOracle;

		uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
		address admin = vm.envAddress("PUBLIC_KEY");
        	vm.startBroadcast(deployerPrivateKey);

			uint256 metaBalance = v2Metapool.balanceOf(address(staking));
			staking.sendDust(admin, address(v2Metapool), metaBalance);

			v2Metapool.remove_liquidity(metaBalance,[uint256(0), uint256(0)]);

			uint256 usd3Bal = USD3CRVToken.balanceOf(admin);
			uint256 uADBal = uAD.balanceOf(admin);

			uint256 deposit;

			if(usd3Bal <= uADBal){
				deposit = usd3Bal;
			} else {
				deposit = uADBal;
			}

			USD3CRVToken.approve(address(v3Metapool), 0);
			USD3CRVToken.approve(address(v3Metapool), deposit);

			uAD.approve(address(v3Metapool), 0);
			uAD.approve(address(v3Metapool), deposit);

			v3Metapool.add_liquidity([deposit, deposit], 0, address(staking));

			require(v3Metapool.balanceOf(address(staking)) > 0);

			twapOracle = new TWAPOracleDollar3pool(address(v3Metapool), address(uAD), address(USD3CRVToken));
			manager.setTwapOracleAddress(address(twapOracle));
        	
        	vm.stopBroadcast();
	}


}
