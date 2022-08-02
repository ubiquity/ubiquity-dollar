import React from "react";

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement>;
type ButtonLinkProps = React.AnchorHTMLAttributes<HTMLAnchorElement>;

const Button: React.FC<ButtonProps> = ({ children }) => {
  return <button>{children}</button>;
};

export const ButtonLink: React.FC<ButtonLinkProps> = ({ children }) => {
  return <a>{children}</a>;
};

export default Button;
