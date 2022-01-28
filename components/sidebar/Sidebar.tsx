type SidebarProps = {
  isOpened: boolean;
};
export default function Sidebar({ isOpened }: SidebarProps) {
  console.log(isOpened);
  return <div className={`${isOpened ? "w-[20vw]" : "w-[0vw]"} bg-white transition-[width 0.5s] overflow-hidden flex flex-col`}></div>;
}
