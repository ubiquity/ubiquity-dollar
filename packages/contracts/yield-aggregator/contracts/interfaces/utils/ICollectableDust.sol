// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICollectableDust {
  event DustSent(address _to, address token, uint amount);
  event ProtocolTokenAdded(address _token);
  event ProtocolTokenRemoved(address _token);

  function addProtocolToken(address _token) external;

  function removeProtocolToken(address _token) external;

  function sendDust(
    address _to,
    address _token,
    uint _amount
  ) external;
}
