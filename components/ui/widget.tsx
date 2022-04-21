import React from "react";

export const Container = (props: React.PropsWithChildren<{ className?: string }>): JSX.Element => (
  <div
    className={`
      relative
      mx-auto mb-8
      max-w-screen-md rounded-lg border border-solid border-accent/60 bg-paper p-8 tracking-wide text-white/75
      ${props.className || ""}`}
  >
    {props.children}
  </div>
);

export const Title = (props: { text: string }): JSX.Element => <div className="mb-4 text-lg uppercase tracking-widest text-white/75">{props.text}</div>;

export const SubTitle = (props: { text: string }): JSX.Element => (
  <div className="mb-8 -mt-4 text-center text-xs uppercase tracking-widest text-white/50">{props.text}</div>
);
