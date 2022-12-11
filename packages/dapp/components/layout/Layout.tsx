import React, { useEffect } from "react";
import { ErrorBoundary } from "react-error-boundary";

import Icon from "../ui/Icon";
import BuildInfo from "./BuildInfo";
import Inventory from "./Inventory";
import Sidebar from "./Sidebar";
import TransactionsDisplay from "./TransactionsDisplay";

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
  useEffect(() => {
    const { ethereum } = window;
    if (ethereum) {
      ethereum.on("accountsChanged", window.location.reload);
      ethereum.on("chainChanged", window.location.reload);
    }
  }, []);

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
        
        {/* project build info (URL to deployed commit) */}
        <BuildInfo />
      </div>
    </div>
  );
}

function hideSidebarOnMobile() {
  const checkbox = document.querySelector("#Foreground > input[type=checkbox]") as HTMLInputElement;
  checkbox.checked = false;
}
