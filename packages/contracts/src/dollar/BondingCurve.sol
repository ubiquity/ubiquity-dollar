// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./BancorFormula.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IERC20Ubiquity.sol";
import "./interfaces/IERC1155Ubiquity.sol";
import "./core/UbiquityDollarManager.sol";

/**
 * @title Bonding Curve
 * @dev Bonding curve contract based on Bacor formula
 * Inspired from Bancor protocol and simondlr
 * https://github.com/bancorprotocol/contracts
 */
contract BondingCurve is BancorFormula, Pausable {
    uint256 constant ACCURACY = 10e18;

    /// @dev Token issued by the bonding curve
    IERC1155Ubiquity immutable token;

    /// @dev Token used as collateral for minting the Token issued by the bonding curve
    IERC20Ubiquity immutable collateral;

    /// @dev The ratio of how much collateral "backs" the total marketcap of the Token
    uint32 immutable connectorWeight;

    /// @dev The intersecting price to mint or burn a Token when supply == PRECISION
    uint256 immutable baseY;

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

    modifier onlyPauser() {
        require(
            manager.hasRole(manager.PAUSER_ROLE(), msg.sender), "not pauser"
        );
        _;
    }

    constructor(
        address _manager,
        IERC1155Ubiquity _token,
        IERC20Ubiquity _collateral,
        uint32 _connectorWeight,
        uint256 _baseY
    ) {
        require(_connectorWeight > 0 && _connectorWeight <= 1000000);
        token = _token;
        collateral = _collateral;
        connectorWeight = _connectorWeight;
        baseY = _baseY;

        manager = UbiquityDollarManager(_manager);
    }

    function deposit(uint256 _collateralDeposited, address _recipient)
        external
        returns (uint256 tokensReturned)
    {
        uint256 supply = token.totalSupply();
        if (supply > 0) {
            tokensReturned = _purchaseTargetAmount(
                _collateralDeposited,
                connectorWeight,
                supply,
                poolBalance
            );
        } else {
            tokensReturned = _purchaseTargetAmountFromZero(
                _collateralDeposited,
                connectorWeight,
                ACCURACY,
                baseY
            );
        }

        poolBalance += _collateralDeposited;
        collateral.transferFrom(msg.sender, address(this), _collateralDeposited);

        token.mint(_recipient, tokenIds, 1, "Ubiquistick");

        emit Deposit(_recipient, _collateralDeposited);
    }

    function pause() public virtual onlyPauser {
        _pause();
    }

    function unpause() public virtual onlyPauser {
        _unpause();
    }
}
