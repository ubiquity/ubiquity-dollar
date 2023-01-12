// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./01_UbiquityDollarManager.s.sol";

contract DollarScript is ManagerScript{
    UbiquityDollarToken dollar;
    address metapool;

    function run() public virtual override {
        super.run();
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        
        dollar = new UbiquityDollarToken(address(manager));
        manager.setDollarTokenAddress(address(dollar));
        
        dollar.mint(address(manager), 10000e18);

        manager.deployStableSwapPool(
            curveFactory,
            basepool,
            USDCrvToken,
            10,
            5000000
        );
        
        metapool = manager.stableSwapMetaPoolAddress();
        
        vm.stopBroadcast();
    }
}