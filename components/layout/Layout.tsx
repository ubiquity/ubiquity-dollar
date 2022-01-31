import { useState } from "react";
import Header from "../header/Header";
import Sidebar from "../sidebar/Sidebar";

type LayoutProps = {
  children: React.ReactNode;
};

export default function Layout({ children }: LayoutProps) {
  const [isOpened, setOpened] = useState(false);
  const toggleDrawer = () => {
    setOpened((prev) => !prev);
  };

  return (
    <div className="text-center flex flex-col min-h-screen">
      <Header toggleDrawer={toggleDrawer} />
      <div className="flex flex-1">
        <Sidebar isOpened={isOpened} />
        <div className={`p-[20px] ${isOpened ? "w-[80vw]" : "w-[100vw]"}`}>{children}</div>
      </div>
    </div>
  );
}
