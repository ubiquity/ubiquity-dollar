import cx from "classnames";

const MaxButtonWrapper: React.FC<{ onMax: () => void; className?: string; disabled?: boolean }> = ({ onMax, children, className, disabled }) => {
  return (
    <div className={cx("relative", className)}>
      {children}
      <button
        onClick={() => onMax()}
        disabled={disabled}
        className={cx(
          `absolute right-0 top-[50%] mr-2 flex h-5  translate-y-[-50%] cursor-pointer
          items-center rounded-md
          border border-solid border-white
          bg-black/80 px-1.5 text-2xs text-white
          transition-all duration-500
          hover:border-accent hover:text-accent hover:drop-shadow-accent
          focus-visible:border-accent focus-visible:text-accent focus-visible:outline-none focus-visible:drop-shadow-accent`,
          { "pointer-events-none opacity-25": disabled }
        )}
      >
        MAX
      </button>
    </div>
  );
};

export default MaxButtonWrapper;
