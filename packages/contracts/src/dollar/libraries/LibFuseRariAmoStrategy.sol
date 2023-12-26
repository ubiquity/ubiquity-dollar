// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IUbiquityDollarToken.sol";
import "../interfaces/IRariComptroller.sol";
import "../interfaces/IDollarAmoMinter.sol";
import "../interfaces/ICErc20Delegator.sol";
import "./Constants.sol";

library LibFuseRariAmoStrategy {
    using Math for uint256;

    bytes32 constant FUSERARIAMO_CONTROL_STORAGE_SLOT =
        bytes32(
            uint256(keccak256("ubiquity.contracts.fuserariamo.storage")) - 1
        );

    struct FuseRariAmoStrategyData {
        IUbiquityDollarToken DOLLAR;
        IDollarAmoMinter amoMinter;
        uint256 globalDollarCollateralRatio;
        address timelockAddress;
        address custodianAddress;
        address[] fusePoolsArray;
        mapping(address => bool) fusePools;
    }

    function fuseRariAmoStrategyStorage()
        internal
        pure
        returns (FuseRariAmoStrategyData storage l)
    {
        bytes32 slot = FUSERARIAMO_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function init(
        address _dollar,
        address[] memory _initialUnitrollers,
        address[] memory _initialFusePools,
        address _amoMinterAddress,
        uint256 _globalDollarCollateralRatio
    ) internal {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        strategyStorage.fusePoolsArray = _initialFusePools;
        for (uint256 i = 0; i < strategyStorage.fusePoolsArray.length; i++) {
            // Set the pools as valid
            strategyStorage.fusePools[_initialFusePools[i]] = true;

            // Enter markets
            address[] memory cTokens = new address[](1);
            cTokens[0] = strategyStorage.fusePoolsArray[i];
            IRariComptroller(_initialUnitrollers[i]).enterMarkets(cTokens);

            strategyStorage.DOLLAR = IUbiquityDollarToken(_dollar);
            strategyStorage.amoMinter = IDollarAmoMinter(_amoMinterAddress);
            strategyStorage.custodianAddress = strategyStorage
                .amoMinter
                .custodianAddress();
            strategyStorage.timelockAddress = strategyStorage
                .amoMinter
                .timelockAddress();

            strategyStorage
                .globalDollarCollateralRatio = _globalDollarCollateralRatio;
        }
    }

    function showAllocations()
        internal
        view
        returns (uint256[3] memory allocations)
    {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        allocations[0] = strategyStorage.DOLLAR.balanceOf(address(this));

        uint256 sumFusePoolTally = 0;
        for (uint i = 0; i < strategyStorage.fusePoolsArray.length; i++) {
            // Make sure the pool is enabled first
            address poolAddress = strategyStorage.fusePoolsArray[i];
            if (strategyStorage.fusePools[poolAddress]) {
                sumFusePoolTally = sumFusePoolTally + dollarInPoolByPoolId(i);
            }
        }
        allocations[1] = sumFusePoolTally;

        allocations[2] = allocations[0] + allocations[1]; // Total FRAX value
    }

    function dollarBalances()
        internal
        view
        returns (uint256 dollarVal, uint256 collatVal)
    {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        dollarVal = showAllocations()[2];
        collatVal =
            (dollarVal) *
            (strategyStorage.globalDollarCollateralRatio /
                UBIQUITY_POOL_PRICE_PRECISION);
    }

    function allPoolAddresses() internal view returns (address[] memory) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        return strategyStorage.fusePoolsArray;
    }

    function allPoolsLength() internal view returns (uint256) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        return strategyStorage.fusePoolsArray.length;
    }

    function poolAddrToId(
        address _poolAddress
    ) internal view returns (uint256) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        for (uint i = 0; i < strategyStorage.fusePoolsArray.length; i++) {
            if (strategyStorage.fusePoolsArray[i] == _poolAddress) {
                return i;
            }
        }
        revert("Pool not found");
    }

    function dollarInPoolByPoolId(
        uint256 _poolId
    ) internal view returns (uint256) {
        FuseRariAmoStrategyData
            storage strategyStorage = fuseRariAmoStrategyStorage();

        ICErc20Delegator delegator = ICErc20Delegator(
            strategyStorage.fusePoolsArray[_poolId]
        );
        uint256 cTokenBalance = delegator.balanceOf(address(this));
        return cTokenBalance * (delegator.exchangeRateStored() / (1e18));
    }
}
