// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IVaultConfigurator {
    function addWhitelist(address receiver) external;
    function removeWhitelist(address receiver) external;
    function allowStrategy(address strategyAddr) external;
    function prevetnStrategy(address strategyAddr) external;
    function pause() external;
    function unpause() external;
    
}
