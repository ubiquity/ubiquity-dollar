const PROD = process.env.NODE_ENV == "production";

export default function Background() {
  return (
    <div id="Background">
      {/* {video} */}
      <div id="color"></div>
      <div id="grid"></div>
    </div>
  );
  // <GridVideoBg />;
}
function GridVideoBg() {
  const video = (
    <video autoPlay muted loop playsInline>
      {PROD && <source src="ubiquity-one-fifth-speed-trimmed-compressed.mp4" type="video/mp4" />}
    </video>
  );

  return (
    <div id="Background">
      {video}
      <div id="grid"></div>
    </div>
  );
}
