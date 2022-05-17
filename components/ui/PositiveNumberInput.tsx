import cx from "classnames";

const BASE_CLASS = `
  block
  h-10 px-4
  rounded-md
  text-md  tracking-wider text-black/70 placeholder-black/30
  shadow-[inset_0_0_2px_#000]
  appearance-none outline outline-2 outline-accent/0
  transition-all duration-500
  focus:outline-accent/60
  focus:drop-shadow-[0_0_4px_rgba(0,255,255,.8)]  disabled:opacity-50`;

const PositiveNumberInput = ({
  value,
  onChange,
  onParse,
  placeholder,
  className,
  disabled,
  fraction = true,
}: {
  value: string;
  onParse?: (val: string) => string | null;
  onChange: (val: string) => void;
  placeholder?: string;
  className?: string;
  disabled?: boolean;
  fraction?: boolean;
}) => {
  const pattern = fraction ? /^[0-9]*\.?[0-9]*$/ : /^[0-9]*$/;

  const onChangePatternWrap = (handler: (val: string) => void) => (ev: React.ChangeEvent<HTMLInputElement>) => {
    const val = ev.currentTarget.value;
    if (!onParse) {
      if (pattern.test(val)) {
        handler(val);
      }
    } else {
      const parsed = onParse(val);
      if (parsed !== null) {
        handler(parsed);
      }
    }
  };
  return (
    <input
      type="tel"
      value={value}
      className={cx(BASE_CLASS, className)}
      onChange={onChangePatternWrap(onChange)}
      placeholder={placeholder}
      disabled={disabled}
    />
  );
};

export const TextInput = ({
  value,
  onChange,
  placeholder,
  className,
  disabled,
}: {
  value: string;
  pattern?: RegExp;
  onParse?: (val: string) => string | null;
  onChange: (val: string) => void;
  placeholder?: string;
  className?: string;
  disabled?: boolean;
}) => {
  const onChangePatternWrap = (handler: (val: string) => void) => (ev: React.ChangeEvent<HTMLInputElement>) => {
    handler(ev.currentTarget.value);
  };

  return <input value={value} className={cx(BASE_CLASS, className)} onChange={onChangePatternWrap(onChange)} placeholder={placeholder} disabled={disabled} />;
};

export default PositiveNumberInput;
