import cx from "classnames";
import React from "react";

interface BaseButtonProps {
  styled?: "accent" | "default";
  size?: "sm" | "md" | "lg" | "xl";
  fill?: "inline" | "full";
}

type ButtonProps = React.ButtonHTMLAttributes<HTMLButtonElement> & BaseButtonProps;
type ButtonLinkProps = React.AnchorHTMLAttributes<HTMLAnchorElement> & BaseButtonProps;

const buttonStyle = ({ className, styled = "default", size = "md", fill = "inline" }: BaseButtonProps & { className?: string }): string => {
  const commonStyles = `
  items-center justify-center
  cursor-pointer whitespace-nowrap rounded-md font-special uppercase tracking-widest
  transition duration-200
  appearance-none outline-transparent outline outline-2 outline-accent/0 focus-visible:outline-accent/60`;

  const disabledStyles = "disabled:opacity-50 disabled:grayscale disabled:pointer-events-none";

  const fillType = {
    inline: "inline-flex",
    full: "flex w-full",
  }[fill];

  const buttonTypeSize = {
    sm: "text-2xs h-6 px-2",
    md: "text-xs h-10 px-4",
    lg: "text-lg h-14 px-6",
    xl: "text-xl h-20 px-10",
  }[size];

  const buttonTypeStyle = {
    default: "bg-transparent border-white/20 text-white/60 border-solid border hover:bg-white/20 hover:text-white",
    accent: "bg-accent/90 text-black/60 hover:bg-accent hover:drop-shadow-accent hover:text-white",
  }[styled];

  return cx(commonStyles, buttonTypeStyle, buttonTypeSize, fillType, className, disabledStyles);
};

const Button: React.FC<ButtonProps> = ({ children, className, styled, size, fill, ...rest }) => {
  return (
    <button className={buttonStyle({ className, styled, size, fill })} {...rest}>
      {children}
    </button>
  );
};

export const ButtonLink: React.FC<ButtonLinkProps> = ({ children, className, styled, size, fill, ...rest }) => {
  return (
    <a className={buttonStyle({ className, styled, size, fill })} {...rest}>
      {children}
    </a>
  );
};

export default Button;
