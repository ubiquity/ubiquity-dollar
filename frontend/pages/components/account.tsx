import React from "react";
import { useConnectedContext } from "../context/connected";

const Account = () => {
  const { account } = useConnectedContext();

  if (!account) {
    return null;
  }

  return (
    <>
      <p>Account: {account?.address}</p>
    </>
  );
};

export default Account;
