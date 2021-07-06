/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import "./styles/utility.css";
import "./styles/index.css";
import "./styles/proxima.css";

import { ConnectedNetwork } from "../components/context/connected";
type MyComponentProps = React.PropsWithChildren<{
  Component: any;
  pageProps: any;
}>;

export default function MyApp({
  Component,
  pageProps,
}: MyComponentProps): JSX.Element {
  return (
    <ConnectedNetwork>
      <>
        <Component {...pageProps} />
      </>
    </ConnectedNetwork>
  );
}
