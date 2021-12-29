import { FC } from "react";
import App from "../components/launch-party/App";

const Monitor: FC = (): JSX.Element => {
  return (
    <div>
      <div className="fixed h-screen w-screen z-10">
        <div id="grid"></div>
      </div>
      <div className="relative z-20">
        <App />
      </div>
    </div>
  );
};

export default Monitor;
