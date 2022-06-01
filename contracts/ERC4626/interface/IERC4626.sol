// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/// @notice Minimal ERC4626 tokenized Vault implementation.
interface IERC4626 is IERC20{

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    // ERC20 public immutable asset;

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver, address stretegyAddr) external  returns (uint256 shares);
    function mint(uint256 shares, address receiver) external returns (uint256 assets);
    function withdraw(
        uint256 assets,
        uint256 uCRpercentage,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function redeem(
        uint256 shares,
        uint256 uCRpercentage,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() external view returns (uint256);
    function convertToShares(uint256 assets) external view  returns (uint256);
    function convertToAssets(uint256 shares) external view  returns (uint256);
    function previewDeposit(uint256 assets) external view  returns (uint256) ;
    function previewMint(uint256 shares) external view  returns (uint256);
    function previewWithdraw(uint256 assets) external view  returns (uint256);
    function previewRedeem(uint256 shares) external view  returns (uint256);

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) external view  returns (uint256);
    function maxMint(address) external view  returns (uint256);
    function maxWithdraw(address owner) external view  returns (uint256);
    function maxRedeem(address owner) external view  returns (uint256);
}
