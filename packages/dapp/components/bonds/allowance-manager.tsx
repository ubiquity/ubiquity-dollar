import { useState } from "react";
import Button from "../ui/button";
import PositiveNumberInput, { TextInput } from "../ui/positive-number-input";

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
    <div>
      <h2>Whitelist management</h2>

      <div>
        {allowances.map((allowance, i) => (
          <AllowanceInputs key={i} data={allowance} setData={(data) => setAllowanceAt(data, i)} />
        ))}
      </div>

      <div>
        <Button onClick={() => setAllowances(allowances.concat([{ address: "", count: "", price: "" }]))}>Add</Button>
        {allowances.length > 1 ? <Button onClick={() => setAllowances(allowances.slice(0, -1))}>Remove</Button> : null}
      </div>
      <div>
        <Button disabled={disableApply} onClick={() => onSubmit(allowances)}>
          Apply
        </Button>
      </div>
    </div>
  );
};

const AllowanceInputs = ({ data: { address, count, price }, setData }: { data: AllowanceData; setData: (data: AllowanceData) => void }) => {
  return (
    <div>
      <TextInput placeholder="Address" value={address} onChange={(val: string) => setData({ address: val, count, price })} />
      <PositiveNumberInput placeholder="UbiquiSticks" fraction={false} value={count} onChange={(val: string) => setData({ address, count: val, price })} />
      <PositiveNumberInput placeholder="Price" value={price} onChange={(val: string) => setData({ address, count, price: val })} />
    </div>
  );
};

export default AllowanceManager;
