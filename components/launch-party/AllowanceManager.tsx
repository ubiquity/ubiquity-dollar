import { Button, PositiveNumberInput, TextInput } from "@/ui";
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
      <widget.Title text="Whitelist management" />

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
        <Button styled="accent" disabled={disableApply} onClick={() => onSubmit(allowances)}>
          Apply
        </Button>
      </div>
    </widget.Container>
  );
};

const AllowanceInputs = ({ data: { address, count, price }, setData }: { data: AllowanceData; setData: (data: AllowanceData) => void }) => {
  return (
    <div>
      <TextInput placeholder="Address" value={address} onChange={(val) => setData({ address: val, count, price })} />
      <PositiveNumberInput placeholder="Ubiquisticks" fraction={false} value={count} onChange={(val) => setData({ address, count: val, price })} />
      <PositiveNumberInput placeholder="Price" value={price} onChange={(val) => setData({ address, count, price: val })} />
    </div>
  );
};

export default AllowanceManager;
