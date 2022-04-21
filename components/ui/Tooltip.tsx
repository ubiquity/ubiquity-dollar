import Tippy from "@tippyjs/react";
import { Placement } from "tippy.js";

const Tooltip = ({ children, content, placement }: { children: React.ReactElement; content: string; placement?: Placement }) => (
  <Tippy
    content={
      <div className="rounded-md border border-solid border-white/10 bg-paper px-4 py-2 text-sm" style={{ backdropFilter: "blur(8px)" }}>
        <p className="text-center text-white/50">{content}</p>
      </div>
    }
    placement={placement || "top"}
    duration={0}
  >
    {children}
  </Tippy>
);

export default Tooltip;
