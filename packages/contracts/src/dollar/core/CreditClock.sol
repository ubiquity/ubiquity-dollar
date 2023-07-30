// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "abdk/ABDKMathQuad.sol";
import {IAccessControl} from "../interfaces/IAccessControl.sol";
import "../libraries/Constants.sol";

/**
 * @notice CreditClock contract
 */
contract CreditClock {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    /// @notice Access control contract
    IAccessControl public accessControl;

    /// @notice ABDKMathQuad with value of 1.
    bytes16 private immutable one = uint256(1).fromUInt();

    /// @notice The block height from where we start applying the rate.
    uint256 public rateStartBlock;

    /// @notice This is the exchange rate of Credits for the start block.
    bytes16 public rateStartValue;

    /// @notice Deprecation rate. How many Dollars are deprecated on each block.
    bytes16 public ratePerBlock;

    /// @notice Emitted when depreciation rate per block is updated
    event SetRatePerBlock(
        uint256 rateStartBlock,
        bytes16 rateStartValue,
        bytes16 ratePerBlock
    );

    /// @notice Modifier checks that the method is called by a user with the "Incentive manager" role
    modifier onlyAdmin() {
        require(
            accessControl.hasRole(INCENTIVE_MANAGER_ROLE, msg.sender),
            "CreditClock: not admin"
        );
        _;
    }

    /**
     * @notice Contract constructor
     * @param _manager The address of the `_manager` contract for access control
     * @param _rateStartValue ABDKMathQuad Initial rate
     * @param _ratePerBlock ABDKMathQuad Initial rate change per block
     */
    constructor(
        address _manager,
        bytes16 _rateStartValue,
        bytes16 _ratePerBlock
    ) {
        accessControl = IAccessControl(_manager);
        rateStartBlock = block.number;
        rateStartValue = _rateStartValue;
        ratePerBlock = _ratePerBlock;

        emit SetRatePerBlock(rateStartBlock, rateStartValue, ratePerBlock);
    }

    /**
     * @notice Updates the manager address
     * @param _manager New manager address
     */
    function setManager(address _manager) external onlyAdmin {
        accessControl = IAccessControl(_manager);
    }

    /**
     * @notice Returns the manager address
     * @return Manager address
     */
    function getManager() external view returns (address) {
        return address(accessControl);
    }

    /**
     * @notice Sets rate to apply from this block onward
     * @param _ratePerBlock ABDKMathQuad new rate per block to apply from this block onward
     */
    function setRatePerBlock(bytes16 _ratePerBlock) external onlyAdmin {
        rateStartValue = getRate(block.number);
        rateStartBlock = block.number;
        ratePerBlock = _ratePerBlock;

        emit SetRatePerBlock(rateStartBlock, rateStartValue, ratePerBlock);
    }

    /**
     * @notice Calculates `rateStartValue * (1 / ((1 + ratePerBlock)^blockNumber - rateStartBlock)))`
     * @param blockNumber Block number to get the rate for. 0 for current block.
     * @return rate ABDKMathQuad rate calculated for the block number
     */
    function getRate(uint256 blockNumber) public view returns (bytes16 rate) {
        if (blockNumber == 0) {
            blockNumber = block.number;
        } else {
            if (blockNumber < block.number) {
                revert("CreditClock: block number must not be in the past.");
            }
        }
        // slither-disable-next-line divide-before-multiply
        rate = rateStartValue.mul(
            one.div(
                // b ^ n == 2^(n*log²(b))
                (blockNumber - rateStartBlock)
                    .fromUInt()
                    .mul(one.add(ratePerBlock).log_2())
                    .pow_2()
            )
        );
    }
}
