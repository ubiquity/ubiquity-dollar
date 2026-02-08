import { ComponentProps, FC } from "react";
import { ChildrenShim } from "./hooks/children-shim-d";
export const combineComponents = (...components: FC<ChildrenShim>[]): FC<ChildrenShim> => {
  return components.reduce(
    (AccumulatedComponents, CurrentComponent) => {
      return function CombinedComponents({ children }: ComponentProps<FC<ChildrenShim>>): JSX.Element {
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
