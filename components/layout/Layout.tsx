import { useState, useEffect, useCallback, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/router";
import cx from "classnames";
import { Icon, IconNames } from "../ui/icons";
import Inventory from "../inventory";
import TransactionsDisplay from "../TransactionsDisplay";

type LayoutProps = {
  children: React.ReactNode;
};

const PROD = process.env.NODE_ENV == "production";

type SidebarState = "loading" | "permanent" | "hidden" | "hidden_hovering";

export default function Layout({ children }: LayoutProps) {
  const sidebarRef = useRef<HTMLDivElement>(null);
  const [sidebarClientWidth, setSidebarClientWidth] = useState(0);
  const [sidebarState, setSidebarState] = useState<SidebarState>("loading");

  const handleResize = useCallback(() => {
    if (sidebarRef.current) {
      if (window.innerWidth < 1024) {
        setSidebarClientWidth(0);
        setSidebarState("hidden");
      } else {
        setSidebarClientWidth(sidebarRef.current.clientWidth);
        setSidebarState("permanent");
      }
    }
  }, []);

  const handleSidebarEnter = useCallback(() => {
    if (sidebarState === "hidden") {
      setSidebarState("hidden_hovering");
    }
  }, [sidebarState]);

  const handleSidebarLeave = useCallback(() => {
    if (sidebarState === "hidden_hovering") {
      setSidebarState("hidden");
    }
  }, [sidebarState]);

  const handleSidebarToggle = useCallback(() => {
    if (sidebarState === "hidden") {
      setSidebarState("hidden_hovering");
    } else {
      setSidebarState("hidden");
    }
  }, [sidebarState]);

  useEffect(() => {
    handleResize();

    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
    };
  }, []);

  return (
    <div className="flex">
      <GridVideoBg />
      <div
        className={cx("fixed top-0 h-screen z-50 transition-transform border-r border-r-accent/60 border-solid bg-paper", {
          "lg:translate-x-0": sidebarState !== "hidden",
          "-translate-x-[97%]": sidebarState === "hidden",
        })}
        ref={sidebarRef}
        onMouseEnter={handleSidebarEnter}
        onMouseLeave={handleSidebarLeave}
      >
        {sidebarState === "hidden" || sidebarState === "hidden_hovering" ? (
          <a
            className={cx("absolute flex items-center justify-center rounded-r border border-l-0 border-accent/60 border-solid top-[50%] left-full ml-[1px] ", {
              "bg-paper text-accent": sidebarState === "hidden",
              "bg-accent text-paper": sidebarState === "hidden_hovering",
            })}
            aria-label="Toggle navigation"
            onClick={handleSidebarToggle}
          >
            <svg
              aria-hidden="true"
              focusable="false"
              data-prefix="fas"
              className={cx("w-6 h-6 m-1 transition-transform", {
                "-rotate-90": sidebarState === "hidden",
                "rotate-90": sidebarState === "hidden_hovering",
              })}
              role="img"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 448 512"
            >
              <path
                fill="currentColor"
                d="M207.029 381.476L12.686 187.132c-9.373-9.373-9.373-24.569 0-33.941l22.667-22.667c9.357-9.357 24.522-9.375 33.901-.04L224 284.505l154.745-154.021c9.379-9.335 24.544-9.317 33.901.04l22.667 22.667c9.373 9.373 9.373 24.569 0 33.941L240.971 381.476c-9.373 9.372-24.569 9.372-33.942 0z"
              ></path>
            </svg>
          </a>
        ) : null}

        <ul className="h-full flex flex-col justify-center">
          <Item text="Ubiquity Intro" href="https://landing.ubq.fi/en/"></Item>
          <Item text="Price Stabilization" href="/"></Item>
          <Item text="Liquidity Mining" href="/liquidity-mining"></Item>
          <Item text="Yield Farming" href="/yield-farming"></Item>
          {/* <Item text="Debt Coupon" href="/debt-coupon"></Item> */}
          <Item text="Launch Party" href="/launch-party"></Item>
          <Item text="Tokens Swap" href="/tokens-swap"></Item>
          <Item text="Docs" href="https://dao.ubq.fi/docs"></Item>
          <Item text="DAO" href="https://dao.ubq.fi/"></Item>
          <Item text="Blog" href="https://medium.com/ubiquity-dao"></Item>
          {/* <Item text="Public Channels" href="/public-channels"></Item> */}
          <li className="flex justify-center mt-4">
            <SocialLinkItem href="https://twitter.com/UbiquityDAO" alt="Twitter" icon="twitter" />
            <SocialLinkItem href="https://t.me/ubiquitydao" alt="Telegram" icon="telegram" />
            <SocialLinkItem href="https://github.com/ubiquity" alt="Github" icon="github" />
            <SocialLinkItem href="https://discord.gg/SjymJ5maJ4" alt="Discord" icon="discord" />
          </li>
        </ul>
      </div>
      {sidebarState !== "loading" ? (
        <>
          <div className="relative flex-grow pl-0 z-10" style={{ paddingLeft: sidebarClientWidth }}>
            {sidebarState === "hidden_hovering" ? <div className="absolute h-full w-full bg-black/50 z-40" onClick={handleSidebarToggle}></div> : null}
            <div className="flex flex-col min-h-screen py-8 px-4 max-w-screen-lg items-center justify-center mx-auto">
              {/* <Header /> */}
              {/* <div className="flex-grow">{children}</div> */}
              {children}
            </div>
          </div>
          <div className="fixed bottom-0 w-full flex justify-center z-50 pointer-events-none" style={{ paddingLeft: sidebarClientWidth }}>
            <Inventory />
          </div>
        </>
      ) : null}
      <TransactionsDisplay />
    </div>
  );
}

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
      <div id="grid" className="opacity-50"></div>
    </div>
  );
};

const SocialLinkItem = ({ href, icon, alt }: { href: string; icon: IconNames; alt: string }) => (
  <a
    href={href}
    className="rounded-full h-10 w-10 p-2 hover:bg-white/5 hover:drop-shadow-light border border-solid border-transparent hover:border-accent/0 flex items-center justify-center mx-1 text-white/75 transition hover:transition-none duration-300 ease-in-out"
    target="_blank"
    title={alt}
  >
    <Icon className="w-full" icon={icon} />
  </a>
);

const Item = ({ text, href }: { text: string; href: string }) => {
  const router = useRouter();
  const isActive = router.asPath === href;
  return (
    <li className="relative cursor-pointer px-2 mb-1">
      <Link href={href}>
        <a
          className={cx(
            "flex px-2 py-2 items-center justify-center text-sm uppercase tracking-widest font-light overflow-hidden text-ellipsis whitespace-nowrap rounded transition hover:transition-none duration-300 ease-in-out border border-solid",
            {
              "bg-accent/10 border-accent text-accent drop-shadow-accent": isActive,
              "hover:bg-white/5 border-transparent text-white/75 hover:drop-shadow-lght": !isActive,
            }
          )}
          target={href.match(/https?:\/\//) ? "_blank" : ""}
        >
          {text}
        </a>
      </Link>
      <div className={cx("absolute left-full -ml-2 top-[50%] h-[1px] bg-accent transition-all", { "w-2": isActive, "w-0": !isActive })}></div>
    </li>
  );
};
