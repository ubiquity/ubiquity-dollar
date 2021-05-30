import "./styles/index.css";

// This default export is required in a new `pages/_app.js` file.
export default function MyApp({ Component, pageProps }) {
  return (
    <>
    <h1>Ubiquity Dollar</h1>
      <Component {...pageProps} />
    </>
  );
}
