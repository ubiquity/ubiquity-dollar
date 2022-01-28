type HeaderProps = {
  isOpened: boolean;
  toggleDrawer: () => void;
};

export default function Header({ isOpened, toggleDrawer }: HeaderProps) {
  return (
    <header className="flex h-[50px] items-center justify-center">
      <div className="p-[10px]" onClick={toggleDrawer}>
        {isOpened ? <span className="h-[30px]">Opened</span> : <span className="h-[30px]">Closed</span>}
      </div>
      <div className="m-auto">Header</div>
    </header>
  );
}
