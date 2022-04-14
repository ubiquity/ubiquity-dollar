import { useEffect, useCallback, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/router";
import cx from "classnames";
import { Icon, IconNames } from "../ui/icons";

const PROD = process.env.NODE_ENV == "production";

export type SidebarState = "loading" | "permanent" | "hidden" | "hidden_hovering";

const Sidebar = ({
  state,
  onChange,
  onResize,
  permanentThreshold,
}: {
  state: SidebarState;
  onChange: (state: SidebarState) => void;
  onResize: (size: number) => void;
  permanentThreshold: number;
}) => {
  const sidebarRef = useRef<HTMLDivElement>(null);

  const handleResize = useCallback(() => {
    if (sidebarRef.current) {
      if (window.innerWidth < permanentThreshold) {
        onResize(0);
        onChange("hidden");
      } else {
        onResize(sidebarRef.current.clientWidth);
        onChange("permanent");
      }
    }
  }, []);

  const handleEnter = useCallback(() => {
    if (state === "hidden") {
      onChange("hidden_hovering");
    }
  }, [state]);

  const handleLeave = useCallback(() => {
    if (state === "hidden_hovering") {
      onChange("hidden");
    }
  }, [state]);

  const handleToggle = useCallback(() => {
    if (state === "hidden") {
      onChange("hidden_hovering");
    } else {
      onChange("hidden");
    }
  }, [state]);

  useEffect(() => {
    handleResize();

    window.addEventListener("resize", handleResize);

    return () => {
      window.removeEventListener("resize", handleResize);
    };
  }, []);

  return (
    <>
      <div
        className={cx("fixed top-0 h-screen z-50 transition-transform duration-500 ease-in-out border-r border-r-accent/60 border-solid bg-paper", {
          "lg:translate-x-0": state !== "hidden",
          "-translate-x-[97%]": state === "hidden",
        })}
        ref={sidebarRef}
        onMouseEnter={handleEnter}
        onMouseLeave={handleLeave}
      >
        {/* Header */}

        {state === "permanent" ? (
          <Link href="/">
            <a className="flex flex-col items-center justify-center my-8 uppercase tracking-widest hover:text-accent hover:drop-shadow-light transition duration-300 ease-in-out">
              <Icon icon="ubq" className="w-16 mb-4" />
              <span>Ubiquity Dollar</span>
            </a>
          </Link>
        ) : null}

        {/* Caret / Toggle button */}

        {state === "hidden" || state === "hidden_hovering" ? (
          <a
            className={cx("absolute flex items-center justify-center rounded-r border border-l-0 border-accent/60 border-solid top-[50%] left-full ml-[1px] ", {
              "bg-paper text-accent": state === "hidden",
              "bg-accent text-paper": state === "hidden_hovering",
            })}
            aria-label="Toggle navigation"
            onClick={handleToggle}
          >
            <Icon
              icon="caret"
              className={cx("w-6 h-6 m-1 transition-transform duration-500 ease-in-out", {
                "rotate-[270deg]": state === "hidden",
                "rotate-90": state === "hidden_hovering",
              })}
            />
          </a>
        ) : null}

        {/* Items */}

        <ul className={cx("h-full flex flex-col", { "justify-center": state !== "permanent" })}>
          <Item text="Ubiquity Intro" href="https://landing.ubq.fi/en/"></Item>
          <Item text="Price Stabilization" href="/"></Item>
          <Item text="Liquidity Mining" href="/liquidity-mining"></Item>
          <Item text="Yield Farming" href="/yield-farming"></Item>
          {/* <Item text="Debt Coupon" href="/debt-coupon"></Item> */}
          {PROD ? null : <Item text="Launch Party" href="/launch-party"></Item>}
          <Item text="Tokens Swap" href="/tokens-swap"></Item>
          <Item text="Docs" href="https://dao.ubq.fi/docs"></Item>
          <Item text="DAO" href="https://dao.ubq.fi/"></Item>
          <Item text="Blog" href="https://medium.com/ubiquity-dao"></Item>
          {/* <Item text="Public Channels" href="/public-channels"></Item> */}
          <li className="flex justify-center mt-8">
            <SocialLinkItem href="https://twitter.com/UbiquityDAO" alt="Twitter" icon="twitter" />
            <SocialLinkItem href="https://t.me/ubiquitydao" alt="Telegram" icon="telegram" />
            <SocialLinkItem href="https://github.com/ubiquity" alt="Github" icon="github" />
            <SocialLinkItem href="https://discord.gg/SjymJ5maJ4" alt="Discord" icon="discord" />
          </li>
        </ul>
      </div>

      {/* Overlay */}

      {state === "hidden_hovering" ? <div className="absolute h-full w-full bg-black/50 z-40" onClick={handleToggle}></div> : null}
    </>
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
            "flex px-2 py-2 items-center justify-center text-sm uppercase tracking-widest font-light  text-ellipsis whitespace-nowrap rounded transition hover:transition-none duration-300 ease-in-out border border-solid",
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

export default Sidebar;
