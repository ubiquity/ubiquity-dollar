import { useEffect } from "react";

const useEffectAsync = (effect: () => Promise<void>, deps: any[]) => {
  useEffect(() => {
    effect();
  }, deps);
};

export default useEffectAsync;
