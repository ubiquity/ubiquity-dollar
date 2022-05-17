import React from "react";
//border border-solid border-accent/60
export const Container = (props: React.PropsWithChildren<{ className?: string }>): JSX.Element => (
  <div
    className={`
      relative mx-auto
      mb-8 max-w-screen-md rounded-lg
      tracking-wide text-white/75
      ${props.className || ""}`}
  >
    <div className="w-full rounded-lg bg-gradient-to-br from-accent/90 via-accent/50 to-accent/70 p-[1px]">
      <div className="rounded-[0.46rem]  bg-paper p-8">{props.children}</div>
    </div>
  </div>
);

export const Title = (props: { text: string }): JSX.Element => (
  <div className="mb-4 text-center text-lg uppercase tracking-widest text-white/75">{props.text}</div>
);

export const SubTitle = (props: { text: string }): JSX.Element => (
  <div className="mb-8 -mt-4 text-center text-center text-xs uppercase tracking-widest text-white/50">{props.text}</div>
);
