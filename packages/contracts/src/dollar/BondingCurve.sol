// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./BancorFormula.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IERC20Ubiquity.sol";
// import "./interfaces/IERC1155Ubiquity.sol";
import "./core/UbiquityDollarManager.sol";
import "./core/UbiquityDollarToken.sol";
import "../ubiquistick/interfaces/IUbiquiStick.sol";

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
    address public tokenAddr;
    // IERC1155Ubiquity public token;
    IUbiquiStick immutable token;

    /// @dev Token used as collateral for minting the Token issued by the bonding curve
    // IERC20Ubiquity immutable collateral;
    address public collateral;

    /// @dev The ratio of how much collateral "backs" the total marketcap of the Token
    uint32 public connectorWeight;

    /// @dev The intersecting price to mint or burn a Token when supply == PRECISION
    uint256 public baseY;

    /**
     * @dev Available balance of reserve token in contract
     */
    uint256 public poolBalance = 0;

    /// @dev Current number of tokens minted
    uint256 public tokenIds = 0;

    UbiquityDollarManager public manager;

    event Deposit(address indexed user, uint256 amount);

    event Withdraw(address indexed recipient, uint256 amount);

    modifier onlyBondingMinter() {
        require(
            manager.hasRole(manager.BONDING_MINTER_ROLE(), msg.sender), "not minter"
        );
        _;
    }

    modifier onlyPauser() {
        require(
            manager.hasRole(manager.PAUSER_ROLE(), msg.sender), "not pauser"
        );
        _;
    }

    modifier onlyParamsSet() {
        require(
            connectorWeight != 0 && baseY != 0, "not initialised"
        );
        _;
    }

    constructor(
        address _manager,
        address _token
    ) {
        require(_token != address(0), "NFT address empty");
        tokenAddr = _token;
        token = IUbiquiStick(_token);

        manager = UbiquityDollarManager(_manager);
    }

    function setCollateralToken(address _collateral) external onlyBondingMinter {
        collateral = _collateral;
    }

    function setParams(
        uint32 _connectorWeight, 
        uint256 _baseY
    ) external onlyBondingMinter {
        require(_connectorWeight > 0 && _connectorWeight <= 1000000, "invalid values"); 
        require(_baseY > 0, "must valid baseY");

        connectorWeight = _connectorWeight;
        baseY = _baseY;
    }

    /// @notice 
    /// @dev 
    /// @param _collateralDeposited Amount of collateral
    /// @param _recipient An address to recieve the NFT
    /// @return Tokens minted
    function deposit(uint256 _collateralDeposited, address _recipient)
        external
        onlyParamsSet
        returns (uint256)
    {
        uint256 tokensReturned;

        if (tokenIds > 0) {
            tokensReturned = _purchaseTargetAmount(
                _collateralDeposited,
                connectorWeight,
                tokenIds,
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

        IERC20(manager.dollarTokenAddress()).transferFrom(
            msg.sender,
            address(this),
            _collateralDeposited
        );

        poolBalance += _collateralDeposited;
        tokenIds += 1;
        uint256 nftNum = 1;
        bytes memory tokReturned = toBytes(tokensReturned);

        token.mint(_recipient, tokenIds, nftNum, tokReturned);
        emit Deposit(_recipient, _collateralDeposited);

        return tokensReturned;
    }

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function pause() public virtual onlyPauser {
        _pause();
    }

    function unpause() public virtual onlyPauser {
        _unpause();
    }

    function withdraw(address _to, uint256 _amount) external onlyBondingMinter {
        require(_amount <= poolBalance, "invalid amount");

        IERC20Ubiquity(collateral).transferFrom(address(this), _to, _amount);
        poolBalance -= _amount;

        emit Withdraw(_to, _amount);
    }
}
