import React from "react";
//border border-solid border-accent/60
export const Container = (props: React.PropsWithChildren<{ className?: string }>): JSX.Element => (
  <div>
    <div>
      <div>{props.children}</div>
    </div>
  </div>
);

export const Title = (props: { text: string }): JSX.Element => <div>{props.text}</div>;

export const SubTitle = (props: { text: string }): JSX.Element => <div>{props.text}</div>;
