const PositiveNumberInput = ({
  value,
  onChange,
  onParse,
  placeholder,
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
  return <input type="tel" value={value} onChange={onChangePatternWrap(onChange)} placeholder={placeholder} disabled={disabled} />;
};

export const TextInput = ({
  value,
}: {
  value: string;
  pattern?: RegExp;
  onParse?: (val: string) => string | null;
  onChange: (val: string) => void;
  placeholder?: string;
  className?: string;
  disabled?: boolean;
}) => {
  return <input value={value} />;
};

export default PositiveNumberInput;
