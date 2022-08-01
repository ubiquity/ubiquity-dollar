import Tippy from "@tippyjs/react";
import { Placement } from "tippy.js";

const Tooltip = ({ children, content, placement }: { children: React.ReactElement; content: React.ReactNode | string; placement?: Placement }) => (
  <Tippy
    content={
      <div style={{ backdropFilter: "blur(8px)" }}>
        <div>{content}</div>
      </div>
    }
    placement={placement || "top"}
    duration={0}
  >
    {children}
  </Tippy>
);

export default Tooltip;
