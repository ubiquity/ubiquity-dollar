import React from "react";
import { useConnectedContext } from "./context/connected";

const Account = () => {
  const { account } = useConnectedContext();

  if (!account) {
    return null;
  }

  return (
    <>
      <div>
        <p>Account: {account?.address}</p>
        <p>
          <a href="https://crv.to">Swap uAD to DAI/USDC/USDT.</a>
          <br />
          Select pool Ubiquity Algorithmic Dollar (uAD3CRV-f-2)
        </p>
      </div>
    </>
  );
};

export default Account;
