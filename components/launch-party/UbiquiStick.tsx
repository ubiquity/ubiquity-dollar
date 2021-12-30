import { useEffect, useState } from "react";
import { useUserContractsContext } from "../context/connected";
import cx from "classnames";
import SectionTitle from "./lib/SectionTitle";
import { TheUbiquityStick__factory } from "./lib/types";

const TheUbiquiStickAddress = "0xaab265cceb890c0e6e09aa6f5ee63b33de649374";
const SaleContractAddress = "0xaab265cceb890c0e6e09aa6f5ee63b33de649374";

const mockAccount = typeof document !== "undefined" && document.location.search === "?test" ? "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd" : null;

type Sticks = {
  standard: number;
  gold: number;
};

const UbiquiStick = () => {
  const [sticks, setSticks] = useState<Sticks | null>(null);

  const userContext = useUserContractsContext();

  useEffect(() => {
    if (userContext) {
      (async () => {
        const { provider, account } = userContext;
        const accountAddress = mockAccount || account.address;
        const NftContract = TheUbiquityStick__factory.connect(TheUbiquiStickAddress, provider);
        const sticksAmount = (await NftContract.balanceOf(accountAddress)).toNumber();
        const sticksData: Sticks = { standard: 0, gold: 0 };
        await Promise.all(
          new Array(sticksAmount).fill(0).map(async (_, i) => {
            const id = (await NftContract.tokenOfOwnerByIndex(accountAddress, i)).toNumber();
            const isGold = await NftContract.gold(id);
            if (isGold) {
              sticksData.gold += 1;
            } else {
              sticksData.standard += 1;
            }
          })
        );
        setSticks(sticksData);
      })();
    }
  }, [userContext]);

  return (
    <div className="party-container flex flex-col items-center">
      <SectionTitle title="The Ubiquistick NFT" subtitle="Access the game bonding pools" />
      <div className="grid grid-cols-2 gap-8 mb-4">
        <Stick loading={!sticks} amount={sticks?.standard || 0} imgSrc="ubiquistick.jpeg" name="Standard" />
        <Stick loading={!sticks} amount={sticks?.gold || 0} imgSrc="ubiquistick.jpeg" name="Gold" />
      </div>
      <button className="btn-primary mb-8">Mint for 0.5 ETH</button>
      <a href="https://opensea.io/">See your Ubiquisticks on OpenSeas</a>
    </div>
  );
};

export default UbiquiStick;

const Stick = ({ amount, imgSrc, name, loading }: { amount: number; imgSrc: string; name: string; loading: boolean }) => {
  return (
    <div className="">
      <div
        className={cx("relative mb-2 rounded-lg shadow-inner border-2 border-solid border-black border-opacity-25", { ["ring-accent ring-1"]: amount !== 0 })}
      >
        {loading ? (
          <div className="absolute w-full h-full flex items-center justify-center pointer-events-none">
            <div className="loader"></div>
          </div>
        ) : null}
        <img className={cx("block rounded-lg w-full h-auto", { ["grayscale opacity-25 blur"]: amount === 0 })} src={imgSrc} />
      </div>
      <div className={cx("flex mx-2", { ["text-opacity-25 text-white"]: amount === 0, ["text-opacity-75 text-accent drop-shadow-light"]: amount !== 0 })}>
        <div className="text-3xl flex-grow text-left">{name}</div>
        <div className="text-3xl">x{loading ? "?" : amount}</div>
      </div>
    </div>
  );
};
