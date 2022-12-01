// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./UbiquityAlgorithmicDollarManager.sol";

import "forge-std/console.sol";

contract SellPressureDampeningIncentive {
    using SafeERC20 for IERC20;
    using SafeERC20 for IMetaPool;
    UbiquityAlgorithmicDollarManager public manager;

    // under this price we will fight the sell pressure
    uint256 private minTriggerPrice;
    // coefficient applied to the lost 3crv to get the amount to provide to the pool in order to increase the peg
    uint256 private coef;
    modifier onlyAdmin() {
        require(
            manager.hasRole(manager.INCENTIVE_MANAGER_ROLE(), msg.sender),
            "SellPressDamp: not admin"
        );
        _;
    }

    /// @param _manager the address of the manager/config contract so we can fetch variables
    constructor(address _manager) {
        manager = UbiquityAlgorithmicDollarManager(_manager);
        minTriggerPrice = 0.89 ether;
        coef = 0.5 ether;
        console.log("## incentivize  constructor _manager:%s ", _manager);
    }

    event Incentivized(
        address indexed sender,
        address indexed recipient,
        address operator,
        uint256 amount
    );

    /**
     * @dev transfer the token from the address of this contract
     * to address of the owner
     */
    function withdrawToken(address _tokenContract, uint256 _amount)
        external
        onlyAdmin
    {
        IERC20 tokenContract = IERC20(_tokenContract);

        // needs to execute `approve()` on the token contract to allow itself the transfer
        //tokenContract.approve(address(this), _amount);
        tokenContract.safeTransfer(manager.treasuryAddress(), _amount);
    }

    function incentivize(
        address sender,
        address recipient,
        address operator,
        uint256 amount
    ) public {
        console.log(
            "## incentivize  sender:%s  recipient:%s ",
            sender,
            recipient
        );
        console.log(
            "## incentivize   operator:%s  amount:%s",
            operator,
            amount
        );
        // check that recipient is the metapool
        address poolAddr = manager.stableSwapMetaPoolAddress();
        if (recipient == poolAddr && sender != address(this)) {
            if (operator == poolAddr) {
                // probably not necessary
                // check that amount > x NTH check that the price of uAD after the sell will be <0.96
                // Calculate the price for exchanging a token with index i to token with index j and amount dx given the _balances provided.
                TWAPOracle twap = TWAPOracle(manager.twapOracleAddress());
                IMetaPool pool = IMetaPool(poolAddr);
                uint256[2] memory priceCumulative = pool
                    .get_price_cumulative_last();
                uint256 blockTimestamp = pool.block_timestamp_last();
                uint256[2] memory priceCumulativeLast = [
                    twap.priceCumulativeLast(0),
                    twap.priceCumulativeLast(1)
                ];
                uint256[2] memory twapBalances = pool.get_twap_balances(
                    priceCumulativeLast,
                    priceCumulative,
                    blockTimestamp - twap.pricesBlockTimestampLast()
                );
                console.log(
                    "## cur price :%s",
                    pool.get_dy(0, 1, 1 ether, twapBalances)
                );
                // remove calculated amount of 3CRV and add amount of uAD from first balance
                uint256 removed3crvAmountFromPool = pool.get_dy(0, 1, amount);
                twapBalances[0] += amount;
                twapBalances[1] -= removed3crvAmountFromPool;
                // simulate the swap from uAD to 3CRV
                uint256 newPrice = pool.get_dy(0, 1, 1 ether, twapBalances);
                console.log("## new price :%s", newPrice);
                if (newPrice <= minTriggerPrice)
                    _provideSingleSided3CRVLiquidity(
                        removed3crvAmountFromPool,
                        pool
                    );

                emit Incentivized(sender, recipient, operator, amount);
            }
        }
    }

    function _provideSingleSided3CRVLiquidity(
        uint256 removed3crvAmountFromPool,
        IMetaPool pool
    ) internal {
        console.log(
            "## _provideSingleSided3CRVLiquidity !!! coin0:%s coin1:%s  ",
            pool.coins(0),
            pool.coins(1)
        );
        // only provide a portion
        uint256 liquidityToProvide = (removed3crvAmountFromPool * coef) / 1e18;
        address curve3PoolTokenAddress = manager.curve3PoolTokenAddress();
        IERC20 curveToken = IERC20(curve3PoolTokenAddress);

        uint256 curBalance = curveToken.balanceOf(address(this));
        console.log(
            "## _provideSingleSided3CRVLiquidity curBalance:%s ",
            curBalance
        );
        if (curBalance > 0) {
            // if we don't have enough use all the funds
            if (curBalance < liquidityToProvide)
                liquidityToProvide = curBalance;
            uint256[2] memory amounts = [0, liquidityToProvide];
            uint256 minLpReturned = pool.calc_token_amount(amounts, true);
            console.log(
                "## minLpReturned :%s liquidityToProvide:%s",
                minLpReturned,
                liquidityToProvide
            );
            curveToken.safeIncreaseAllowance(
                address(pool),
                1000000000000000 ether
            ); // liquidityToProvide);
            // ***//
            address uadTokenAddress = manager.dollarTokenAddress();
            console.log(
                "## curve3PoolTokenAddress:%s uadTokenAddress:%s pool:%s ",
                curve3PoolTokenAddress,
                uadTokenAddress,
                address(pool)
            );
            IERC20 uad = IERC20(uadTokenAddress);
            uad.safeIncreaseAllowance(address(pool), 1000000000000000 ether);
            console.log(
                "## uad allowance :%s balance:%s",
                uad.allowance(address(this), address(pool)),
                uad.balanceOf(address(this))
            );
            /*** */
            console.log(
                "## curveToken allowance :%s balance:%s",
                curveToken.allowance(address(this), address(pool)),
                curveToken.balanceOf(address(this))
            );
            //excahnge
            // swap  amount of 3CRV => uAD
            uint256 amount3CRVReceivedEstimqt = pool.get_dy(1, 0, 1 ether);
            console.log(
                "##  amount3CRVReceivedEstimqt:%s",
                amount3CRVReceivedEstimqt
            );
            uint256 amount3CRVReceived = pool.exchange(1, 0, 1, 0);
            console.log(
                "## exchange ok amount3CRVReceived:%s",
                amount3CRVReceived
            );
            //

            // provide one coin liquidity
            amounts[0] = 0;
            amounts[1] = 10000000;
            uint256 lpReturned = pool.add_liquidity(
                amounts,
                0, //minLpReturned,
                address(this)
            );
            console.log("## lpReturned :%s", minLpReturned);
        }
    }

    // TODO add a remove liquidity that the admin can trigger if peg > 1$
}
