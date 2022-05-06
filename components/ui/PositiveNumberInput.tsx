import cx from "classnames";

const PositiveNumberInput = ({
  value,
  onChange,
  pattern = /^[0-9]*\.?[0-9]*$/,
  placeholder,
  className,
}: {
  value: string;
  pattern?: RegExp;
  onChange: (val: string) => void;
  placeholder?: string;
  className?: string;
}) => {
  const onChangePatternWrap = (handler: (val: string) => void) => (ev: React.ChangeEvent<HTMLInputElement>) => {
    const val = ev.currentTarget.value;
    if (pattern.test(val)) {
      handler(val);
    }
  };
  return <input type="tel" value={value} className={cx("m-0 block h-10", className)} onChange={onChangePatternWrap(onChange)} placeholder={placeholder} />;
};

export default PositiveNumberInput;
