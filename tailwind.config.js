module.exports = {
  corePlugins: {
    preflight: false,
  },
  content: ["components/**/*.tsx", "pages/**/*.tsx"],
  theme: {
    extend: {
      letterSpacing: {
        widest: ".17em",
      },
      colors: {
        accent: "#00ffff",
      },
      dropShadow: { light: "0 0 16px #fff" },
      fontFamily: {
        special: ["Ubiquity Nova", "Proxima Nova", "Avenir", "sans-serif"],
      },
    },
  },
};
