import { BigNumber, ethers } from "ethers";
import dynamic from "next/dynamic";
import { FC, useEffect, useState } from "react";
import { useBalance } from "wagmi";

import { getERC20Allowance, getERC20Contract } from "@/components/lib/contracts-shortcuts";
import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import useWeb3 from "@/components/lib/hooks/use-web-3";
import usePrices from "@/components/redeem/lib/use-prices";
import Button from "@/components/ui/button";
import PositiveNumberInput from "@/components/ui/positive-number-input";

const WalletConnectionWall = dynamic(() => import("@/components/ui/wallet-connection-wall"), { ssr: false }); //@note Fix: (Hydration Error)

const SLIPPAGE_RATE = 50_000; // 5%, 1_000_000 = 100%
const UBIQUITY_POOL_PRICE_PRECISION = 1_000_000;

type CollateralInfo = {
  collateralAddress: string;
  collateralPriceFeedAddress: string;
  collateralPriceFeedStalenessThreshold: BigNumber;
  index: BigNumber;
  isBorrowPaused: boolean;
  isEnabled: boolean;
  isMintPaused: boolean;
  isRedeemPaused: boolean;
  mintingFee: BigNumber;
  missingDecimals: BigNumber;
  poolCeiling: BigNumber;
  price: BigNumber;
  redemptionFee: BigNumber;
  symbol: string;
};

/**
 * UbiquityPool page
 *
 * Allows users to:
 * 1. Send collateral tokens to the pool in exchange for Dollar tokens (mint)
 * 2. Send Dollar tokens to the pool in exchange for collateral (redeem)
 */
