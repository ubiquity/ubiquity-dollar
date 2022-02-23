import { useState, useEffect, useCallback } from "react";
import Header from "../header/Header";
import Sidebar from "../sidebar/Sidebar";
import Footer from "../footer/Footer";

type LayoutProps = {
  children: React.ReactNode;
};

export default function Layout({ children }: LayoutProps) {
  const [isOpened, setOpened] = useState(false);
  const toggleDrawer = () => {
    setOpened((prev) => !prev);
  };

  const handleKeyDown = useCallback((event) => {
    if (event.key === "Escape") {
      setOpened(false);
    }
  }, []);

  useEffect(() => {
    document.addEventListener("keydown", handleKeyDown, false);

    return () => {
      document.removeEventListener("keydown", handleKeyDown, false);
    };
  }, []);

  return (
    <div className="text-center flex flex-col min-h-screen">
      <Header toggleDrawer={toggleDrawer} isOpened={isOpened} />
      <div className="flex flex-1">
        <Sidebar isOpened={isOpened} onClose={toggleDrawer} />
        <div className="p-[20px] w-[100vw]">{children}</div>
      </div>
      <Footer />
    </div>
  );
}
