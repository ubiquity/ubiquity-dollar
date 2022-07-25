import { ComponentProps, FC } from "react";

export const combineComponents = (...components: FC[]): FC => {
  return components.reduce(
    (AccumulatedComponents, CurrentComponent) => {
      return function CombinedComponents({ children }: ComponentProps<FC>): JSX.Element {
        return (
          <AccumulatedComponents>
            <CurrentComponent>{children}</CurrentComponent>
          </AccumulatedComponents>
        );
      };
    },
    function CombinedComponents({ children }) {
      return <>{children}</>;
    }
  );
};
