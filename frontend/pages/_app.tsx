/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import "./styles/index.css";
import { ConnectedNetwork } from "./context/connected";
export default function MyApp({ Component, pageProps }): JSX.Element {
  return (
    <ConnectedNetwork>
      <>
        <h1>Ubiquity Dollar</h1>
        <Component {...pageProps} />
      </>
    </ConnectedNetwork>
  );
}
