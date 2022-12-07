import React from "react";
import SelectUnstyled from "react-select";

/* // drop down options e.g
 const Tokens: { label: string; value: number; image: () => JSX.Element }[] = [
   {
     label: "uAD",
     value: 355,
     image: icons.SVGs.uad,
  } 
] */

export const DropDown = ({
  text = "select · · ·",
  dropdownOptions,
}: {
  text: string;
  dropdownOptions: { label: string; value: number; image: () => JSX.Element }[];
}): JSX.Element => {
  return (
    <SelectUnstyled
      defaultInputValue={text}
      className="react-select-container"
      classNamePrefix="react-select"
      formatOptionLabel={(option: { label: string; value: number; image: () => JSX.Element }) => (
        <div style={{ display: "flex", flexDirection: "row", justifyContent: "flex-end", alignItems: "center" }}>
          <div>{option.image ? <option.image /> : ""} </div>
          <div>
            <span style={{ margin: 3 }}>{option.label}</span>
          </div>
        </div>
      )}
      options={dropdownOptions}
      styles={{
        control: (baseStyles) => ({
          ...baseStyles,
          backgroundColor: "#ffffff10",
          border: 3,
          borderRadius: "var(--button-rounding)",
          minHeight: 32,
          marginBottom: 3,
        }),
        singleValue: (baseStyles) => ({
          ...baseStyles,
          color: "white",
          display: "flex",
        }),
        container: (baseStyles) => ({
          ...baseStyles,
          //backgroundColor: state.isFocused ? "#79797d" : "inherit",
          display: "flex",
          width: "fit-content",
          margin: 3,
        }),
        option: (baseStyles, state) => ({
          ...baseStyles,
          backgroundColor: state.isFocused ? "#79797d" : "inherit",
          display: "flex",
        }),
        menu: (baseStyles) => ({
          ...baseStyles,
          backgroundColor: "#121218",

          width: "auto",
        }),
      }}
    />
  );
};

export default DropDown;
