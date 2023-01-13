// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./BancorFormula.sol";
import "./interfaces/IERC20Ubiquity.sol";
import "./interfaces/IERC1155Ubiquity.sol";
import "./core/UbiquityDollarManager.sol";

/**
 * @title Bonding Curve
 * @dev Bonding curve contract based on Bacor formula
 * Inspired from Bancor protocol and simondlr
 * https://github.com/bancorprotocol/contracts
 */
contract BondingCurve is BancorFormula {
    uint256 constant ACCURACY = 10 ** 18;

    /// @dev Token issued by the bonding curve
    IERC1155Ubiquity immutable token;

    /// @dev Token used as collateral for minting the Token issued by the bonding curve
    IERC20Ubiquity immutable collateral;

    /// @dev The ratio of how much collateral "backs" the total marketcap of the Token
    uint32 immutable weight;

    /// @dev The intersecting price to mint or burn a Token when supply == PRECISION
    uint256 immutable intersect;

    /**
     * @dev Available balance of reserve token in contract
     */
    uint256 public poolBalance = 0;

    /// @dev Current number of tokens minted
    uint256 public tokenIds = 0;

    UbiquityDollarManager public manager;

    event Deposit(address indexed user, uint256 amount);

    event Withdraw(address indexed recipient, uint256 amount);

    modifier onlyUBQMinter() {
        require(
            manager.hasRole(manager.UBQ_MINTER_ROLE(), msg.sender), "not admin"
        );
        _;
    }

    constructor(
        address _manager,
        IERC1155Ubiquity _token,
        IERC20Ubiquity _collateral,
        uint32 _weight,
        uint256 _intersect
    ) {
        require(_weight <= 1000000 && _weight > 0);
        token = _token;
        collateral = _collateral;
        weight = _weight;
        intersect = _intersect;

        manager = UbiquityDollarManager(_manager);
    }

    function deposit(uint256 _collateralDeposited, address _recipient)
        external
        returns (uint256 _price)
    {
        _price = _calculatePurchasePrice(tokenIds);

        require(_collateralDeposited >= _price, "Not enough collateral");

        bytes memory tokenValue = _toBytes(_price);

        poolBalance += _collateralDeposited;
        collateral.transferFrom(msg.sender, address(this), _collateralDeposited);

        tokenIds += 1;
        token.mint(_recipient, tokenIds, 1, tokenValue);

        emit Deposit(_recipient, _collateralDeposited);
    }

    function _toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function withdraw(uint256 _amount) external onlyUBQMinter {
        require(_amount > 0, "Amount must be greater than zero");
        require(_amount < poolBalance, "Insufficient funds");

        poolBalance -= _amount;

        collateral.transfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }
}
