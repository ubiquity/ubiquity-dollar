// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IUbiquityPool} from "../interfaces/IUbiquityPool.sol";

contract Minter {
    address public immutable ubiquityPool;

    constructor(address ubiquityPool_) {
        ubiquityPool = ubiquityPool_;
    }

    function getAccountAddress(address user) external view returns (address) {
        return _getAccountAddress(user);
    }

    function getAccountBalance(
        address user,
        IERC20 token
    ) public view returns (uint256) {
        return token.balanceOf(_getAccountAddress(user));
    }

    function ensureAccount(address user) public returns (MintAccount) {
        address accountAddress = _getAccountAddress(user);
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(accountAddress)
        }

        if (codeSize > 0) {
            return MintAccount(accountAddress);
        } else {
            MintAccount newAccount = new MintAccount{salt: bytes32(0)}(
                user,
                ubiquityPool
            );
            require(
                accountAddress == address(newAccount),
                "account does not expected deployment address"
            );

            return newAccount;
        }
    }

    function mint(
        address user,
        address token,
        uint256 amountIn,
        uint256 dollarMin
    ) public {
        ensureAccount(user).mintDollar(token, amountIn, dollarMin);
    }

    function mintAll(address user, address token, uint256 dollarMin) external {
        mint(user, token, getAccountBalance(user, IERC20(token)), dollarMin);
    }

    function withdraw(address user, address token, uint256 amount) public {
        ensureAccount(user).withdraw(token, amount);
    }

    function withdrawAll(address user, address token) external {
        withdraw(user, token, getAccountBalance(user, IERC20(token)));
    }

    function _getAccountAddress(address user) internal view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                bytes32(0),
                                keccak256(
                                    abi.encodePacked(
                                        type(MintAccount).creationCode,
                                        abi.encode(user, ubiquityPool)
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }
}

contract MintAccount {
    address public immutable user;
    address public immutable ubiquityPool;

    constructor(address user_, address ubiquityPool_) {
        user = user_;
        ubiquityPool = ubiquityPool_;
    }

    function mintDollar(
        address token,
        uint256 amountIn,
        uint256 amountOutMin
    ) external {
        IERC20(token).approve(ubiquityPool, amountIn);
        IUbiquityPool(ubiquityPool).mintDollar(
            user,
            token,
            amountIn,
            amountOutMin
        );
    }

    function withdraw(address token, uint256 amount) external returns (bool) {
        return IERC20(token).transfer(user, amount);
    }
}
