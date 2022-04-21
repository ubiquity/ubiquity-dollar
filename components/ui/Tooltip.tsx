import Tippy from "@tippyjs/react";

const Tooltip = ({ children, content }: { children: React.ReactElement; content: string }) => (
  <Tippy
    content={
      <div className="rounded-md border border-solid border-white/10 bg-paper px-4 py-2 text-sm" style={{ backdropFilter: "blur(8px)" }}>
        <p className="text-center text-white/50">{content}</p>
      </div>
    }
    placement="top"
    duration={0}
  >
    {children}
  </Tippy>
);

export default Tooltip;
