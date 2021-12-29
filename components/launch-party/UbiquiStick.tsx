import cx from "classnames";
import SectionTitle from "./lib/SectionTitle";

const UbiquiStick = () => {
  return (
    <div className="party-container flex flex-col items-center">
      <SectionTitle title="The Ubiquistick NFT" subtitle="Access the game bonding pools" />
      <div className="grid grid-cols-2 gap-8 mb-4">
        <Stick amount={4} imgSrc="ubiquistick.png" name="Standard" />
        <Stick amount={0} imgSrc="ubiquistick.png" name="Gold" />
      </div>
      <button className="btn-primary mb-8">Mint for 0.5 ETH</button>
      <a href="https://opensea.io/">See your Ubiquisticks on OpenSeas</a>
    </div>
  );
};

export default UbiquiStick;

const Stick = ({ amount, imgSrc, name }: { amount: number; imgSrc: string; name: string }) => {
  return (
    <div className="">
      <div className={cx("mb-2 rounded-lg shadow-inner border-2 border-solid border-black border-opacity-25", { ["ring-accent ring-1"]: amount !== 0 })}>
        <img className={cx("block rounded-lg w-full h-auto", { ["grayscale opacity-25"]: amount === 0 })} src={imgSrc} />
      </div>
      <div className={cx("flex mx-2", { ["text-opacity-25 text-white"]: amount === 0, ["text-opacity-75 text-accent drop-shadow-light"]: amount !== 0 })}>
        <div className="text-3xl flex-grow text-left">{name}</div>
        <div className="text-3xl">x{amount}</div>
      </div>
    </div>
  );
};
