// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IVaultConfigurator {
    event WhitelistAdded(address receiver);
    event WhitelistRemoved(address receiver);
    event StrategyAllowed(address receiver);
    event StrategyPrevented(address receiver);
    event Puased();
    event UnPuased();

    function addWhitelist(address receiver) external;
    function removeWhitelist(address receiver) external;
    function allowStrategy(address strategyAddr) external;
    function prevetnStrategy(address strategyAddr) external;
    function pause() external;
    function unpause() external;
    function updateuCRrate(uint256) external;
    function twapPriceProvde(address )external view returns(uint256);
}
