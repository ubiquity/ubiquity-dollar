import Button from "./Button";
import PositiveNumberInput from "./PositiveNumberInput";
import { BigNumber, ethers } from "ethers";
import { useEffect, useState } from "react";

const TokenAmountInput = ({
  value,
  onChange,
  label,
  max,
  decimals,
  icon,
  placeholder,
  disabled,
  fraction = true,
}: {
  value: string;
  decimals: number;
  label: string;
  max: BigNumber;
  icon: () => JSX.Element;
  onParse?: (val: string) => string | null;
  onChange: (val: string) => void;
  placeholder?: string;
  className?: string;
  disabled?: boolean;
  fraction?: boolean;
}) => {
  const Icon = icon;

  const [inputValue, setInputValue] = useState(value);
  useEffect(() => {
    (async function () {
      if (value) {
        setInputValue(value);
      }
    })();
  }, [value]);
  const maxInt = parseInt(ethers.utils.formatUnits(max, decimals));
  const handleMaxClick = () => {
    setInputValue(maxInt.toString());
    onChange(maxInt.toString());
  };
  const onChangePatternWrap = (inputVal: string) => {
    setInputValue(inputVal);
    onChange(inputVal);
  };
  return (
    <div className="tokenAmountInput">
      <div style={{ paddingRight: 5, marginBottom: -4 }}>
        <Button style={{ padding: 3 }} disabled={disabled} onClick={handleMaxClick}>
          Max:{` ${maxInt}`}
        </Button>
      </div>

      <div style={{ border: "solid gray", borderWidth: "1px", borderRadius: "5px", padding: "8px 5px 5px", margin: 3 }}>
        <div
          style={{
            position: "absolute",
            marginTop: "-18px",
            marginLeft: "5px",
            fontSize: "70%",
            color: "white",
            background: "black",
            borderRadius: "5px",
            padding: "2px 2px",
          }}
        >
          {label}
        </div>
        <div style={{ display: "flex", flexDirection: "row", justifyContent: "flex-start", alignItems: "center" }}>
          <div className="tokenInputImage">{<Icon />}</div>
          <div style={{ marginLeft: 3 }}>
            <PositiveNumberInput value={inputValue} fraction={fraction} onChange={onChangePatternWrap} placeholder={placeholder} disabled={disabled} />
          </div>
        </div>
      </div>
    </div>
  );
};

export default TokenAmountInput;
