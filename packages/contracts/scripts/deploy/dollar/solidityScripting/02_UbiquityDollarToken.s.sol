// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./01_Diamond.s.sol";

contract DollarScript is DiamondScript {
    UbiquityDollarToken dollar;
    address metapool;

    function run() public virtual override {
        super.run();
        vm.startBroadcast(deployerPrivateKey);

        dollar = new UbiquityDollarToken(address(diamond));
        IManager.setDollarTokenAddress(address(dollar));
        IAccessControl.grantRole(DOLLAR_TOKEN_MINTER_ROLE, address(diamond));
        IAccessControl.grantRole(DOLLAR_TOKEN_BURNER_ROLE, address(diamond));

        dollar.mint(address(diamond), 10000e18);
        uint256 adminBal = IERC20(curve3PoolToken).balanceOf(admin);
        console.log("----ADMIN 3CRV bal:", adminBal);
        // deployer needs 10000  3CRV to deploy the pool
        require(
            IERC20(curve3PoolToken).transfer(address(diamond), 10000e18),
            "Transfer failed"
        );
        uint256 diamondBal = IERC20(curve3PoolToken).balanceOf(
            address(diamond)
        );
        console.log("----DIAMOND 3CRV bal:", diamondBal);
        //  deal(curve3PoolToken, address(diamond), 10000e18);
        IManager.deployStableSwapPool(
            curveFactory,
            basePool,
            curve3PoolToken,
            10,
            5e6
        );

        metapool = IManager.stableSwapMetaPoolAddress();

        vm.stopBroadcast();
    }
}
