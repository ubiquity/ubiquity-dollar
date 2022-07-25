import { Icon, IconsNames } from "@/ui";
import cx from "classnames";
import Link from "next/link";
import { useRouter } from "next/router";
import { useCallback, useEffect, useRef } from "react";

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
        className={cx("fixed top-0 z-50 h-screen border-r border-solid border-r-accent/60 bg-paper transition-transform duration-500 ease-in-out", {
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
            <a className="my-8 flex flex-col items-center justify-center uppercase tracking-widest transition duration-300 ease-in-out hover:text-accent hover:drop-shadow-light">
              <Icon icon="ubq" className="mb-4 w-16" />
              <span>Ubiquity</span>
            </a>
          </Link>
        ) : null}

        {/* Caret / Toggle button */}

        {state === "hidden" || state === "hidden_hovering" ? (
          <a
            className={cx("absolute top-[50%] left-full ml-[1px] flex items-center justify-center rounded-r border border-l-0 border-solid border-accent/60 ", {
              "bg-paper text-accent": state === "hidden",
              "bg-accent text-paper": state === "hidden_hovering",
            })}
            aria-label="Toggle navigation"
            onClick={handleToggle}
          >
            <Icon
              icon="caret"
              className={cx("m-1 h-6 w-6 transition-transform duration-500 ease-in-out", {
                "rotate-[270deg]": state === "hidden",
                "rotate-90": state === "hidden_hovering",
              })}
            />
          </a>
        ) : null}

        {/* Items */}

        <ul className={cx("flex h-full flex-col", { "justify-center": state !== "permanent" })}>
          <Item text="Ubiquity Intro" href="https://landing.ubq.fi/en/" icon="🦍"></Item>
          <Item text="Redeem" href="/" icon="💸"></Item>
          <Item text="Staking" href="/staking" icon="⛏"></Item>
          <Item text="Yield Farming" href="/yield-farming" icon="🚜"></Item>
          {/* <Item text="Debt Coupon" href="/debt-coupon"></Item> */}
          {PROD ? null : <Item text="Launch Party" href="/launch-party" icon="🎉"></Item>}
          <Item text="Swap" href="/swap" icon="🔁"></Item>
          <Item text="Docs" href="https://dao.ubq.fi/docs" icon="📑"></Item>
          <Item text="DAO" href="https://dao.ubq.fi/" icon="🤝"></Item>
          <Item text="Blog" href="https://medium.com/ubiquity-dao" icon="📰"></Item>
          {/* <Item text="Public Channels" href="/public-channels"></Item> */}
          <li className="mt-8 flex justify-center">
            <SocialLinkItem href="https://twitter.com/UbiquityDAO" alt="Twitter" icon="twitter" />
            <SocialLinkItem href="https://t.me/ubiquitydao" alt="Telegram" icon="telegram" />
            <SocialLinkItem href="https://github.com/ubiquity" alt="Github" icon="github" />
            <SocialLinkItem href="https://discord.gg/SjymJ5maJ4" alt="Discord" icon="discord" />
          </li>
        </ul>
      </div>

      {/* Overlay */}

      {state === "hidden_hovering" ? <div className="absolute z-40 h-full w-full bg-black/50" onClick={handleToggle}></div> : null}
    </>
  );
};

const SocialLinkItem = ({ href, icon, alt }: { href: string; icon: IconsNames; alt: string }) => (
  <a
    href={href}
    className="mx-1 flex h-10 w-10 items-center justify-center rounded-full border border-solid border-transparent p-2 text-white/75 transition duration-300 ease-in-out hover:border-accent/0 hover:bg-white/5 hover:drop-shadow-light hover:transition-none"
    target="_blank"
    title={alt}
  >
    <Icon className="w-full" icon={icon} />
  </a>
);

const Item = ({ text, href }: { text: string; href: string; icon: string }) => {
  const router = useRouter();
  const isActive = router.asPath === href;
  const isExternal = href.startsWith("http");
  return (
    <li className="relative mb-1 cursor-pointer px-2">
      <Link href={href}>
        <a
          className={cx(
            "flex items-center justify-center text-ellipsis whitespace-nowrap rounded border border-solid py-2  pl-2 text-sm font-light uppercase tracking-widest transition duration-300 ease-in-out hover:transition-none",
            {
              "border-accent bg-accent/10 text-accent drop-shadow-accent": isActive,
              "border-transparent text-white/75 hover:bg-white/5 hover:drop-shadow-light": !isActive,
            }
          )}
          target={href.match(/https?:\/\//) ? "_blank" : ""}
        >
          {text}
          {isExternal ? <Icon className="ml-0.5 -mt-0.5 h-3.5 opacity-50" icon="external" /> : null}
        </a>
      </Link>
      <div className={cx("absolute left-full top-[50%] -ml-2 h-[1px] bg-accent transition-all", { "w-2": isActive, "w-0": !isActive })}></div>
    </li>
  );
};

export default Sidebar;
