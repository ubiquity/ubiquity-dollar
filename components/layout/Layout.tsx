import cx from "classnames";
import Link from "next/link";
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

const PROD = process.env.NODE_ENV == "production";

function ErrorHandler({ error }: { error: Error }) {
  return (
    <Container className="w-96">
      <div className="flex flex-col items-center justify-center text-center">
        <div className="mb-8 flex w-96 flex-col items-center justify-center text-accent opacity-50">
          <Icon icon="warning" className="w-20" />
          <div className="uppercase leading-tight tracking-widest">Error</div>
        </div>
        <div className="opacity-75">{error.message}</div>
      </div>
    </Container>
  );
}

export default function Layout({ children }: LayoutProps) {
  const [sidebarClientWidth, setSidebarClientWidth] = useState(0);
  const [sidebarState, setSidebarState] = useState<SidebarState>("loading");

  useEffect(() => {
    const { ethereum } = window;
    if (ethereum) {
      ethereum.on("accountsChanged", () => window.location.reload());
      ethereum.on("chainChanged", () => window.location.reload());
    }
  }, []);

  return (
    <div className="flex">
      <Sidebar permanentThreshold={1024} state={sidebarState} onChange={setSidebarState} onResize={setSidebarClientWidth} />
      <div className="fixed top-0 right-0 bottom-0" style={{ left: sidebarClientWidth }}>
        <WalletConnect />
        <div className="h-full w-full overflow-auto">
          <GridVideoBg />
          {sidebarState !== "loading" ? (
            <>
              <div className="relative z-10 flex-grow pl-0">
                <ConditionalHeader show={sidebarState !== "permanent"} />

                {/* Content */}

                <div
                  className={cx("mx-auto flex min-h-screen max-w-screen-lg flex-col items-center justify-center px-4 pb-8", {
                    "pt-8": sidebarState === "permanent",
                    "pt-24": sidebarState !== "permanent",
                  })}
                >
                  <ErrorBoundary FallbackComponent={ErrorHandler} resetKeys={[children]}>
                    {children}
                  </ErrorBoundary>
                </div>
              </div>
            </>
          ) : null}
        </div>
        {/* Floating Inventory */}
        <div className="pointer-events-none absolute bottom-0 z-50 flex w-full justify-center">
          <Inventory />
        </div>
        <TransactionsDisplay />
      </div>
    </div>
  );
}

const ConditionalHeader = ({ show }: { show: boolean }) => (
  <Link href="/">
    <a
      className={cx(
        "-mt-20 box-content flex h-12 items-center justify-center pt-6 uppercase tracking-widest transition duration-300 ease-in-out hover:text-accent hover:drop-shadow-light",
        { "translate-y-[100%]": show }
      )}
    >
      <Icon icon="ubq" className="mr-4 h-8" />
      <span className="mt-1">Ubiquity</span>
    </a>
  </Link>
);

const GridVideoBg = () => {
  const video = (
    <video autoPlay muted loop playsInline className="bg-video">
      {PROD && <source src="ubiquity-one-fifth-speed-trimmed-compressed.mp4" type="video/mp4" />}
    </video>
  );

  return (
    <div id="background" className="z-0">
      {video}
      <div id="grid" className="opacity-75"></div>
    </div>
  );
};
