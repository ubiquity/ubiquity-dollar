import { useState } from "react";
import Link from "next/link";
import cx from "classnames";
import { Icon } from "../ui/icons";
import Inventory from "../inventory";
import TransactionsDisplay from "../TransactionsDisplay";
import Sidebar, { SidebarState } from "./Sidebar";

type LayoutProps = {
  children: React.ReactNode;
};

const PROD = process.env.NODE_ENV == "production";

export default function Layout({ children }: LayoutProps) {
  const [sidebarClientWidth, setSidebarClientWidth] = useState(0);
  const [sidebarState, setSidebarState] = useState<SidebarState>("loading");

  return (
    <div className="flex">
      <GridVideoBg />
      <Sidebar permanentThreshold={1024} state={sidebarState} onChange={setSidebarState} onResize={setSidebarClientWidth} />
      {sidebarState !== "loading" ? (
        <>
          <div className="relative flex-grow pl-0 z-10" style={{ paddingLeft: sidebarClientWidth }}>
            <ConditionalHeader show={sidebarState !== "permanent"} />

            {/* Content */}

            <div
              className={cx("flex flex-col min-h-screen pb-8 px-4 max-w-screen-lg items-center justify-center mx-auto", {
                "pt-8": sidebarState === "permanent",
                "pt-24": sidebarState !== "permanent",
              })}
            >
              {children}
            </div>
          </div>

          {/* Floating Inventory */}
          <div className="fixed bottom-0 w-full flex justify-center z-50 pointer-events-none" style={{ paddingLeft: sidebarClientWidth }}>
            <Inventory />
          </div>
        </>
      ) : null}
      <TransactionsDisplay />
    </div>
  );
}

const ConditionalHeader = ({ show }: { show: boolean }) => (
  <Link href="/">
    <a
      className={cx(
        "flex items-center justify-center box-content h-12 pt-6 -mt-20 uppercase tracking-widest hover:text-accent hover:drop-shadow-light transition duration-300 ease-in-out",
        { "translate-y-[100%]": show }
      )}
    >
      <Icon icon="ubq" className="h-8 mr-4" />
      <span className="mt-1">Ubiquity Dollar</span>
    </a>
  </Link>
);

const GridVideoBg = () => {
  const poster =
    "https://ssfy.io/https%3A%2F%2Fwww.notion.so%2Fimage%2Fhttps%253A%252F%252Fs3-us-west-2.amazonaws.com%252Fsecure.notion-static.com%252Fbb144e8e-3a57-4e68-b2b9-6a80dbff07d0%252FGroup_3.png%3Ftable%3Dblock%26id%3Dff1a3cae-9009-41e4-9cc4-d4458cc2867d%26cache%3Dv2";

  const video = (
    <video autoPlay muted loop playsInline poster={poster} className="bg-video">
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
