// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.10;

import {ERC20} from 'openzeppelin-contracts/contracts/token/ERC20/ERC20.sol';
import {ERC4626} from 'openzeppelin-contracts/contracts/token/ERC20/extensions/ERC4626.sol';

contract MockERC4626 is ERC4626 {
  uint public beforeWithdrawHookCalledCounter = 0;
  uint public afterDepositHookCalledCounter = 0;

  constructor(
    ERC20 _underlying,
    string memory _name,
    string memory _symbol
  ) ERC4626(_underlying) ERC20(_name, _symbol) {}

  /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

  function deposit(uint assets, address receiver) public virtual override returns (uint shares) {
    require(assets <= maxDeposit(receiver), 'ERC4626: deposit more than max');

    // Check for rounding error since we round down in previewDeposit.
    require((shares = previewDeposit(assets)) != 0, 'ZERO_SHARES');
    _deposit(_msgSender(), receiver, assets, shares);
    afterDeposit(assets, shares);
    return shares;
  }

  function mint(uint shares, address receiver) public virtual override returns (uint assets) {
    require(shares <= maxMint(receiver), 'ERC4626: mint more than max');

    uint assets = previewMint(shares);
    _deposit(_msgSender(), receiver, assets, shares);
    afterDeposit(assets, shares);
    return assets;
  }

  function withdraw(
    uint assets,
    address receiver,
    address owner
  ) public virtual override returns (uint shares) {
    require(assets <= maxWithdraw(owner), 'ERC4626: withdraw more than max');

    uint shares = previewWithdraw(assets);
    beforeWithdraw(assets, shares);
    _withdraw(_msgSender(), receiver, owner, assets, shares);

    return shares;
  }

  function redeem(
    uint shares,
    address receiver,
    address owner
  ) public virtual override returns (uint assets) {
    // Check for rounding error since we round down in previewRedeem.
    require((assets = previewRedeem(shares)) != 0, 'ZERO_ASSETS');

    beforeWithdraw(assets, shares);

    _withdraw(_msgSender(), receiver, owner, assets, shares);
    return assets;
  }

  function beforeWithdraw(uint, uint) internal virtual {
    beforeWithdrawHookCalledCounter++;
  }

  function afterDeposit(uint, uint) internal virtual {
    afterDepositHookCalledCounter++;
  }
}
