// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ICreditNftManager.sol";
import "../interfaces/ICreditRedemptionCalculator.sol";
import "../interfaces/ICreditNftRedemptionCalculator.sol";
import "../interfaces/IDollarMintCalculator.sol";
import "../interfaces/IDollarMintExcess.sol";
import "./TWAPOracleDollar3pool.sol";
import "./UbiquityDollarToken.sol";
import "./UbiquityCreditToken.sol";
import "./UbiquityDollarManager.sol";
import "./CreditNft.sol";

/// @title A basic credit issuing and redemption mechanism for Credit Nft holders
/// @notice Allows users to burn their Ubiquity Dollar in exchange for Credit Nft
/// redeemable in the future
/// @notice Allows users to redeem individual Credit Nft or batch redeem
/// Credit Nft on a first-come first-serve basis
contract CreditNftManager is ERC165, IERC1155Receiver {
    using SafeERC20 for IERC20Ubiquity;

    UbiquityDollarManager public immutable manager;

    //the amount of dollars we minted this cycle, so we can calculate delta.
    // should be reset to 0 when cycle ends
    uint256 public dollarsMintedThisCycle;
    bool public debtCycle;
    uint256 public blockHeightDebt;
    uint256 public creditNftLengthBlocks;
    uint256 public expiredCreditNftConversionRate = 2;

    event ExpiredCreditNftConversionRateChanged(
        uint256 newRate,
        uint256 previousRate
    );

    event CreditNftLengthChanged(
        uint256 newCreditNftLengthBlocks,
        uint256 previousCreditNftLengthBlocks
    );

    modifier onlyCreditNftManager() {
        require(
            manager.hasRole(manager.CREDIT_NFT_MANAGER_ROLE(), msg.sender),
            "Caller is not a Credit Nft manager"
        );
        _;
    }

    /// @param _manager the address of the manager contract so we can fetch variables
    /// @param _creditNftLengthBlocks how many blocks Credit Nft last. can't be changed
    /// once set (unless migrated)
    constructor(
        UbiquityDollarManager _manager,
        uint256 _creditNftLengthBlocks
    ) {
        manager = _manager;
        creditNftLengthBlocks = _creditNftLengthBlocks;
    }

    function setExpiredCreditNftConversionRate(
        uint256 rate
    ) external onlyCreditNftManager {
        emit ExpiredCreditNftConversionRateChanged(
            rate,
            expiredCreditNftConversionRate
        );
        expiredCreditNftConversionRate = rate;
    }

    function setCreditNftLength(
        uint256 _creditNftLengthBlocks
    ) external onlyCreditNftManager {
        emit CreditNftLengthChanged(
            _creditNftLengthBlocks,
            creditNftLengthBlocks
        );
        creditNftLengthBlocks = _creditNftLengthBlocks;
    }

    /// @dev called when a user wants to burn Ubiquity Dollar for Credit Nft.
    ///      should only be called when oracle is below a dollar
    /// @param amount the amount of dollars to exchange for Credit Nft
    function exchangeDollarsForCreditNft(
        uint256 amount
    ) external returns (uint256) {
        uint256 twapPrice = _getTwapPrice();

        require(
            twapPrice < 1 ether,
            "Price must be below 1 to mint Credit Nft"
        );

        CreditNft creditNft = CreditNft(manager.creditNftAddress());
        creditNft.updateTotalDebt();

        //we are in a down cycle so reset the cycle counter
        // and set the blockHeight Debt
        if (!debtCycle) {
            debtCycle = true;
            blockHeightDebt = block.number;
            dollarsMintedThisCycle = 0;
        }

        ICreditNftRedemptionCalculator creditNftCalculator = ICreditNftRedemptionCalculator(
                manager.creditNftCalculatorAddress()
            );
        uint256 creditNftToMint = creditNftCalculator.getCreditNftAmount(
            amount
        );

        // we burn user's dollars.
        UbiquityDollarToken(manager.dollarTokenAddress()).burnFrom(
            msg.sender,
            amount
        );

        uint256 expiryBlockNumber = block.number + (creditNftLengthBlocks);
        creditNft.mintCreditNft(msg.sender, creditNftToMint, expiryBlockNumber);

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

        CreditNft creditNft = CreditNft(manager.creditNftAddress());
        creditNft.updateTotalDebt();

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

    /// @dev uses the current Credit Nft for dollars calculation to get Credit Nft for dollars
    /// @param amount the amount of dollars to exchange for Credit Nft
    function getCreditNftReturnedForDollars(
        uint256 amount
    ) external view returns (uint256) {
        ICreditNftRedemptionCalculator creditNftCalculator = ICreditNftRedemptionCalculator(
                manager.creditNftCalculatorAddress()
            );
        return creditNftCalculator.getCreditNftAmount(amount);
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

    /// @dev should be called by this contract only when getting Credit Nft to be burnt
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

    /// @dev let Credit Nft holder burn expired Credit Nft for Governance Token. Doesn't make TWAP > 1 check.
    /// @param id the timestamp of the Credit Nft
    /// @param amount the amount of Credit Nft to redeem
    /// @return governanceAmount amount of Governance Token minted to Credit Nft holder
    function burnExpiredCreditNftForGovernance(
        uint256 id,
        uint256 amount
    ) public returns (uint256 governanceAmount) {
        // Check whether Credit Nft hasn't expired --> Burn Credit Nft.
        CreditNft creditNft = CreditNft(manager.creditNftAddress());

        require(id <= block.number, "Credit NFT has not expired");
        require(
            creditNft.balanceOf(msg.sender, id) >= amount,
            "User not enough Credit Nft"
        );

        creditNft.burnCreditNft(msg.sender, amount, id);

        // Mint Governance Token to this contract. Transfer Governance Token to msg.sender i.e. Credit Nft holder
        IERC20Ubiquity governanceToken = IERC20Ubiquity(
            manager.governanceTokenAddress()
        );
        governanceAmount = amount / expiredCreditNftConversionRate;
        governanceToken.mint(msg.sender, governanceAmount);
    }

    // TODO should we leave it ?
    /// @dev Lets Credit Nft holder burn Credit Nft for Credit. Doesn't make TWAP > 1 check.
    /// @param id the timestamp of the Credit Nft
    /// @param amount the amount of Credit Nft to redeem
    /// @return amount of Credit pool tokens (i.e. LP tokens) minted to Credit Nft holder
    function burnCreditNftForCredit(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        // Check whether Credit Nft hasn't expired --> Burn Credit Nft.
        CreditNft creditNft = CreditNft(manager.creditNftAddress());

        require(id > block.timestamp, "Credit NFT has expired");
        require(
            creditNft.balanceOf(msg.sender, id) >= amount,
            "User not enough Credit Nft"
        );

        creditNft.burnCreditNft(msg.sender, amount, id);

        // Mint LP tokens to this contract. Transfer LP tokens to msg.sender i.e. Credit Nft holder
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            manager.creditTokenAddress()
        );
        creditToken.mint(address(this), amount);
        require(
            creditToken.transfer(msg.sender, amount),
            "CreditNftManager: Credit Token Transfer Failed"
        );

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
        require(
            dollarToken.transfer(msg.sender, amount),
            "CreditNftManager: Credit Token Transfer Failed"
        );

        return amount - creditToRedeem;
    }

    /// @param id the block number of the Credit Nft
    /// @param amount the amount of Credit Nft to redeem
    /// @return amount of unredeemed Credit Nft
    function redeemCreditNft(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        uint256 twapPrice = _getTwapPrice();

        require(
            twapPrice > 1 ether,
            "Price must be above 1 to redeem Credit Nft"
        );
        if (debtCycle) {
            debtCycle = false;
        }
        CreditNft creditNft = CreditNft(manager.creditNftAddress());

        require(id > block.number, "Credit NFT has expired");
        require(
            creditNft.balanceOf(msg.sender, id) >= amount,
            "User not enough Credit Nft"
        );

        mintClaimableDollars();
        UbiquityDollarToken dollarToken = UbiquityDollarToken(
            manager.dollarTokenAddress()
        );
        UbiquityCreditToken creditToken = UbiquityCreditToken(
            manager.creditTokenAddress()
        );
        // Credit have a priority on Credit Nft holder
        require(
            creditToken.totalSupply() <= dollarToken.balanceOf(address(this)),
            "There aren't enough Dollar to redeem currently"
        );
        uint256 maxRedeemableCreditNft = dollarToken.balanceOf(address(this)) -
            creditToken.totalSupply();
        uint256 creditNftToRedeem = amount;

        if (amount > maxRedeemableCreditNft) {
            creditNftToRedeem = maxRedeemableCreditNft;
        }
        require(
            dollarToken.balanceOf(address(this)) > 0,
            "There aren't any Dollar to redeem currently"
        );

        // creditNftManager must be an operator to transfer on behalf of msg.sender
        creditNft.burnCreditNft(msg.sender, creditNftToRedeem, id);
        require(
            creditToken.transfer(msg.sender, amount),
            "CreditNftManager: Credit Token Transfer Failed"
        );

        return amount - (creditNftToRedeem);
    }

    function mintClaimableDollars() public {
        CreditNft creditNft = CreditNft(manager.creditNftAddress());
        creditNft.updateTotalDebt();

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
        uint256 totalOutstandingDebt = creditNft.getTotalOutstandingDebt() +
            creditToken.totalSupply();

        if (currentRedeemableBalance > totalOutstandingDebt) {
            uint256 excessDollars = currentRedeemableBalance -
                (totalOutstandingDebt);

            IDollarMintExcess dollarsDistributor = IDollarMintExcess(
                manager.getExcessDollarsDistributor(address(this))
            );
            // transfer excess dollars to the distributor and tell it to distribute
            require(
                dollarToken.transfer(
                    manager.getExcessDollarsDistributor(address(this)),
                    excessDollars
                ),
                "Dollar: Transfer failed"
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
