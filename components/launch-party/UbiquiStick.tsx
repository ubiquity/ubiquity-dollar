import cx from "classnames";

const UbiquiStick = () => {
  return (
    <div className="party-container flex flex-col items-center">
      <h2 className="m-0 mb-2 tracking-widest uppercase text-xl">The Ubiquistick NFT</h2>
      <p className="m-0 mb-4 font-light tracking-wide">Access the game bonding pools</p>
      <div className="grid grid-cols-2 gap-8 mb-4">
        <Stick amount={4} imgSrc="ubiquistick.png" name="Standard" />
        <Stick amount={0} imgSrc="ubiquistick.png" name="Gold" />
      </div>
      <button className="btn-primary text-lg mb-8">Mint for 0.5 ETH</button>
      <a href="https://opensea.io/">See your Ubiquisticks on OpenSeas</a>
    </div>
  );
};

export default UbiquiStick;

const Stick = ({ amount, imgSrc, name }: { amount: number; imgSrc: string; name: string }) => {
  return (
    <div className="">
      <div className="mb-2 rounded-lg shadow-inner border-2 border-solid border-black border-opacity-25">
        <img className={cx("block rounded-lg w-full h-auto", { ["grayscale opacity-25"]: amount === 0 })} src={imgSrc} />
      </div>
      <div className={cx("flex text-white mx-2", { ["text-opacity-25"]: amount === 0, ["text-opacity-75"]: amount !== 0 })}>
        <div className="text-3xl flex-grow text-left">{name}</div>
        <div className="text-3xl">x{amount}</div>
      </div>
    </div>
  );
};
