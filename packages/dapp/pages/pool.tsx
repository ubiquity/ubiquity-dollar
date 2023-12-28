import { BigNumber, ethers } from "ethers";
import dynamic from "next/dynamic";
import { FC, useEffect, useState } from "react";
import { useBalance } from "wagmi";

import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import useWeb3 from "@/components/lib/hooks/use-web-3";
import usePrices from "@/components/redeem/lib/use-prices";
import Button from "@/components/ui/button";
import PositiveNumberInput from "@/components/ui/positive-number-input";

const WalletConnectionWall = dynamic(() => import("@/components/ui/wallet-connection-wall"), { ssr: false }); //@note Fix: (Hydration Error)

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
  const { walletAddress } = useWeb3(); 
  const collateralBalanceUser = useBalance({
    address: walletAddress as `0x${string}`,
    token: collateralInfo?.collateralAddress as `0x${string}`,
  });
  const dollarBalanceUser = useBalance({
    address: walletAddress as `0x${string}`,
    token: protocolContracts.dollarToken?.address as `0x${string}`,
  });
  const [receiveAmountDollar, setReceiveAmountDollar] = useState<BigNumber>(BigNumber.from(0));
  const [receiveAmountCollateral, setReceiveAmountCollateral] = useState<BigNumber>(BigNumber.from(0));

  useEffect(() => {
    const fetchData = async () => {
      const allCollateralAddresses = await protocolContracts.ubiquityPoolFacet?.allCollaterals();
      const collateralInfo: CollateralInfo = await protocolContracts.ubiquityPoolFacet?.collateralInformation(allCollateralAddresses[0]);

      setCollateralInfo(collateralInfo);
    };
    
    fetchData().catch(err => { console.error(err) });
  }, []);

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
            <PositiveNumberInput placeholder={`${collateralInfo?.symbol} amount`} value="" onChange={() => {}} />
          </div>
          <div className="pool-container__row">
            <span>You receive</span>
            <span>{receiveAmountDollar.toString()} Dollars</span>
          </div>
          <div>
            <Button disabled={true}>Mint</Button>
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
