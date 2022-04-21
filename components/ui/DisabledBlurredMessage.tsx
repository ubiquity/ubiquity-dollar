import cx from "classnames";

const DisabledBlurredMessage = ({ content, disabled, children }: { content: React.ReactNode; disabled: boolean; children: React.ReactNode }) => {
  return (
    <div className="relative">
      <div className={cx({ "blur-sm": disabled })}>{children}</div>
      {disabled && (
        <div className="absolute top-0 right-0 bottom-0 left-0 flex items-center  justify-center rounded-lg border-4 border-dashed border-white/25 bg-white/10">
          {typeof content === "string" ? <span className="uppercase tracking-widest">{content}</span> : content}
        </div>
      )}
    </div>
  );
};

export default DisabledBlurredMessage;
