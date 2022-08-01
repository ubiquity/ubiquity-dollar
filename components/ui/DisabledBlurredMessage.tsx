import cx from "classnames";

const DisabledBlurredMessage = ({ content, disabled, children }: { content: React.ReactNode; disabled: boolean; children: React.ReactNode }) => {
  return (
    <div>
      <div>{children}</div>
      {disabled && <div>{typeof content === "string" ? <span>{content}</span> : content}</div>}
    </div>
  );
};

export default DisabledBlurredMessage;
