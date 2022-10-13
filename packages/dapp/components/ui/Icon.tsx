import React from "react";

import { jsxSvgIcons } from "./jsxIcons";

export type IconsNames = keyof typeof jsxSvgIcons;

const Icon = ({ icon, ...props }: { icon: IconsNames; className?: string }) => {
  return React.cloneElement(jsxSvgIcons[icon], props);
};

export default Icon;
