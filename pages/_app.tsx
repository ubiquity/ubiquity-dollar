/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import "./styles/index.css";
import "./styles/proxima.css";

import { ConnectedNetwork } from "../components/context/connected";
import { AppProps } from "next/app";
import Head from "next/head";

export default function Ubiquity({ Component, pageProps }: AppProps): JSX.Element {
  return (
    <>
      <Head>
        <link rel="apple-touch-icon" href="https://dao.ubq.fi/apple-touch-icon.png" />
        <title>Dashboard | Ubiquity Dollar</title>
        <link rel="icon" type="image/png" sizes="16x16" href="https://dao.ubq.fi/favicon-16x16.png" />
        <link rel="icon" type="image/png" sizes="32x32" href="https://dao.ubq.fi/favicon-32x32.png" />
        <link rel="icon" type="image/png" sizes="36x36" href="https://dao.ubq.fi/favicon-36x36.png" />
        <link rel="icon" type="image/png" sizes="48x48" href="https://dao.ubq.fi/favicon-48x48.png" />
        <link rel="icon" type="image/png" sizes="57x57" href="https://dao.ubq.fi/favicon-57x57.png" />
        <link rel="icon" type="image/png" sizes="60x60" href="https://dao.ubq.fi/favicon-60x60.png" />
        <link rel="icon" type="image/png" sizes="70x70" href="https://dao.ubq.fi/favicon-70x70.png" />
        <link rel="icon" type="image/png" sizes="72x72" href="https://dao.ubq.fi/favicon-72x72.png" />
        <link rel="icon" type="image/png" sizes="76x76" href="https://dao.ubq.fi/favicon-76x76.png" />
        <link rel="icon" type="image/png" sizes="96x96" href="https://dao.ubq.fi/favicon-96x96.png" />
        <link rel="icon" type="image/png" sizes="114x114" href="https://dao.ubq.fi/favicon-114x114.png" />
        <link rel="icon" type="image/png" sizes="120x120" href="https://dao.ubq.fi/favicon-120x120.png" />
        <link rel="icon" type="image/png" sizes="144x144" href="https://dao.ubq.fi/favicon-144x144.png" />
        <link rel="icon" type="image/png" sizes="150x150" href="https://dao.ubq.fi/favicon-150x150.png" />
        <link rel="icon" type="image/png" sizes="152x152" href="https://dao.ubq.fi/favicon-152x152.png" />
        <link rel="icon" type="image/png" sizes="180x180" href="https://dao.ubq.fi/favicon-180x180.png" />
        <link rel="icon" type="image/png" sizes="192x192" href="https://dao.ubq.fi/favicon-192x192.png" />
        <link rel="icon" type="image/png" sizes="310x310" href="https://dao.ubq.fi/favicon-310x310.png" />
        <link rel="icon" type="image/png" sizes="512x512" href="https://dao.ubq.fi/favicon-512x512.png" />
        <meta name="theme-color" content="#06061a" />
      </Head>
      <ConnectedNetwork>
        <>
          <Component {...pageProps} />
        </>
      </ConnectedNetwork>
    </>
  );
}
