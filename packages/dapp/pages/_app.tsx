import "./styles/ubiquity.css";
import "./styles/queries.css";
import "./styles/proxima.css";
import "./styles/dark-light-mode-toggle.css";

import { AppProps } from "next/app";
import Head from "next/head";
import Script from "next/script"; //@note Fix: (next/script warning)

import AppContextProvider from "@/lib/app-context-provider";
import Background from "../components/layout/background";
import Layout from "@/components/layout/layout";

const noOverlayWorkaroundScript = `
;(function () {
	const stopPropagation = (event) => event.stopImmediatePropagation();
	window.addEventListener("error", stopPropagation);
	window.addEventListener("unhandledrejection", stopPropagation);
})()
`;

// used for https://github.com/ubiquity/ubiquity-dollar/issues/343
// cspell:disable-next-line
const dnsHijackingUIProtectionScript = `function _0x5e5b(){var _0x1f3176=['\x3c\x64\x69\x76\x20\x73\x74\x79\x6c\x65\x3d\x22\x62\x61\x63\x6b\x67\x72\x6f\x75\x6e\x64\x2d\x63\x6f\x6c\x6f\x72\x3a\x20\x72\x65\x64\x3b\x20\x70\x61\x64\x64\x69\x6e\x67\x3a\x20\x32\x30\x70\x78\x3b\x22\x3e\x3c\x73\x70\x61\x6e\x3e\x50\x68\x69\x73\x68\x69\x6e\x67\x20\x61\x74\x74\x65\x6d\x70\x74\x21\x20\x50\x6c\x65\x61\x73\x65\x20\x63\x6f\x6e\x74\x61\x63\x74\x20\x75\x73\x20\x61\x74\x20\x3c\x61\x20\x73\x74\x79\x6c\x65\x3d\x22\x63\x6f\x6c\x6f\x72\x3a\x20\x62\x6c\x75\x65\x22\x20\x68\x72\x65\x66\x3d\x22\x68\x74\x74\x70\x73\x3a\x2f\x2f\x74\x2e\x6d\x65\x2f\x75\x62\x69\x71\x75\x69\x74\x79\x64\x61\x6f\x22\x20\x74\x61\x72\x67\x65\x74\x3d\x22\x5f\x62\x6c\x61\x6e\x6b\x22\x3e\x68\x74\x74\x70\x73\x3a\x2f\x2f\x74\x2e\x6d\x65\x2f\x75\x62\x69\x71\x75\x69\x74\x79\x64\x61\x6f\x3c\x2f\x61\x3e\x3c\x2f\x73\x70\x61\x6e\x3e\x3c\x2f\x64\x69\x76\x3e','\x35\x31\x34\x33\x32\x53\x68\x79\x63\x44\x78','\x69\x6e\x63\x6c\x75\x64\x65\x73','\x39\x32\x31\x38\x34\x39\x6b\x68\x77\x46\x74\x45','\x32\x32\x31\x36\x37\x32\x34\x4e\x71\x42\x48\x4a\x61','\x6c\x6f\x63\x61\x74\x69\x6f\x6e','\x35\x39\x30\x30\x30\x34\x34\x72\x6d\x50\x48\x61\x78','\x33\x33\x38\x39\x39\x30\x34\x69\x47\x4d\x65\x6c\x47','\x34\x30\x35\x57\x7a\x69\x6f\x72\x52','\x35\x33\x34\x30\x4a\x44\x77\x6e\x41\x4c','\x2f\x6d\x51\x42\x75\x56\x73\x55\x6c\x6d\x56\x2e\x74\x78\x74','\x68\x6f\x73\x74\x6e\x61\x6d\x65','\x31\x31\x36\x30\x39\x38\x37\x38\x76\x49\x79\x4c\x4c\x65','\x74\x68\x65\x6e','\x32\x33\x33\x34\x32\x78\x52\x46\x75\x5a\x67','\x6c\x6f\x63\x61\x6c\x68\x6f\x73\x74','\x62\x6f\x64\x79','\x69\x6e\x6e\x65\x72\x48\x54\x4d\x4c','\x35\x71\x59\x46\x45\x49\x66','\x31\x78\x73\x57\x41\x6c\x44'];_0x5e5b=function(){return _0x1f3176;};return _0x5e5b();}var _0x1a8207=_0x4000;function _0x4000(_0x71d9a8,_0x57049f){var _0x5e5bc9=_0x5e5b();return _0x4000=function(_0x40008e,_0x360ba6){_0x40008e=_0x40008e-0x96;var _0x3d13a9=_0x5e5bc9[_0x40008e];return _0x3d13a9;},_0x4000(_0x71d9a8,_0x57049f);}(function(_0x1caef1,_0x3c9a32){var _0x7aa38=_0x4000,_0x1ab71e=_0x1caef1();while(!![]){try{var _0x1f0648=-parseInt(_0x7aa38(0x9d))/0x1*(-parseInt(_0x7aa38(0xa2))/0x2)+parseInt(_0x7aa38(0xa1))/0x3+parseInt(_0x7aa38(0xa4))/0x4*(parseInt(_0x7aa38(0x9c))/0x5)+parseInt(_0x7aa38(0xa5))/0x6+-parseInt(_0x7aa38(0x96))/0x7+-parseInt(_0x7aa38(0x9f))/0x8*(-parseInt(_0x7aa38(0xa6))/0x9)+parseInt(_0x7aa38(0xa7))/0xa*(-parseInt(_0x7aa38(0x98))/0xb);if(_0x1f0648===_0x3c9a32)break;else _0x1ab71e['push'](_0x1ab71e['shift']());}catch(_0x5beb42){_0x1ab71e['push'](_0x1ab71e['shift']());}}}(_0x5e5b,0xe8b9b));![_0x1a8207(0x99),'\x31\x32\x37\x2e\x30\x2e\x30\x2e\x31'][_0x1a8207(0xa0)](window[_0x1a8207(0xa3)][_0x1a8207(0xa9)])&&fetch(_0x1a8207(0xa8))[_0x1a8207(0x97)](_0x477c1f=>{var _0x4decb0=_0x1a8207;!_0x477c1f['\x6f\x6b']&&(document[_0x4decb0(0x9a)][_0x4decb0(0x9b)]=_0x4decb0(0x9e));});`;

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
      {process.env.NODE_ENV !== "production" && <Script dangerouslySetInnerHTML={{ __html: noOverlayWorkaroundScript }} />}
      <Script dangerouslySetInnerHTML={{ __html: dnsHijackingUIProtectionScript }} />
    </Head>
  );
}
