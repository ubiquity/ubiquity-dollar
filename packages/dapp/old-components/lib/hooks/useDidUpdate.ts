import { useEffect, useRef } from "react";

// Like useEffect, but only fires after the first render
const useDidUpdate = (callback: () => void, conditions?: unknown[]) => {
  const didMountRef = useRef(false);
  useEffect(() => {
    if (!didMountRef.current) {
      didMountRef.current = true;
      return;
    }

    return callback && callback();
  }, conditions);
};

export default useDidUpdate;
