/* eslint-disable @typescript-eslint/explicit-module-boundary-types */
import "./styles/index.css";

export default function MyApp({ Component, pageProps }): JSX.Element {
  return (
    <>
      <h1>Ubiquity Dollar</h1>
      <Component {...pageProps} />
    </>
  );
}
