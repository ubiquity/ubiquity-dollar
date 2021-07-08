import { ReactChildren } from "react";

export default function Widget({
  children,
}: {
  children: ReactChildren;
}): JSX.Element {
  return (
    <div className="!block !mx-0 !py-8 text-white text-opacity-50 tracking-wide bg-black border border-white">
      {children}
    </div>
  );
}
