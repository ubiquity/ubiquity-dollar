type SidebarProps = {
  isOpened: boolean;
};

export default function Sidebar({ isOpened }: SidebarProps) {
  return <div className={`${isOpened ? "w-[20vw]" : "w-[0vw]"} bg-white overflow-hidden flex flex-col`} style={{ transition: ".15s width ease-in-out" }}></div>;
}
