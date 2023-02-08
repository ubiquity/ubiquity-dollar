// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CreditNFT} from "../../dollar/core/CreditNFT.sol";
import {CREDIT_NFT_MANAGER_ROLE} from "./Constants.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/IERC20Ubiquity.sol";
import {IDollarMintExcess} from "../../dollar/interfaces/IDollarMintExcess.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {LibDollar} from "./LibDollar.sol";
import {LibCreditRedemptionCalculator} from "./LibCreditRedemptionCalculator.sol";
import {LibTWAPOracle} from "./LibTWAPOracle.sol";
import {LibCreditNFTRedemptionCalculator} from "./LibCreditNFTRedemptionCalculator.sol";
import {UbiquityCreditToken} from "../../dollar/core/UbiquityCreditToken.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import {IDollarMintCalculator} from "../../dollar/interfaces/IDollarMintCalculator.sol";
import {DollarTokenFacet} from "../facets/DollarTokenFacet.sol";

/// @title A basic credit issuing and redemption mechanism for Credit NFT holders
/// @notice Allows users to burn their Ubiquity Dollar in exchange for Credit NFT
/// redeemable in the future
/// @notice Allows users to redeem individual Credit NFT or batch redeem
/// Credit NFT on a first-come first-serve basis
library LibCreditNFTManager {
    using SafeERC20 for IERC20Ubiquity;

    bytes32 constant CREDIT_NFT_MANAGER_STORAGE_SLOT =
        keccak256("ubiquity.contracts.credit.nft.manager.storage");

    event ExpiredCreditNFTConversionRateChanged(
        uint256 newRate,
        uint256 previousRate
    );

    event CreditNFTLengthChanged(
        uint256 newCreditNFTLengthBlocks,
        uint256 previousCreditNFTLengthBlocks
    );

    struct CreditNFTMgrData {
        //the amount of dollars we minted this cycle, so we can calculate delta.
        // should be reset to 0 when cycle ends
        uint256 dollarsMintedThisCycle;
        uint256 blockHeightDebt;
        uint256 creditNFTLengthBlocks;
        uint256 expiredCreditNFTConversionRate;
        bool debtCycle;
    }

    function creditNFTStorage()
        internal
        pure
        returns (CreditNFTMgrData storage l)
    {
        bytes32 slot = CREDIT_NFT_MANAGER_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function expiredCreditNFTConversionRate() internal view returns (uint256) {
        return creditNFTStorage().expiredCreditNFTConversionRate;
    }

    function setExpiredCreditNFTConversionRate(uint256 rate) internal {
        emit ExpiredCreditNFTConversionRateChanged(
            rate,
            creditNFTStorage().expiredCreditNFTConversionRate
        );
        creditNFTStorage().expiredCreditNFTConversionRate = rate;
    }

    function setCreditNFTLength(uint256 _creditNFTLengthBlocks) internal {
        emit CreditNFTLengthChanged(
            _creditNFTLengthBlocks,
            creditNFTStorage().creditNFTLengthBlocks
        );
        creditNFTStorage().creditNFTLengthBlocks = _creditNFTLengthBlocks;
    }

    function creditNFTLengthBlocks() internal view returns (uint256) {
        return creditNFTStorage().creditNFTLengthBlocks;
    }

    /// @dev called when a user wants to burn Ubiquity Dollar for Credit NFT.
    ///      should only be called when oracle is below a dollar
    /// @param amount the amount of dollars to exchange for Credit NFT
    function exchangeDollarsForCreditNFT(
        uint256 amount
    ) internal returns (uint256) {
        uint256 twapPrice = LibTWAPOracle.getTwapPrice();

        require(
            twapPrice < 1 ether,
            "Price must be below 1 to mint Credit NFT"
        );

        CreditNFT creditNFT = CreditNFT(
            LibAppStorage.appStorage().creditNFTAddress
        );
        creditNFT.updateTotalDebt();
        CreditNFTMgrData storage cs = creditNFTStorage();
        //we are in a down cycle so reset the cycle counter
        // and set the blockHeight Debt
        if (!cs.debtCycle) {
            cs.debtCycle = true;
            cs.blockHeightDebt = block.number;
            cs.dollarsMintedThisCycle = 0;
        }

        uint256 creditNFTToMint = LibCreditNFTRedemptionCalculator
            .getCreditNFTAmount(amount);

        // we burn user's dollars.
        LibDollar.burn(msg.sender, amount);

        uint256 expiryBlockNumber = block.number + (cs.creditNFTLengthBlocks);
        creditNFT.mintCreditNFT(msg.sender, creditNFTToMint, expiryBlockNumber);

        //give the caller the block number of the minted nft
        return expiryBlockNumber;
    }

    /// @dev called when a user wants to burn Dollar for Credit.
    ///      should only be called when oracle is below a dollar
    /// @param amount the amount of dollars to exchange for Credit
    /// @return amount of Credit tokens minted
    function exchangeDollarsForCredit(
        uint256 amount
    ) internal returns (uint256) {
        uint256 twapPrice = LibTWAPOracle.getTwapPrice();

        require(twapPrice < 1 ether, "Price must be below 1 to mint Credit");

        CreditNFT creditNFT = CreditNFT(
            LibAppStorage.appStorage().creditNFTAddress
        );
        creditNFT.updateTotalDebt();

        //we are in a down cycle so reset the cycle counter
        // and set the blockHeight Debt
        if (!creditNFTStorage().debtCycle) {
            CreditNFTMgrData storage cs = creditNFTStorage();
            cs.debtCycle = true;
            cs.blockHeightDebt = block.number;
            cs.dollarsMintedThisCycle = 0;
        }

        uint256 creditToMint = LibCreditRedemptionCalculator.getCreditAmount(
            amount,
            creditNFTStorage().blockHeightDebt
        );

        // we burn user's dollars.
        LibDollar.burn(msg.sender, amount);
        // mint Credit
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            LibAppStorage.appStorage().creditTokenAddress
        );
        creditToken.mint(msg.sender, creditToMint);

        //give minted Credit amount
        return creditToMint;
    }

    /// @dev uses the current Credit NFT for dollars calculation to get Credit NFT for dollars
    /// @param amount the amount of dollars to exchange for Credit NFT
    function getCreditNFTReturnedForDollars(
        uint256 amount
    ) internal view returns (uint256) {
        return LibCreditNFTRedemptionCalculator.getCreditNFTAmount(amount);
    }

    /// @dev uses the current Credit for dollars calculation to get Credit for dollars
    /// @param amount the amount of dollars to exchange for Credit
    function getCreditReturnedForDollars(
        uint256 amount
    ) internal view returns (uint256) {
        return
            LibCreditRedemptionCalculator.getCreditAmount(
                amount,
                creditNFTStorage().blockHeightDebt
            );
    }

    /// @dev should be called by this contract only when getting Credit NFT to be burnt
    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) internal view returns (bytes4) {
        if (LibAccessControl.hasRole(CREDIT_NFT_MANAGER_ROLE, operator)) {
            //allow the transfer since it originated from this contract
            return
                bytes4(
                    keccak256(
                        "onERC1155Received(address,address,uint256,uint256,bytes)"
                    )
                );
        } else {
            //reject the transfer
            return "";
        }
    }

    /// @dev let Credit NFT holder burn expired Credit NFT for Governance Token. Doesn't make TWAP > 1 check.
    /// @param id the timestamp of the Credit NFT
    /// @param amount the amount of Credit NFT to redeem
    /// @return governanceAmount amount of Governance Token minted to Credit NFT holder
    function burnExpiredCreditNFTForGovernance(
        uint256 id,
        uint256 amount
    ) public returns (uint256 governanceAmount) {
        // Check whether Credit NFT hasn't expired --> Burn Credit NFT.
        CreditNFT creditNFT = CreditNFT(
            LibAppStorage.appStorage().creditNFTAddress
        );

        require(id <= block.number, "Credit NFT has not expired");
        require(
            creditNFT.balanceOf(msg.sender, id) >= amount,
            "User not enough Credit NFT"
        );

        creditNFT.burnCreditNFT(msg.sender, amount, id);

        // Mint Governance Token to this contract. Transfer Governance Token to msg.sender i.e. Credit NFT holder
        IERC20Ubiquity governanceToken = IERC20Ubiquity(
            LibAppStorage.appStorage().governanceTokenAddress
        );
        governanceAmount =
            amount /
            creditNFTStorage().expiredCreditNFTConversionRate;
        governanceToken.mint(msg.sender, governanceAmount);
    }

    // TODO should we leave it ?
    /// @dev Lets Credit NFT holder burn Credit NFT for Credit. Doesn't make TWAP > 1 check.
    /// @param id the timestamp of the Credit NFT
    /// @param amount the amount of Credit NFT to redeem
    /// @return amount of Credit pool tokens (i.e. LP tokens) minted to Credit NFT holder
    function burnCreditNFTForCredit(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        // Check whether Credit NFT hasn't expired --> Burn Credit NFT.
        CreditNFT creditNFT = CreditNFT(
            LibAppStorage.appStorage().creditNFTAddress
        );

        require(id > block.timestamp, "Credit NFT has expired");
        require(
            creditNFT.balanceOf(msg.sender, id) >= amount,
            "User not enough Credit NFT"
        );

        creditNFT.burnCreditNFT(msg.sender, amount, id);

        // Mint LP tokens to this contract. Transfer LP tokens to msg.sender i.e. Credit NFT holder
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            LibAppStorage.appStorage().creditTokenAddress
        );
        creditToken.mint(address(this), amount);
        creditToken.transfer(msg.sender, amount);

        return creditToken.balanceOf(msg.sender);
    }

    /// @dev Exchange Credit pool token for Dollar tokens.
    /// @param amount Amount of Credit tokens to burn in exchange for Dollar tokens.
    /// @return amount of unredeemed Credit
    function burnCreditTokensForDollars(
        uint256 amount
    ) public returns (uint256) {
        uint256 twapPrice = LibTWAPOracle.getTwapPrice();
        require(twapPrice > 1 ether, "Price must be above 1");
        if (creditNFTStorage().debtCycle) {
            creditNFTStorage().debtCycle = false;
        }
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            LibAppStorage.appStorage().creditTokenAddress
        );
        require(
            creditToken.balanceOf(msg.sender) >= amount,
            "User doesn't have enough Credit pool tokens."
        );

        uint256 maxRedeemableCredit = LibDollar.balanceOf(address(this));

        if (maxRedeemableCredit <= 0) {
            mintClaimableDollars();
            maxRedeemableCredit = LibDollar.balanceOf(address(this));
        }

        uint256 creditToRedeem = amount;
        if (amount > maxRedeemableCredit) {
            creditToRedeem = maxRedeemableCredit;
        }
        creditToken.burnFrom(msg.sender, creditToRedeem);
        DollarTokenFacet(address(this)).transfer(msg.sender, creditToRedeem);

        return amount - creditToRedeem;
    }

    /// @param id the block number of the Credit NFT
    /// @param amount the amount of Credit NFT to redeem
    /// @return amount of unredeemed Credit NFT
    function redeemCreditNFT(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        uint256 twapPrice = LibTWAPOracle.getTwapPrice();

        require(
            twapPrice > 1 ether,
            "Price must be above 1 to redeem Credit NFT"
        );
        if (creditNFTStorage().debtCycle) {
            creditNFTStorage().debtCycle = false;
        }
        AppStorage storage s = LibAppStorage.appStorage();
        CreditNFT creditNFT = CreditNFT(s.creditNFTAddress);

        require(id > block.number, "Credit NFT has expired");
        require(
            creditNFT.balanceOf(msg.sender, id) >= amount,
            "User not enough Credit NFT"
        );

        mintClaimableDollars();

        UbiquityCreditToken creditToken = UbiquityCreditToken(
            s.creditTokenAddress
        );

        // Credit have a priority on Credit NFT holder
        require(
            creditToken.totalSupply() <= LibDollar.balanceOf(address(this)),
            "There aren't enough Dollar to redeem currently"
        );
        uint256 maxRedeemableCreditNFT = LibDollar.balanceOf(address(this)) -
            creditToken.totalSupply();
        uint256 creditNFTToRedeem = amount;

        if (amount > maxRedeemableCreditNFT) {
            creditNFTToRedeem = maxRedeemableCreditNFT;
        }
        require(
            LibDollar.balanceOf(address(this)) > 0,
            "There aren't any Dollar to redeem currently"
        );

        // creditNFTManager must be an operator to transfer on behalf of msg.sender
        creditNFT.burnCreditNFT(msg.sender, creditNFTToRedeem, id);
        DollarTokenFacet(address(this)).transfer(msg.sender, creditNFTToRedeem);

        return amount - (creditNFTToRedeem);
    }

    function mintClaimableDollars() public {
        AppStorage storage s = LibAppStorage.appStorage();

        CreditNFT creditNFT = CreditNFT(s.creditNFTAddress);
        creditNFT.updateTotalDebt();

        uint256 totalMintableDollars = IDollarMintCalculator(
            s.dollarMintCalculatorAddress
        ).getDollarsToMint();
        uint256 dollarsToMint = totalMintableDollars -
            (creditNFTStorage().dollarsMintedThisCycle);
        //update the dollars for this cycle
        creditNFTStorage().dollarsMintedThisCycle = totalMintableDollars;

        // Dollar should be minted to address(this)
        LibDollar.mint(address(this), dollarsToMint);
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            s.creditTokenAddress
        );

        uint256 currentRedeemableBalance = LibDollar.balanceOf(address(this));
        uint256 totalOutstandingDebt = creditNFT.getTotalOutstandingDebt() +
            creditToken.totalSupply();

        if (currentRedeemableBalance > totalOutstandingDebt) {
            uint256 excessDollars = currentRedeemableBalance -
                (totalOutstandingDebt);

            IDollarMintExcess dollarsDistributor = IDollarMintExcess(
                s._excessDollarDistributors[address(this)]
            );
            // transfer excess dollars to the distributor and tell it to distribute
            DollarTokenFacet(address(this)).transfer(
                s._excessDollarDistributors[address(this)],
                excessDollars
            );
            dollarsDistributor.distributeDollars();
        }
    }
}
