const Liquidate = () => {
  return (
    <div className="party-container">
      <h2 className="m-0 mb-2 tracking-widest uppercase text-xl">Liquidate</h2>
      <p className="m-0 mb-8 font-light tracking-wide">Exit the game; sell uAR for ETH</p>
      <div className="text-lg mb-2">You have</div>
      <div className="text-4xl mb-10 text-accent drop-shadow-light">3,500 uAR</div>
      <a className="btn-primary text-lg" target="_blank" href="https://app.uniswap.org/">
        Exchange for ETH
      </a>
    </div>
  );
};

export default Liquidate;
