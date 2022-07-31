import { useEffect } from "react";

const useEffectAsync = (effect: () => Promise<void>, deps: unknown[]) => {
  useEffect(() => {
    effect();
  }, deps);
};

export default useEffectAsync;
