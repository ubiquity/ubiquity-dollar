// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./BancorFormula.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IERC20Ubiquity.sol";
import "./core/UbiquityDollarManager.sol";
import "../ubiquistick/interfaces/IUbiquistick.sol";

/**
 * @title Bonding Curve
 * @dev Bonding curve contract based on Bacor formula
 * Inspired from Bancor protocol and simondlr
 * https://github.com/bancorprotocol/contracts
 */
contract BondingCurve is BancorFormula, Pausable {
    uint256 constant ACCURACY = 10e18;

    /// @dev Token issued by the bonding curve
    // IUbiquiStick immutable token;
    address public token;

    /// @dev Token used as collateral for minting the Token issued by the bonding curve
    // IERC20Ubiquity immutable collateral;
    address public collateral;

    /// @dev The ratio of how much collateral "backs" the total marketcap of the Token
    uint32 immutable connectorWeight;

    /// @dev The intersecting price to mint or burn a Token when supply == PRECISION
    uint256 immutable baseY;

    /**
     * @dev Available balance of reserve token in contract
     */
    uint256 public poolBalance;

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
        address _token,
        address _collateral,
        uint32 _connectorWeight,
        uint256 _baseY
    ) {
        require(_connectorWeight > 0 && _connectorWeight <= 1000000);
        require(_token != address(0), "NFT address empty");
        require(_baseY > 0, "must valid baseY");
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
        uint256 supply = IUbiquiStick(token).totalSupply();
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

        IERC20Ubiquity(collateral).transferFrom(msg.sender, address(this), _collateralDeposited);
        // collateral.transferFrom(msg.sender, address(this), _collateralDeposited);

        IUbiquiStick(token).batchSafeMint(_recipient, 1);

        emit Deposit(_recipient, _collateralDeposited);
    }

    // function _totalSupply() internal override {
    //     super.totalSupply();
    // }

    function pause() public virtual onlyPauser {
        _pause();
    }

    function unpause() public virtual onlyPauser {
        _unpause();
    }
}
