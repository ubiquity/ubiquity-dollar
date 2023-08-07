// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./04_UbiquityCredit.s.sol";

contract StakingShareScript is CreditScript {
    function run() public virtual override {
        super.run();
        vm.startBroadcast(deployerPrivateKey);

        // grant diamond token minter rights
        IAccessControl.grantRole(STAKING_SHARE_MINTER_ROLE, address(diamond));
        // add staking shares
        string
            memory uri = "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/";

        address stakingShareAddress = address(
            new StakingShare(address(diamond), uri)
        );
        IManager.setStakingShareAddress(stakingShareAddress);

        vm.stopBroadcast();
    }
}
