import "../styles/ubiquity.css";
import "../styles/queries.css";
import "../styles/proxima.css";

import { AppProps } from "next/app";
import Background from "@/components/Background";
import Foreground from "@/components/Foreground";

export default function UbiquityDollarDApp({ Component, pageProps }: AppProps) {
  return (
    <>
      <Background />
      <Foreground>
        <Component {...pageProps} />
      </Foreground>
    </>
  );
}
