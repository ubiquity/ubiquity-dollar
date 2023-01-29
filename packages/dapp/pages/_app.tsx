import "./styles/ubiquity.css";
import "./styles/queries.css";
import "./styles/proxima.css";

import { AppProps } from "next/app";
import Background from "@/components/Background";
import Layout from "@/components/Layout";

export default function UbiquityDollarDApp({ Component, pageProps }: AppProps) {
  return (
    <>
      <Background />
      <Layout>
        <Component {...pageProps} />
      </Layout>
    </>
  );
}
