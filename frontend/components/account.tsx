import React from "react";
import { useConnectedContext } from "./context/connected";

const Account = () => {
  const { account } = useConnectedContext();

  if (!account) {
    return null;
  }

  return (
    <>
      <div id="account">
        <p>{account?.address}</p>
      </div>
    </>
  );
};

export default Account;
