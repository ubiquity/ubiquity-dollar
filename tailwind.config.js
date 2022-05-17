module.exports = {
  corePlugins: {
    preflight: true,
  },
  content: ["components/**/*.tsx", "pages/**/*.tsx"],
  theme: {
    extend: {
      fontSize: {
        "2xs": "0.6rem",
      },
      letterSpacing: {
        widest: ".17em",
      },
      colors: {
        accent: "#00ffff",
        paper: "#131326",
      },
      dropShadow: { light: "0 0 16px #fff", accent: "0 0 16px #0FF" },
      fontFamily: {
        special: ["Ubiquity Nova", "Proxima Nova", "Avenir", "sans-serif"],
      },
    },
  },
};
