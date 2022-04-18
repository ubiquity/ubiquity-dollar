import { useState } from "react";
import * as widget from "../ui/widget";

type AllowanceData = {
  address: string;
  count: string;
  price: string;
};

type AllowanceManagerParams = {
  defaultAddress: string;
  onSubmit: (data: AllowanceData[]) => unknown;
};

const AllowanceManager = ({ defaultAddress, onSubmit }: AllowanceManagerParams) => {
  // const [address, setAddress] = useState<string>(defaultAddress || "");
  // const [count, setCount] = useState<string>("");
  // const [price, setPrice] = useState<string>("");
  const [allowances, setAllowances] = useState<AllowanceData[]>([{ address: defaultAddress || "", count: "", price: "" }]);

  const setAllowanceAt = (allowance: AllowanceData, index: number) => {
    const newAllowances = allowances.concat([]);
    newAllowances.splice(index, 1, allowance);
    setAllowances(newAllowances);
  };

  const disableApply = allowances.some(({ address, count, price }) => !address || count === "" || price === "");

  return (
    <widget.Container>
      <widget.Title text="Allowance management" />

      <div>
        {allowances.map((allowance, i) => (
          <AllowanceInputs key={i} data={allowance} setData={(data) => setAllowanceAt(data, i)} />
        ))}
      </div>

      <div>
        <button className="btn-primary" onClick={() => setAllowances(allowances.concat([{ address: "", count: "", price: "" }]))}>
          Add
        </button>
        {allowances.length > 1 ? (
          <button className="btn-primary" onClick={() => setAllowances(allowances.slice(0, -1))}>
            Remove
          </button>
        ) : null}
      </div>
      <div>
        <button disabled={disableApply} onClick={() => onSubmit(allowances)}>
          Apply
        </button>
      </div>
    </widget.Container>
  );
};

const AllowanceInputs = ({ data: { address, count, price }, setData }: { data: AllowanceData; setData: (data: AllowanceData) => void }) => {
  return (
    <div>
      <input placeholder="Address" value={address} onChange={(ev) => setData({ address: ev.target.value, count, price })} />
      <input placeholder="Count" type="number" value={count} onChange={(ev) => setData({ address, count: ev.target.value, price })} />
      <input placeholder="Price" type="number" value={price} onChange={(ev) => setData({ address, count, price: ev.target.value })} />
    </div>
  );
};

export default AllowanceManager;
