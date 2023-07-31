// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Minter, MintAccount} from "../../src/dollar/cow-minter/Minter.sol";
import {UbiquityPoolFacetTest} from "../diamond/facets/UbiquityPoolFacet.t.sol";
import {MockERC20} from "../../src/dollar/mocks/MockERC20.sol";

contract MinterTest is UbiquityPoolFacetTest {
    Minter public minter;
    MintAccount public mintAccount;
    MockERC20 public collateral;

    function setUp() public override {
        super.setUp();
        minter = new Minter(address(diamond));

        collateral = new MockERC20("collateral", "collateral", 18);
        collateral.mint(secondAccount, 10 ether);
        vm.prank(admin);
        IUbiquityPoolFacet.addToken(address(collateral), (metapool));
        vm.prank(admin);
        IUbiquityPoolFacet.setMintActive(address(collateral), true);
    }

    function test_createAccountIfNoneExists() public {
        address accountAddress = minter.getAccountAddress(secondAccount);
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(accountAddress)
        }
        assertEq(codeSize, 0);

        MintAccount mintAccount_ = minter.ensureAccount(secondAccount);
        uint256 codeSize_;
        assembly {
            codeSize_ := extcodesize(mintAccount_)
        }
        assertGt(codeSize, 0);
    }

    function test_MintFunction() public {
        uint256 preBal = IDollar.balanceOf(secondAccount);
        vm.startPrank(secondAccount);
        mintAccount = minter.ensureAccount(secondAccount);
        collateral.transfer(address(mintAccount), 5 ether);
        minter.mintAll(secondAccount, address(collateral), 0);
        minter.withdrawAll(secondAccount, address(IDollar));
        assertGt(IDollar.balanceOf(secondAccount), preBal);
    }
}
