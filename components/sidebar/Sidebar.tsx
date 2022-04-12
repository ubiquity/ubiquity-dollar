import { useRouter } from "next/router";
import Link from "next/link";

type SidebarProps = {
  isOpened: boolean;
  onClose: () => void;
};

export default function Sidebar({ isOpened, onClose }: SidebarProps) {
  return (
    // <div
    //   className={`${isOpened ? "w-[300px]" : "w-[0vw]"} lg:w-[300px] absolute top-0 h-screen shadow-md z-50 bg-[#00000060] overflow-hidden flex flex-col`}
    //   style={{ transition: ".15s width ease-in-out" }}
    // >
    <div>
      {/* <span className="absolute top-[20px] right-[4px] cursor-pointer lg:hidden" onClick={onClose}>
        <svg xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" width="30" height="30" viewBox="0 0 24 24" fill="currentColor">
          <path d="M 4.7070312 3.2929688 L 3.2929688 4.7070312 L 10.585938 12 L 3.2929688 19.292969 L 4.7070312 20.707031 L 12 13.414062 L 19.292969 20.707031 L 20.707031 19.292969 L 13.414062 12 L 20.707031 4.7070312 L 19.292969 3.2929688 L 12 10.585938 L 4.7070312 3.2929688 z"></path>
        </svg>
      </span> */}
      <ul className="relative flex flex-col justify-center h-full">
        <Item text="Introduction" href="https://landing.ubq.fi/en/"></Item>
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
      </ul>
    </div>
  );
}

const Item = ({ text, href }: { text: string; href: string }) => {
  return (
    <li className="relative cursor-pointer">
      <Link href={href}>
        <a
          className="flex items-center text-accent text-sm py-4 px-6 h-12 overflow-hidden text-ellipsis whitespace-nowrap rounded hover:bg-gray-100/20 transition duration-300 ease-in-out"
          target={href.match(/https?:\/\//) ? "_blank" : ""}
          data-mdb-ripple="true"
          data-mdb-ripple-color="dark"
        >
          <span>{text}</span>
        </a>
      </Link>
    </li>
  );
};
