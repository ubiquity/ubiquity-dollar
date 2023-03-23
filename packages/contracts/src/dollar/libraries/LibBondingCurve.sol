// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IERC20Ubiquity.sol";
// import "./interfaces/IERC1155Ubiquity.sol";
import "./core/UbiquityDollarManager.sol";
import "./core/UbiquityDollarToken.sol";
import "../ubiquistick/interfaces/IUbiquiStick.sol";
import {BancorFormula} from "../core/BancorFormula.sol";


library BondingCurve {
    uint256 constant ACCURACY = 10e18;

    /// @dev Token issued by the bonding curve
    // IUbiquiStick immutable token;
    address public tokenAddr;
    // IERC1155Ubiquity public token;
    IUbiquiStick immutable token;

    /// @dev Token used as collateral for minting the Token issued by the bonding curve
    // IERC20Ubiquity immutable collateral;
    address public collateral;

    /// @dev Treasury address
    address public treasuryAddress;

    /// @dev The ratio of how much collateral "backs" the total Token
    uint32 public connectorWeight;

    /// @dev The intersecting price to mint or burn a Token when supply == PRECISION
    uint256 public baseY;

    /// @dev token id
    uint256 public constant BONDING_TOKEN_ID = 1;

    /**
     * @dev Available balance of reserve token in contract
     */
    uint256 public poolBalance = 0;

    /// @dev Current number of tokens minted
    uint256 public tokenIds = 0;

    /// @dev Mapping of tokens minted to address
    mapping (address => uint256) public share;

    UbiquityDollarManager public manager;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(uint256 amount);

    struct BondingCurveData {
        uint32 connectorWeight;
        uint256 baseY;
    
    }

    function bondingCurveStorage() internal pure returns (BondingCurveData storage l) {
        bytes32 slot = BONDING_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    // Look into this function
    // function setCollateralToken(address _collateral) internal {
    //     collateral = _collateral;
    // }

    function setParams(
        uint32 _connectorWeight, 
        uint256 _baseY
    ) internal {
        require(_connectorWeight > 0 && _connectorWeight <= 1000000, "invalid values"); 
        require(_baseY > 0, "must valid baseY");

        connectorWeight = _connectorWeight;
        baseY = _baseY;
    }

    function setTreasuryAddress() external onlyBondingMinter {
        treasuryAddress = manager.treasuryAddress();
    }

    /// @notice 
    /// @dev 
    /// @param _collateralDeposited Amount of collateral
    /// @param _recipient An address to receive the NFT
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
        bytes memory tokReturned = toBytes(tokensReturned);
        share[_recipient] = tokensReturned;

        IUbiquiStick(manager.ubiquiStickAddress()).mint(
           _recipient, 
           BONDING_TOKEN_ID, 
           tokensReturned, 
           tokReturned 
        );

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

    function withdraw(uint256 _amount) external onlyBondingMinter {
        require(_amount <= poolBalance, "invalid amount");

        IERC20Ubiquity(collateral).transferFrom(address(this), treasuryAddress, _amount);
        poolBalance -= _amount;

        emit Withdraw(_amount);
    }
}
