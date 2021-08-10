/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import "./styles/index.css";
import "./styles/proxima.css";
import "windi.css";

import { ConnectedNetwork } from "../components/context/connected";
import { AppProps } from "next/app";

export default function MyApp({ Component, pageProps }: AppProps): JSX.Element {
  return (
    <ConnectedNetwork>
      <>
        <Component {...pageProps} />
      </>
    </ConnectedNetwork>
  );
}
