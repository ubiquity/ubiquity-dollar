// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CreditNft} from "../../dollar/core/CreditNft.sol";
import {CREDIT_NFT_MANAGER_ROLE} from "./Constants.sol";
import {IERC20Ubiquity} from "../../dollar/interfaces/IERC20Ubiquity.sol";
import {IDollarMintExcess} from "../../dollar/interfaces/IDollarMintExcess.sol";
import {LibAppStorage, AppStorage} from "./LibAppStorage.sol";
import {LibCreditRedemptionCalculator} from "./LibCreditRedemptionCalculator.sol";
import {LibTWAPOracle} from "./LibTWAPOracle.sol";
import {LibCreditNftRedemptionCalculator} from "./LibCreditNftRedemptionCalculator.sol";
import {UbiquityCreditToken} from "../../dollar/core/UbiquityCreditToken.sol";
import {LibAccessControl} from "./LibAccessControl.sol";
import {IDollarMintCalculator} from "../../dollar/interfaces/IDollarMintCalculator.sol";

/**
 * @notice Library for basic credit issuing and redemption mechanism for Credit NFT and Credit holders
 * @notice Allows users to burn their Dollars in exchange for Credit NFTs or Credits redeemable in the future
 * @notice Allows users to:
 * - redeem individual Credit NFT or batch redeem Credit NFT on a first-come first-serve basis
 * - redeem Credits for Dollars
 */