const PoolPage: FC = (): JSX.Element => {
  const protocolContracts = useProtocolContracts();
  const [dollarPrice] = usePrices();
  const [collateralInfo, setCollateralInfo] = useState<CollateralInfo | null>(null);
  const collateralBalancePool = useBalance({
    address: protocolContracts.ubiquityPoolFacet?.address as `0x${string}`,
    token: collateralInfo?.collateralAddress as `0x${string}`,
  });
  const { provider, signer, walletAddress } = useWeb3(); 
  const collateralBalanceUser = useBalance({
    address: walletAddress as `0x${string}`,
    token: collateralInfo?.collateralAddress as `0x${string}`,
  });
  const dollarBalanceUser = useBalance({
    address: walletAddress as `0x${string}`,
    token: protocolContracts.dollarToken?.address as `0x${string}`,
  });
  const [allowanceAmountCollateral, setAllowanceAmountCollateral] = useState<BigNumber>(BigNumber.from(0));
  const [allowanceAmountDollar, setAllowanceAmountDollar] = useState<BigNumber>(BigNumber.from(0));
  const [receiveAmountCollateral, setReceiveAmountCollateral] = useState<BigNumber>(BigNumber.from(0));
  const [receiveAmountDollar, setReceiveAmountDollar] = useState<BigNumber>(BigNumber.from(0));
  const [inputAmountCollateral, setInputAmountCollateral] = useState<string>('');

  /**
   * On component mount
   */
  useEffect(() => {
    init().catch(err => { console.error(err) });
  }, []);

  /**
   * Initializes component
   */
  const init = async () => {
    const allCollateralAddresses = await protocolContracts.ubiquityPoolFacet?.allCollaterals();
    const collateralInfo: CollateralInfo = await protocolContracts.ubiquityPoolFacet?.collateralInformation(allCollateralAddresses[0]);
    const allowanceCollateral = await getERC20Allowance(provider, collateralInfo.collateralAddress, walletAddress || '', protocolContracts.ubiquityPoolFacet?.address || '');

    setCollateralInfo(collateralInfo);
    setAllowanceAmountCollateral(allowanceCollateral);
  };

  /**
   * On "mint" input change
   * @param value New input value
   */
  const onInputAmountCollateralChange = async (value: string) => {
    setInputAmountCollateral(value);
      const dollarsRequired = ethers.utils.parseEther(value || '0').mul(UBIQUITY_POOL_PRICE_PRECISION).div(collateralInfo?.price || 1);
      setReceiveAmountDollar(dollarsRequired);
  };

  /**
   * On "approve" button transfer of collateral tokens click
   */
  const onApproveCollateralClick = async () => {
    // get collateral contract instance
    const collateralContract = await getERC20Contract(collateralInfo?.collateralAddress || '', provider);
    // get amount in WEI that should be approved
    const amountToApproveWei = ethers.utils.parseEther(inputAmountCollateral);
    // approve
    await collateralContract.connect(signer || '').approve(
      protocolContracts.ubiquityPoolFacet?.address, 
      amountToApproveWei,
    );
    // update UI
    setAllowanceAmountCollateral(amountToApproveWei);
  };

  /**
   * On "mint" button click
   */
  const onMintClick = async () => {
    // be default we have only 1 collateral pool hence index is 0
    const collateralIndex = 0; 
    // amount of Dollars to mint
    const dollarAmount = receiveAmountDollar.toString();
    // min amount of Dollars to mint (slippage protection)
    const dollarOutMin = BigNumber.from(dollarAmount).mul(BigNumber.from(1_000_000).sub(SLIPPAGE_RATE)).div(1_000_000).toString();
    // max amount of input collateral (slippage protection)
    const maxCollateralIn = BigNumber.from(dollarAmount).mul(BigNumber.from(1_000_000).add(SLIPPAGE_RATE)).div(1_000_000).toString();

    // mint Dollars
    await protocolContracts.ubiquityPoolFacet?.connect(signer || '').mintDollar(
      collateralIndex,
      dollarAmount,
      dollarOutMin,
      maxCollateralIn,
    );

    // update UI
    init();
    setInputAmountCollateral('');
    setReceiveAmountDollar(BigNumber.from(0));
  };

  /**
   * Returns JSX template
   */
  return (
    <WalletConnectionWall>
      <div id="Pool" className="pool-container">
        {/* pool info block */}
        <div className="panel">
          <h2>Pool info</h2>
          <div className="pool-container__row">
            <span>Dollar price</span>
            <span>${(+ethers.utils.formatEther(dollarPrice || 0)).toFixed(2)}</span>
          </div>
          <div className="pool-container__row">
            <span>Pool balance ({collateralInfo?.symbol})</span>
            <span>{(+ethers.utils.formatEther(collateralBalancePool.data?.value || 0)).toFixed(2)}</span>
          </div>
          <div className="pool-container__row">
            <span>Pool ceiling ({collateralInfo?.symbol})</span>
            <span>{(+ethers.utils.formatEther(collateralInfo?.poolCeiling || 0)).toFixed(2)}</span>
          </div>
          <div className="pool-container__row">
            <span>User balance ({collateralInfo?.symbol})</span>
            <span>{(+ethers.utils.formatEther(collateralBalanceUser.data?.value || 0)).toFixed(2)}</span>
          </div>
          <div className="pool-container__row">
            <span>User balance (Dollar)</span>
            <span>{(+ethers.utils.formatEther(dollarBalanceUser.data?.value || 0)).toFixed(2)}</span>
          </div>
          <div className="pool-container__row">
            <span>Mint fee</span>
            <span>{((+(collateralInfo?.mintingFee.toString() || 0) / 1e6) * 100).toFixed(2)}%</span>
          </div>
          <div className="pool-container__row">
            <span>Redemption fee</span>
            <span>{((+(collateralInfo?.redemptionFee.toString() || 0) / 1e6) * 100).toFixed(2)}%</span>
          </div>
        </div>
        {/* mint block */}
        <div className="panel">
          <h2>Mint</h2>
          <div>
            <PositiveNumberInput 
              placeholder={`${collateralInfo?.symbol} amount`} 
              value={inputAmountCollateral}
              onChange={onInputAmountCollateralChange} 
            />
          </div>
          <div className="pool-container__row">
            <span>You receive</span>
            <span>{(+ethers.utils.formatEther(receiveAmountDollar)).toFixed(2)} Dollars</span>
          </div>
          {/* mint Dollars / approve collateral button */}
          <div>
            {allowanceAmountCollateral.gte(ethers.utils.parseEther(inputAmountCollateral || '0')) ? (
              <Button onClick={onMintClick}>Mint</Button>
            ) : (
              <Button 
                disabled={BigNumber.from(inputAmountCollateral || 0).eq(0)}
                onClick={onApproveCollateralClick}
              >
                Approve
              </Button>
            )}
          </div>
        </div>
        {/* redeem block */}
        <div className="panel">
          <h2>Redeem</h2>
          <div>
            <PositiveNumberInput placeholder={`Dollar amount`} value="" onChange={() => {}} />
          </div>
          <div className="pool-container__row">
            <span>You receive</span>
            <span>{receiveAmountCollateral.toString()} {collateralInfo?.symbol}</span>
          </div>
          <div>
            <Button>Redeem</Button>
          </div>
        </div>
      </div>
    </WalletConnectionWall>
  );
};

export default PoolPage;
