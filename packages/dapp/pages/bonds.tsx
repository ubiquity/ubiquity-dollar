import { FC } from "react";

import dynamic from "next/dynamic";
const BondsContainer = dynamic(() => import("../components/bonds/app"), { ssr: false }); //@note Fix: (Hydration Error)

const Bonds: FC = (): JSX.Element => {
  return <BondsContainer />;
};

export default Bonds;