library LibCreditNftManager {
    using SafeERC20 for IERC20Ubiquity;

    /// @notice Storage slot used to store data for this library
    bytes32 constant CREDIT_NFT_MANAGER_STORAGE_SLOT =
        bytes32(
            uint256(
                keccak256("ubiquity.contracts.credit.nft.manager.storage")
            ) - 1
        );

    /// @notice Emitted when Credit NFT to Governance conversion rate was updated
    event ExpiredCreditNftConversionRateChanged(
        uint256 newRate,
        uint256 previousRate
    );

    /// @notice Emitted when Credit NFT block expiration length was updated
    event CreditNftLengthChanged(
        uint256 newCreditNftLengthBlocks,
        uint256 previousCreditNftLengthBlocks
    );

    /// @notice Struct used as a storage for the current library
    struct CreditNftManagerData {
        //the amount of dollars we minted this cycle, so we can calculate delta.
        // should be reset to 0 when cycle ends
        uint256 dollarsMintedThisCycle;
        uint256 blockHeightDebt;
        uint256 creditNftLengthBlocks;
        uint256 expiredCreditNftConversionRate;
        bool debtCycle;
    }

    /**
     * @notice Returns struct used as a storage for this library
     * @return l Struct used as a storage
     */
    function creditNftStorage()
        internal
        pure
        returns (CreditNftManagerData storage l)
    {
        bytes32 slot = CREDIT_NFT_MANAGER_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice Returns Credit NFT to Governance conversion rate
     * @return Conversion rate
     */
    function expiredCreditNftConversionRate() internal view returns (uint256) {
        return creditNftStorage().expiredCreditNftConversionRate;
    }

    /**
     * @notice Credit NFT to Governance conversion rate
     * @notice When Credit NFTs are expired they can be converted to
     * Governance tokens using `rate` conversion rate
     * @param rate Credit NFT to Governance tokens conversion rate
     */
    function setExpiredCreditNftConversionRate(uint256 rate) internal {
        emit ExpiredCreditNftConversionRateChanged(
            rate,
            creditNftStorage().expiredCreditNftConversionRate
        );
        creditNftStorage().expiredCreditNftConversionRate = rate;
    }

    /**
     * @notice Sets Credit NFT block lifespan
     * @param _creditNftLengthBlocks The number of blocks during which Credit NFTs can be
     * redeemed for Dollars
     */
    function setCreditNftLength(uint256 _creditNftLengthBlocks) internal {
        emit CreditNftLengthChanged(
            _creditNftLengthBlocks,
            creditNftStorage().creditNftLengthBlocks
        );
        creditNftStorage().creditNftLengthBlocks = _creditNftLengthBlocks;
    }

    /**
     * @notice Returns Credit NFT block lifespan
     * @return Number of blocks during which Credit NFTs can be
     * redeemed for Dollars
     */
    function creditNftLengthBlocks() internal view returns (uint256) {
        return creditNftStorage().creditNftLengthBlocks;
    }

    /**
     * @notice Burns Dollars in exchange for Credit NFTs
     * @notice Should only be called when Dollar price < 1$
     * @param amount Amount of Dollars to exchange for Credit NFTs
     * @return Expiry block number when Credit NFTs can no longer be redeemed for Dollars
     */
    function exchangeDollarsForCreditNft(
        uint256 amount
    ) internal returns (uint256) {
        uint256 twapPrice = LibTWAPOracle.getTwapPrice();

        require(
            twapPrice < 1 ether,
            "Price must be below 1 to mint Credit NFT"
        );

        CreditNft creditNft = CreditNft(
            LibAppStorage.appStorage().creditNftAddress
        );
        creditNft.updateTotalDebt();
        CreditNftManagerData storage cs = creditNftStorage();
        //we are in a down cycle so reset the cycle counter
        // and set the blockHeight Debt
        if (!cs.debtCycle) {
            cs.debtCycle = true;
            cs.blockHeightDebt = block.number;
            cs.dollarsMintedThisCycle = 0;
        }

        uint256 creditNftToMint = LibCreditNftRedemptionCalculator
            .getCreditNftAmount(amount);

        // we burn user's dollars.
        IERC20Ubiquity(LibAppStorage.appStorage().dollarTokenAddress).burnFrom(
            msg.sender,
            amount
        );

        uint256 expiryBlockNumber = block.number + (cs.creditNftLengthBlocks);
        creditNft.mintCreditNft(msg.sender, creditNftToMint, expiryBlockNumber);

        //give the caller the block number of the minted nft
        return expiryBlockNumber;
    }

    /**
     * @notice Burns Dollars in exchange for Credit tokens
     * @notice Should only be called when Dollar price < 1$
     * @param amount Amount of Dollars to burn
     * @return Amount of Credits minted
     */
    function exchangeDollarsForCredit(
        uint256 amount
    ) internal returns (uint256) {
        uint256 twapPrice = LibTWAPOracle.getTwapPrice();

        require(twapPrice < 1 ether, "Price must be below 1 to mint Credit");
        AppStorage storage store = LibAppStorage.appStorage();
        CreditNft creditNft = CreditNft(store.creditNftAddress);
        creditNft.updateTotalDebt();

        //we are in a down cycle so reset the cycle counter
        // and set the blockHeight Debt
        if (!creditNftStorage().debtCycle) {
            CreditNftManagerData storage cs = creditNftStorage();
            cs.debtCycle = true;
            cs.blockHeightDebt = block.number;
            cs.dollarsMintedThisCycle = 0;
        }

        uint256 creditToMint = LibCreditRedemptionCalculator.getCreditAmount(
            amount,
            creditNftStorage().blockHeightDebt
        );

        // we burn user's dollars.
        IERC20Ubiquity(store.dollarTokenAddress).burnFrom(msg.sender, amount);
        // mint Credit
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            store.creditTokenAddress
        );
        creditToken.mint(msg.sender, creditToMint);

        //give minted Credit amount
        return creditToMint;
    }

    /**
     * @notice Returns amount of Credit NFTs to be minted for the `amount` of Dollars to burn
     * @param amount Amount of Dollars to burn
     * @return Amount of Credit NFTs to be minted
     */
    function getCreditNftReturnedForDollars(
        uint256 amount
    ) internal view returns (uint256) {
        return LibCreditNftRedemptionCalculator.getCreditNftAmount(amount);
    }

    /**
     * @notice Returns the amount of Credit tokens to be minter for the provided `amount` of Dollars to burn
     * @param amount Amount of Dollars to burn
     * @return Amount of Credits to be minted
     */
    function getCreditReturnedForDollars(
        uint256 amount
    ) internal view returns (uint256) {
        return
            LibCreditRedemptionCalculator.getCreditAmount(
                amount,
                creditNftStorage().blockHeightDebt
            );
    }

    /**
     * @notice Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
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

    /**
     * @notice Burns expired Credit NFTs for Governance tokens at `expiredCreditNftConversionRate` rate
     * @param id Credit NFT timestamp
     * @param amount Amount of Credit NFTs to burn
     * @return governanceAmount Amount of Governance tokens minted to Credit NFT holder
     */
    function burnExpiredCreditNftForGovernance(
        uint256 id,
        uint256 amount
    ) public returns (uint256 governanceAmount) {
        // Check whether Credit NFT hasn't expired --> Burn Credit NFT.
        CreditNft creditNft = CreditNft(
            LibAppStorage.appStorage().creditNftAddress
        );

        require(id <= block.number, "Credit NFT has not expired");
        require(
            creditNft.balanceOf(msg.sender, id) >= amount,
            "User not enough Credit NFT"
        );

        creditNft.burnCreditNft(msg.sender, amount, id);

        // Mint Governance Token to this contract. Transfer Governance Token to msg.sender i.e. Credit NFT holder
        IERC20Ubiquity governanceToken = IERC20Ubiquity(
            LibAppStorage.appStorage().governanceTokenAddress
        );
        governanceAmount =
            amount /
            creditNftStorage().expiredCreditNftConversionRate;
        governanceToken.mint(msg.sender, governanceAmount);
    }

    /**
     * TODO: Should we leave it ?
     * @notice Burns Credit NFTs for Credit tokens
     * @param id Credit NFT timestamp
     * @param amount Amount of Credit NFTs to burn
     * @return Credit tokens balance of `msg.sender`
     */
    function burnCreditNftForCredit(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        // Check whether Credit NFT hasn't expired --> Burn Credit NFT.
        CreditNft creditNft = CreditNft(
            LibAppStorage.appStorage().creditNftAddress
        );
        require(id > block.timestamp, "Credit NFT has expired");
        require(
            creditNft.balanceOf(msg.sender, id) >= amount,
            "User not enough Credit NFT"
        );

        creditNft.burnCreditNft(msg.sender, amount, id);

        // Mint LP tokens to this contract. Transfer LP tokens to msg.sender i.e. Credit NFT holder
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            LibAppStorage.appStorage().creditTokenAddress
        );
        creditToken.mint(address(this), amount);
        creditToken.transfer(msg.sender, amount);

        return creditToken.balanceOf(msg.sender);
    }

    /**
     * @notice Burns Credit tokens for Dollars when Dollar price > 1$
     * @param amount Amount of Credits to burn
     * @return Amount of unredeemed Credits
     */
    function burnCreditTokensForDollars(
        uint256 amount
    ) public returns (uint256) {
        uint256 twapPrice = LibTWAPOracle.getTwapPrice();
        require(twapPrice > 1 ether, "Price must be above 1");
        if (creditNftStorage().debtCycle) {
            creditNftStorage().debtCycle = false;
        }
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            LibAppStorage.appStorage().creditTokenAddress
        );
        require(
            creditToken.balanceOf(msg.sender) >= amount,
            "User doesn't have enough Credit pool tokens."
        );
        IERC20Ubiquity dollar = IERC20Ubiquity(
            LibAppStorage.appStorage().dollarTokenAddress
        );
        uint256 maxRedeemableCredit = dollar.balanceOf(address(this));

        if (maxRedeemableCredit <= 0) {
            mintClaimableDollars();
            maxRedeemableCredit = dollar.balanceOf(address(this));
        }

        uint256 creditToRedeem = amount;
        if (amount > maxRedeemableCredit) {
            creditToRedeem = maxRedeemableCredit;
        }
        creditToken.burnFrom(msg.sender, creditToRedeem);
        dollar.transfer(msg.sender, creditToRedeem);

        return amount - creditToRedeem;
    }

    /**
     * @notice Burns Credit NFTs for Dollars when Dollar price > 1$
     * @param id Credit NFT expiry block number
     * @param amount Amount of Credit NFTs to burn
     * @return Amount of unredeemed Credit NFTs
     */
    function redeemCreditNft(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        uint256 twapPrice = LibTWAPOracle.getTwapPrice();

        require(
            twapPrice > 1 ether,
            "Price must be above 1 to redeem Credit NFT"
        );
        if (creditNftStorage().debtCycle) {
            creditNftStorage().debtCycle = false;
        }
        AppStorage storage store = LibAppStorage.appStorage();
        CreditNft creditNft = CreditNft(store.creditNftAddress);

        require(id > block.number, "Credit NFT has expired");
        require(
            creditNft.balanceOf(msg.sender, id) >= amount,
            "User not enough Credit NFT"
        );

        mintClaimableDollars();

        UbiquityCreditToken creditToken = UbiquityCreditToken(
            store.creditTokenAddress
        );
        IERC20Ubiquity dollar = IERC20Ubiquity(store.dollarTokenAddress);
        // Credit have a priority on Credit NFT holder
        require(
            creditToken.totalSupply() <= dollar.balanceOf(address(this)),
            "There aren't enough Dollar to redeem currently"
        );
        uint256 maxRedeemableCreditNft = dollar.balanceOf(address(this)) -
            creditToken.totalSupply();
        uint256 creditNftToRedeem = amount;

        if (amount > maxRedeemableCreditNft) {
            creditNftToRedeem = maxRedeemableCreditNft;
        }
        require(
            dollar.balanceOf(address(this)) > 0,
            "There aren't any Dollar to redeem currently"
        );

        // creditNftManager must be an operator to transfer on behalf of msg.sender
        creditNft.burnCreditNft(msg.sender, creditNftToRedeem, id);

        dollar.transfer(msg.sender, creditNftToRedeem);

        return amount - (creditNftToRedeem);
    }

    /**
     * @notice Mints Dollars when Dollar price > 1$
     * @notice Distributes excess Dollars this way:
     * - 50% goes to the treasury address
     * - 10% goes for burning Dollar-Governance LP tokens in a DEX pool
     * - 40% goes to the Staking contract
     */
    function mintClaimableDollars() public {
        AppStorage storage store = LibAppStorage.appStorage();

        CreditNft creditNft = CreditNft(store.creditNftAddress);
        creditNft.updateTotalDebt();

        uint256 totalMintableDollars = IDollarMintCalculator(address(this))
            .getDollarsToMint();
        uint256 dollarsToMint = totalMintableDollars -
            (creditNftStorage().dollarsMintedThisCycle);
        //update the dollars for this cycle
        creditNftStorage().dollarsMintedThisCycle = totalMintableDollars;

        // Dollar should be minted to address(this)
        IERC20Ubiquity dollar = IERC20Ubiquity(store.dollarTokenAddress);
        dollar.mint(address(this), dollarsToMint);
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            store.creditTokenAddress
        );

        uint256 currentRedeemableBalance = dollar.balanceOf(address(this));
        uint256 totalOutstandingDebt = creditNft.getTotalOutstandingDebt() +
            creditToken.totalSupply();

        if (currentRedeemableBalance > totalOutstandingDebt) {
            uint256 excessDollars = currentRedeemableBalance -
                (totalOutstandingDebt);

            IDollarMintExcess dollarsDistributor = IDollarMintExcess(
                address(this)
            );
            // transfer excess dollars to the distributor and tell it to distribute
            dollar.transfer(address(this), excessDollars);
            dollarsDistributor.distributeDollars();
        }
    }
}
