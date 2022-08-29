import React from "react";

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement>;
type ButtonLinkProps = React.AnchorHTMLAttributes<HTMLAnchorElement>;

const Button: React.FC<ButtonProps> = ({ children, ...rest }) => {
  return (
    <button {...rest}>
      <span>{children}</span>
    </button>
  );
};

export const ButtonLink: React.FC<ButtonLinkProps> = ({ children, ...rest }) => {
  return (
    <a {...rest}>
      <Button>{children}</Button>
    </a>
  );
};

export default Button;
