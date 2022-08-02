import Link from "next/link";
import { useCallback, useEffect, useRef } from "react";
import Icon, { IconsNames } from "../ui/Icon";
import WalletConnect from "./WalletConnect";

const PROD = process.env.NODE_ENV == "production";

export type SidebarState = "loading" | "permanent" | "hidden" | "hidden_hovering";

const Sidebar = ({ state, onChange, permanentThreshold }: { state: SidebarState; onChange: (state: SidebarState) => void; permanentThreshold: number }) => {
  const sidebarRef = useRef<HTMLDivElement>(null);

  const handleResize = useCallback(() => {
    if (sidebarRef.current) {
      if (window.innerWidth < permanentThreshold) {
        onChange("hidden");
      } else {
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
      <div id="Sidebar" ref={sidebarRef} onMouseEnter={handleEnter} onMouseLeave={handleLeave}>
        <WalletConnect />
        {/* Header */}

        {/* Caret / Toggle button */}

        {state === "hidden" || state === "hidden_hovering" ? (
          <a aria-label="Toggle navigation" onClick={handleToggle}>
            <Icon icon="caret" />
          </a>
        ) : null}

        {/* Items */}

        <ul>
          <li>
            <div>
              {" "}
              {state === "permanent" ? (
                <Link href="/">
                  <a>
                    <Icon icon="uad" />
                    <span>Ubiquity Dollar Dashboard</span>
                  </a>
                </Link>
              ) : null}
            </div>
          </li>
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

          <li>
            <SocialLinkItem href="https://twitter.com/UbiquityDAO" alt="Twitter" icon="twitter" />
          </li>
          <li>
            <SocialLinkItem href="https://t.me/ubiquitydao" alt="Telegram" icon="telegram" />
          </li>
          <li>
            <SocialLinkItem href="https://github.com/ubiquity" alt="Github" icon="github" />
          </li>
          <li>
            <SocialLinkItem href="https://discord.gg/SjymJ5maJ4" alt="Discord" icon="discord" />
          </li>
        </ul>
      </div>

      {/* Overlay */}

      {state === "hidden_hovering" ? <div onClick={handleToggle}></div> : null}
    </>
  );
};

const SocialLinkItem = ({ href, icon, alt }: { href: string; icon: IconsNames; alt: string }) => (
  <a href={href} target="_blank" title={alt}>
    <div>
      <Icon icon={icon} />
    </div>
  </a>
);

const Item = ({ text, href }: { text: string; href: string; icon: string }) => {
  const isExternal = href.startsWith("http");
  return (
    <li>
      <div>
        <Link href={href}>
          <a target={href.match(/https?:\/\//) ? "_blank" : ""}>
            <span>{text}</span>
            {isExternal ? <Icon icon="external" /> : null}
          </a>
        </Link>
      </div>
    </li>
  );
};

export default Sidebar;
