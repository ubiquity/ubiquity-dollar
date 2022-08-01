import cx from "classnames";

const MaxButtonWrapper: React.FC<{ onMax: () => void; children: React.ReactNode; className?: string; disabled?: boolean }> = ({
  onMax,
  children,
  className,
  disabled,
}) => {
  return (
    <div>
      {children}
      <button onClick={() => onMax()} disabled={disabled}>
        MAX
      </button>
    </div>
  );
};

export default MaxButtonWrapper;
