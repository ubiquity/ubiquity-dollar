// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./01_Diamond.s.sol";

contract DollarScript is DiamondScript {
    address metapool;

    UbiquityDollarToken public dollarToken;
    ERC1967Proxy public proxyDollarToken;

    function run() public virtual override {
        super.run();
        vm.startBroadcast(deployerPrivateKey);
        bytes memory managerPayload = abi.encodeWithSignature(
            "initialize(address)",
            address(diamond)
        );

        proxyDollarToken = new ERC1967Proxy(
            address(new UbiquityDollarToken()),
            managerPayload
        );
        dollarToken = UbiquityDollarToken(address(proxyDollarToken));

        IManager.setDollarTokenAddress(address(dollarToken));
        IAccessControl.grantRole(DOLLAR_TOKEN_MINTER_ROLE, address(diamond));
        IAccessControl.grantRole(DOLLAR_TOKEN_BURNER_ROLE, address(diamond));

        dollarToken.mint(address(diamond), 10000e18);
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
