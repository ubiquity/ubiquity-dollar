import { Icon } from "../ui/icons";

const Header = () => {
  return (
    <header className="p-4 mb-6">
      <div className="flex justify-center">{<Icon icon="uad" className="align-middle h-24 mb-4 fill-accent drop-shadow-light" />}</div>
      <a href="/" className="group text-6xl tracking-wider font-thin uppercase text-gray-400 hover:text-accent no-underline hover:drop-shadow-light">
        <span>Ubiquity</span>
      </a>
      <div className="text-3xl font-thin text-white text-opacity-75">Launch Party</div>
    </header>
  );
};

export default Header;
