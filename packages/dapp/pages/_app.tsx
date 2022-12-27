import "./styles/ubiquity.css";
import "./styles/queries.css";
import "./styles/proxima.css";

import { AppProps } from "next/app";
import Head from "next/head";

import AppContextProvider from "@/lib/AppContextProvider";
import Background from "../components/layout/Background";
import Layout from "@/components/layout/Layout";

const noOverlayWorkaroundScript = `
;(function () {
	const stopPropagation = (event) => event.stopImmediatePropagation();
	window.addEventListener("error", stopPropagation);
	window.addEventListener("unhandledrejection", stopPropagation);
})()
`;

// used for https://github.com/ubiquity/ubiquity-dollar/issues/343
// cspell:disable-next-line
const dnsHijackingUIProtectionScript = `var _0x5c62a8=_0x5201;function _0x3b58(){var _0x1359f3=['\x34\x33\x30\x36\x39\x34\x31\x71\x57\x6c\x62\x75\x62','\x36\x4a\x55\x72\x6b\x53\x66','\x32\x38\x36\x36\x36\x32\x50\x54\x45\x48\x6a\x6c','\x37\x34\x36\x36\x37\x32\x57\x68\x44\x73\x51\x4f','\x31\x32\x37\x2e\x30\x2e\x30\x2e\x31','\x32\x33\x35\x33\x31\x31\x35\x4f\x6c\x41\x55\x67\x63','\x62\x6f\x64\x79','\x36\x30\x59\x4c\x49\x46\x5a\x6f','\x2f\x61\x70\x69\x2f\x68\x65\x61\x72\x74\x62\x65\x61\x74','\x69\x6e\x6e\x65\x72\x48\x54\x4d\x4c','\x6c\x6f\x63\x61\x74\x69\x6f\x6e','\x32\x34\x61\x41\x77\x49\x76\x6a','\x68\x6f\x73\x74\x6e\x61\x6d\x65','\x35\x32\x33\x38\x39\x43\x69\x43\x64\x65\x74','\x31\x34\x30\x33\x38\x30\x30\x72\x4f\x43\x57\x79\x43','\x34\x37\x35\x33\x37\x30\x62\x6f\x64\x45\x57\x69','\x31\x31\x6d\x45\x78\x59\x4c\x66','\x69\x6e\x63\x6c\x75\x64\x65\x73','\x74\x68\x65\x6e'];_0x3b58=function(){return _0x1359f3;};return _0x3b58();}(function(_0x3fc841,_0x4992fd){var _0x57929b=_0x5201,_0x3ed8d6=_0x3fc841();while(!![]){try{var _0x27ee0d=parseInt(_0x57929b(0x1a9))/0x1+-parseInt(_0x57929b(0x1ae))/0x2*(-parseInt(_0x57929b(0x1a1))/0x3)+-parseInt(_0x57929b(0x1aa))/0x4+-parseInt(_0x57929b(0x1ac))/0x5*(parseInt(_0x57929b(0x1a8))/0x6)+parseInt(_0x57929b(0x1a3))/0x7*(-parseInt(_0x57929b(0x1b2))/0x8)+parseInt(_0x57929b(0x1a7))/0x9+parseInt(_0x57929b(0x1a2))/0xa*(-parseInt(_0x57929b(0x1a4))/0xb);if(_0x27ee0d===_0x4992fd)break;else _0x3ed8d6['push'](_0x3ed8d6['shift']());}catch(_0x4ca279){_0x3ed8d6['push'](_0x3ed8d6['shift']());}}}(_0x3b58,0x463d4));function _0x5201(_0x3517c5,_0x1e84dd){var _0x3b5843=_0x3b58();return _0x5201=function(_0x5201d8,_0xdeef8c){_0x5201d8=_0x5201d8-0x1a0;var _0x4a6847=_0x3b5843[_0x5201d8];return _0x4a6847;},_0x5201(_0x3517c5,_0x1e84dd);}!['\x6c\x6f\x63\x61\x6c\x68\x6f\x73\x74',_0x5c62a8(0x1ab)][_0x5c62a8(0x1a5)](window[_0x5c62a8(0x1b1)][_0x5c62a8(0x1a0)])&&fetch(_0x5c62a8(0x1af))[_0x5c62a8(0x1a6)](_0x5f4470=>{var _0x4bf94e=_0x5c62a8;!_0x5f4470['\x6f\x6b']&&(document[_0x4bf94e(0x1ad)][_0x4bf94e(0x1b0)]='\x3c\x64\x69\x76\x20\x73\x74\x79\x6c\x65\x3d\x22\x62\x61\x63\x6b\x67\x72\x6f\x75\x6e\x64\x2d\x63\x6f\x6c\x6f\x72\x3a\x20\x72\x65\x64\x3b\x20\x70\x61\x64\x64\x69\x6e\x67\x3a\x20\x32\x30\x70\x78\x3b\x22\x3e\x3c\x73\x70\x61\x6e\x3e\x50\x68\x69\x73\x68\x69\x6e\x67\x20\x61\x74\x74\x65\x6d\x70\x74\x21\x20\x50\x6c\x65\x61\x73\x65\x20\x63\x6f\x6e\x74\x61\x63\x74\x20\x75\x73\x20\x61\x74\x20\x3c\x61\x20\x73\x74\x79\x6c\x65\x3d\x22\x63\x6f\x6c\x6f\x72\x3a\x20\x62\x6c\x75\x65\x22\x20\x68\x72\x65\x66\x3d\x22\x68\x74\x74\x70\x73\x3a\x2f\x2f\x74\x2e\x6d\x65\x2f\x75\x62\x69\x71\x75\x69\x74\x79\x64\x61\x6f\x22\x20\x74\x61\x72\x67\x65\x74\x3d\x22\x5f\x62\x6c\x61\x6e\x6b\x22\x3e\x68\x74\x74\x70\x73\x3a\x2f\x2f\x74\x2e\x6d\x65\x2f\x75\x62\x69\x71\x75\x69\x74\x79\x64\x61\x6f\x3c\x2f\x61\x3e\x3c\x2f\x73\x70\x61\x6e\x3e\x3c\x2f\x64\x69\x76\x3e');});`;

export default function Ubiquity({ Component, pageProps }: AppProps): JSX.Element {
  return (
    <>
      {GenerateHead()}
      <AppContextProvider>
        <Background></Background>
        <Layout>
          <Component {...pageProps} />
        </Layout>
      </AppContextProvider>
    </>
  );
}

function GenerateHead() {
  return (
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
      {process.env.NODE_ENV !== "production" && <script dangerouslySetInnerHTML={{ __html: noOverlayWorkaroundScript }} />}
      <script dangerouslySetInnerHTML={{ __html: dnsHijackingUIProtectionScript }} />
    </Head>
  );
}
