import "./styles/index.css";

export default function MyApp({ Component, pageProps }) {
  return (
    <>
    <h1>Ubiquity Dollar</h1>
      <Component {...pageProps} />
    </>
  );
}
