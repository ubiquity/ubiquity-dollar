import React, { useEffect, useState } from "react";
import { ErrorBoundary } from "react-error-boundary";

import { Container, Icon } from "@/ui";

import Inventory from "./Inventory";
import Sidebar, { SidebarState } from "./Sidebar";
import TransactionsDisplay from "./TransactionsDisplay";
import WalletConnect from "./WalletConnect";

type LayoutProps = {
  children: React.ReactNode;
};

function ErrorHandler({ error }: { error: Error }) {
  return (
    <Container>
      <div>
        <div>
          <Icon icon="warning" />
          <div>Error</div>
        </div>
        <div>{error.message}</div>
      </div>
    </Container>
  );
}

export default function Layout({ children }: LayoutProps) {
  const [setSidebarClientWidth] = useState(0);
  const [sidebarState, setSidebarState] = useState<SidebarState>("loading");

  useEffect(() => {
    const { ethereum } = window;
    if (ethereum) {
      ethereum.on("accountsChanged", () => window.location.reload());
      ethereum.on("chainChanged", () => window.location.reload());
    }
  }, []);

  return (
    <div id="Foreground">
      <Sidebar permanentThreshold={1024} state={sidebarState} onChange={setSidebarState} />
      <div id="MainContent">
        <div>
          <div id="Content">
            {sidebarState !== "loading" ? (
              <>
                <div>
                  {/* <ConditionalHeader show={sidebarState !== "permanent"} /> */}

                  {/* Content */}

                  <div>
                    <ErrorBoundary FallbackComponent={ErrorHandler} resetKeys={[children]}>
                      {children}
                    </ErrorBoundary>
                  </div>
                </div>
              </>
            ) : null}
          </div>
          <TransactionsDisplay />
        </div>
      </div>
      <Inventory />
    </div>
  );
}
