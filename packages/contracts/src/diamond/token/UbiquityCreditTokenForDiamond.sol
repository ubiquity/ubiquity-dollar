// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.16;
import {ManagerFacet} from "../facets/ManagerFacet.sol";
import {ERC20UbiquityForDiamond} from "./ERC20UbiquityForDiamond.sol";

contract UbiquityCreditTokenForDiamond is ERC20UbiquityForDiamond {
    constructor(
        address _diamond
    )
        // cspell: disable-next-line
        ERC20UbiquityForDiamond(_diamond, "Ubiquity Auto Redeem", "uAR")
    {} // solhint-disable-line no-empty-blocks

    /// @notice raise capital in form of Ubiquity Credit Token (only redeemable when Ubiquity Dollar > 1$)
    /// @param amount the amount to be minted
    /// @dev you should be minter to call that function
    function raiseCapital(uint256 amount) external {
        address treasuryAddress = ManagerFacet(address(accessCtrl))
            .treasuryAddress();
        mint(treasuryAddress, amount);
    }
}
