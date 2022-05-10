import React from "react";
import cx from "classnames";

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  styled?: "accent" | "default";
}

const Button: React.FC<ButtonProps> = ({ children, className, disabled, styled = "default", ...rest }) => {
  return (
    <button
      {...rest}
      disabled={disabled}
      className={cx(
        `cursor-pointer rounded-md
        bg-accent/90 py-2 px-4 font-special
        text-xs uppercase tracking-widest text-paper
        transition duration-200
        hover:bg-accent hover:drop-shadow-accent`,
        className,
        { "cursor-auto opacity-50 grayscale hover:bg-accent/90 hover:drop-shadow-none": disabled }
      )}
    >
      {children}
    </button>
  );
};

export default Button;
