import React, { useEffect, useRef } from "react";
import { ErrorBoundary } from "react-error-boundary";

import Icon from "../ui/icon";
import Inventory from "./inventory";
import Sidebar from "./sidebar";
import TransactionsDisplay from "./transactions-display";

type LayoutProps = {
  children: React.ReactNode;
};

function ErrorHandler({ error }: { error: Error }) {
  return (
    <div id="Error" className="panel">
      <div>
        <Icon icon="warning" />
        <h2>Error</h2>
      </div>
      <div>{error.message}</div>
    </div>
  );
}

export default function Layout({ children }: LayoutProps) {
  const firstUpdate = useRef(false);
  const updateFinish = useRef(false);

  useEffect(() => {
    //@note Fix: (Illegal Invocation)
    if (firstUpdate.current) {
      const { ethereum } = window;
      if (ethereum) {
        ethereum.on("accountsChanged", window.location.reload);
        ethereum.on("chainChanged", window.location.reload);
      }
      firstUpdate.current = false;
      updateFinish.current = true;
    } else {
      if (!updateFinish.current) {
        firstUpdate.current = true;
      }
    }
  }, [firstUpdate]);

  return (
    <div id="Foreground">
      <Sidebar />
      <div id="MainContent" onClick={hideSidebarOnMobile}>
        <div>
          <TransactionsDisplay />
          <div id="Content">
            <div>
              <div>
                <ErrorBoundary FallbackComponent={ErrorHandler} resetKeys={[children]}>
                  {children}
                </ErrorBoundary>
              </div>
            </div>
          </div>
        </div>

        <div>
          <Inventory />
        </div>
      </div>
    </div>
  );
}

function hideSidebarOnMobile() {
  const checkbox = document.querySelector("#Foreground > input[type=checkbox]") as HTMLInputElement;
  checkbox.checked = false;
}
