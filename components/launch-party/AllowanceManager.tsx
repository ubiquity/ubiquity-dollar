import { useState } from "react";
import SectionTitle from "./lib/SectionTitle";

type AllowanceManagerParams = {
  defaultAddress: string;
  onSubmit: ({ address, count, price }: { address: string; count: string; price: string }) => any;
};

const AllowanceManager = ({ defaultAddress, onSubmit }: AllowanceManagerParams) => {
  const [address, setAddress] = useState<string>(defaultAddress || "");
  const [count, setCount] = useState<string>("");
  const [price, setPrice] = useState<string>("");

  return (
    <div className="party-container">
      <SectionTitle title="Allowance management" subtitle="" />
      <input placeholder="Address" value={address} onChange={(ev) => setAddress(ev.target.value)} />
      <input placeholder="Count" type="number" value={count} onChange={(ev) => setCount(ev.target.value)} />
      <input placeholder="Price" type="number" value={price} onChange={(ev) => setPrice(ev.target.value)} />
      <button disabled={!address || count === "" || price === ""} onClick={() => onSubmit({ address, count, price })}>
        Apply
      </button>
    </div>
  );
};

export default AllowanceManager;
