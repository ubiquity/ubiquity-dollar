// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ICreditNFTManager.sol";
import "../interfaces/ICreditRedemptionCalculator.sol";
import "../interfaces/ICreditNFTRedemptionCalculator.sol";
import "../interfaces/IDollarMintCalculator.sol";
import "../interfaces/IDollarMintExcess.sol";
import "./TWAPOracleDollar3pool.sol";
import "./UbiquityDollarToken.sol";
import "./UbiquityCreditToken.sol";
import "./UbiquityDollarManager.sol";
import "./CreditNFT.sol";

/// @title A basic credit issuing and redemption mechanism for Credit NFT holders
/// @notice Allows users to burn their Ubiquity Dollar in exchange for Credit NFT
/// redeemable in the future
/// @notice Allows users to redeem individual Credit NFT or batch redeem
/// Credit NFT on a first-come first-serve basis
contract CreditNFTManager is ERC165, IERC1155Receiver {
    using SafeERC20 for IERC20Ubiquity;

    UbiquityDollarManager public manager;

    //the amount of dollars we minted this cycle, so we can calculate delta.
    // should be reset to 0 when cycle ends
    uint256 public dollarsMintedThisCycle;
    bool public debtCycle;
    uint256 public blockHeightDebt;
    uint256 public creditNFTLengthBlocks;
    uint256 public expiredCreditNFTConversionRate = 2;

    event ExpiredCreditNFTConversionRateChanged(
        uint256 newRate,
        uint256 previousRate
    );

    event CreditNFTLengthChanged(
        uint256 newCreditNFTLengthBlocks,
        uint256 previousCreditNFTLengthBlocks
    );

    modifier onlyCreditNFTManager() {
        require(
            manager.hasRole(manager.CREDIT_NFT_MANAGER_ROLE(), msg.sender),
            "Caller is not a Credit NFT manager"
        );
        _;
    }

    /// @param _manager the address of the manager contract so we can fetch variables
    /// @param _creditNFTLengthBlocks how many blocks Credit NFT last. can't be changed
    /// once set (unless migrated)
    constructor(address _manager, uint256 _creditNFTLengthBlocks) {
        manager = UbiquityDollarManager(_manager);
        creditNFTLengthBlocks = _creditNFTLengthBlocks;
    }

    function setExpiredCreditNFTConversionRate(
        uint256 rate
    ) external onlyCreditNFTManager {
        emit ExpiredCreditNFTConversionRateChanged(
            rate,
            expiredCreditNFTConversionRate
        );
        expiredCreditNFTConversionRate = rate;
    }

    function setCreditNFTLength(
        uint256 _creditNFTLengthBlocks
    ) external onlyCreditNFTManager {
        emit CreditNFTLengthChanged(
            _creditNFTLengthBlocks,
            creditNFTLengthBlocks
        );
        creditNFTLengthBlocks = _creditNFTLengthBlocks;
    }

    /// @dev called when a user wants to burn Ubiquity Dollar for Credit NFT.
    ///      should only be called when oracle is below a dollar
    /// @param amount the amount of dollars to exchange for Credit NFT
    function exchangeDollarsForCreditNFT(
        uint256 amount
    ) external returns (uint256) {
        uint256 twapPrice = _getTwapPrice();

        require(
            twapPrice < 1 ether,
            "Price must be below 1 to mint Credit NFT"
        );

        CreditNFT creditNFT = CreditNFT(manager.creditNFTAddress());
        creditNFT.updateTotalDebt();

        //we are in a down cycle so reset the cycle counter
        // and set the blockHeight Debt
        if (!debtCycle) {
            debtCycle = true;
            blockHeightDebt = block.number;
            dollarsMintedThisCycle = 0;
        }

        ICreditNFTRedemptionCalculator creditNFTCalculator = ICreditNFTRedemptionCalculator(
                manager.creditNFTCalculatorAddress()
            );
        uint256 creditNFTToMint = creditNFTCalculator.getCreditNFTAmount(
            amount
        );

        // we burn user's dollars.
        UbiquityDollarToken(manager.dollarTokenAddress()).burnFrom(
            msg.sender,
            amount
        );

        uint256 expiryBlockNumber = block.number + (creditNFTLengthBlocks);
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
    ) external returns (uint256) {
        uint256 twapPrice = _getTwapPrice();

        require(twapPrice < 1 ether, "Price must be below 1 to mint Credit");

        CreditNFT creditNFT = CreditNFT(manager.creditNFTAddress());
        creditNFT.updateTotalDebt();

        //we are in a down cycle so reset the cycle counter
        // and set the blockHeight Debt
        if (!debtCycle) {
            debtCycle = true;
            blockHeightDebt = block.number;
            dollarsMintedThisCycle = 0;
        }

        ICreditRedemptionCalculator creditCalculator = ICreditRedemptionCalculator(
                manager.creditCalculatorAddress()
            );
        uint256 creditToMint = creditCalculator.getCreditAmount(
            amount,
            blockHeightDebt
        );

        // we burn user's dollars.
        UbiquityDollarToken(manager.dollarTokenAddress()).burnFrom(
            msg.sender,
            amount
        );
        // mint Credit
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            manager.creditTokenAddress()
        );
        creditToken.mint(msg.sender, creditToMint);

        //give minted Credit amount
        return creditToMint;
    }

    /// @dev uses the current Credit NFT for dollars calculation to get Credit NFT for dollars
    /// @param amount the amount of dollars to exchange for Credit NFT
    function getCreditNFTReturnedForDollars(
        uint256 amount
    ) external view returns (uint256) {
        ICreditNFTRedemptionCalculator creditNFTCalculator = ICreditNFTRedemptionCalculator(
                manager.creditNFTCalculatorAddress()
            );
        return creditNFTCalculator.getCreditNFTAmount(amount);
    }

    /// @dev uses the current Credit for dollars calculation to get Credit for dollars
    /// @param amount the amount of dollars to exchange for Credit
    function getCreditReturnedForDollars(
        uint256 amount
    ) external view returns (uint256) {
        ICreditRedemptionCalculator creditCalculator = ICreditRedemptionCalculator(
                manager.creditCalculatorAddress()
            );
        return creditCalculator.getCreditAmount(amount, blockHeightDebt);
    }

    /// @dev should be called by this contract only when getting Credit NFT to be burnt
    function onERC1155Received(
        address operator,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external view override returns (bytes4) {
        if (manager.hasRole(manager.CREDIT_NFT_MANAGER_ROLE(), operator)) {
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

    /// @dev this method is never called by the contract so if called,
    /// it was called by someone else -> revert.
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        //reject the transfer
        return "";
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
        CreditNFT creditNFT = CreditNFT(manager.creditNFTAddress());

        require(id <= block.number, "Credit NFT has not expired");
        require(
            creditNFT.balanceOf(msg.sender, id) >= amount,
            "User not enough Credit NFT"
        );

        creditNFT.burnCreditNFT(msg.sender, amount, id);

        // Mint Governance Token to this contract. Transfer Governance Token to msg.sender i.e. Credit NFT holder
        IERC20Ubiquity governanceToken = IERC20Ubiquity(
            manager.governanceTokenAddress()
        );
        governanceAmount = amount / expiredCreditNFTConversionRate;
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
        CreditNFT creditNFT = CreditNFT(manager.creditNFTAddress());

        require(id > block.timestamp, "Credit NFT has expired");
        require(
            creditNFT.balanceOf(msg.sender, id) >= amount,
            "User not enough Credit NFT"
        );

        creditNFT.burnCreditNFT(msg.sender, amount, id);

        // Mint LP tokens to this contract. Transfer LP tokens to msg.sender i.e. Credit NFT holder
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            manager.creditTokenAddress()
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
        uint256 twapPrice = _getTwapPrice();
        require(twapPrice > 1 ether, "Price must be above 1");
        if (debtCycle) {
            debtCycle = false;
        }
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            manager.creditTokenAddress()
        );
        require(
            creditToken.balanceOf(msg.sender) >= amount,
            "User doesn't have enough Credit pool tokens."
        );

        UbiquityDollarToken dollarToken = UbiquityDollarToken(
            manager.dollarTokenAddress()
        );
        uint256 maxRedeemableCredit = dollarToken.balanceOf(address(this));

        if (maxRedeemableCredit <= 0) {
            mintClaimableDollars();
            maxRedeemableCredit = dollarToken.balanceOf(address(this));
        }

        uint256 creditToRedeem = amount;
        if (amount > maxRedeemableCredit) {
            creditToRedeem = maxRedeemableCredit;
        }
        creditToken.burnFrom(msg.sender, creditToRedeem);
        dollarToken.transfer(msg.sender, creditToRedeem);

        return amount - creditToRedeem;
    }

    /// @param id the block number of the Credit NFT
    /// @param amount the amount of Credit NFT to redeem
    /// @return amount of unredeemed Credit NFT
    function redeemCreditNFT(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        uint256 twapPrice = _getTwapPrice();

        require(
            twapPrice > 1 ether,
            "Price must be above 1 to redeem Credit NFT"
        );
        if (debtCycle) {
            debtCycle = false;
        }
        CreditNFT creditNFT = CreditNFT(manager.creditNFTAddress());

        require(id > block.number, "Credit NFT has expired");
        require(
            creditNFT.balanceOf(msg.sender, id) >= amount,
            "User not enough Credit NFT"
        );

        mintClaimableDollars();
        UbiquityDollarToken dollarToken = UbiquityDollarToken(
            manager.dollarTokenAddress()
        );
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            manager.creditTokenAddress()
        );
        // Credit have a priority on Credit NFT holder
        require(
            creditToken.totalSupply() <= dollarToken.balanceOf(address(this)),
            "There aren't enough Dollar to redeem currently"
        );
        uint256 maxRedeemableCreditNFT = dollarToken.balanceOf(address(this)) -
            creditToken.totalSupply();
        uint256 creditNFTToRedeem = amount;

        if (amount > maxRedeemableCreditNFT) {
            creditNFTToRedeem = maxRedeemableCreditNFT;
        }
        require(
            dollarToken.balanceOf(address(this)) > 0,
            "There aren't any Dollar to redeem currently"
        );

        // creditNFTManager must be an operator to transfer on behalf of msg.sender
        creditNFT.burnCreditNFT(msg.sender, creditNFTToRedeem, id);
        dollarToken.transfer(msg.sender, creditNFTToRedeem);

        return amount - (creditNFTToRedeem);
    }

    function mintClaimableDollars() public {
        CreditNFT creditNFT = CreditNFT(manager.creditNFTAddress());
        creditNFT.updateTotalDebt();

        // uint256 twapPrice = _getTwapPrice(); //unused variable. Why here?
        uint256 totalMintableDollars = IDollarMintCalculator(
            manager.dollarMintCalculatorAddress()
        ).getDollarsToMint();
        uint256 dollarsToMint = totalMintableDollars - (dollarsMintedThisCycle);
        //update the dollars for this cycle
        dollarsMintedThisCycle = totalMintableDollars;

        UbiquityDollarToken dollarToken = UbiquityDollarToken(
            manager.dollarTokenAddress()
        );
        // Dollar should be minted to address(this)
        dollarToken.mint(address(this), dollarsToMint);
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            manager.creditTokenAddress()
        );

        uint256 currentRedeemableBalance = dollarToken.balanceOf(address(this));
        uint256 totalOutstandingDebt = creditNFT.getTotalOutstandingDebt() +
            creditToken.totalSupply();

        if (currentRedeemableBalance > totalOutstandingDebt) {
            uint256 excessDollars = currentRedeemableBalance -
                (totalOutstandingDebt);

            IDollarMintExcess dollarsDistributor = IDollarMintExcess(
                manager.getExcessDollarsDistributor(address(this))
            );
            // transfer excess dollars to the distributor and tell it to distribute
            dollarToken.transfer(
                manager.getExcessDollarsDistributor(address(this)),
                excessDollars
            );
            dollarsDistributor.distributeDollars();
        }
    }

    function _getTwapPrice() internal returns (uint256) {
        TWAPOracleDollar3pool(manager.twapOracleAddress()).update();
        return
            TWAPOracleDollar3pool(manager.twapOracleAddress()).consult(
                manager.dollarTokenAddress()
            );
    }
}
