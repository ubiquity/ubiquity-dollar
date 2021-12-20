module.exports = {
  corePlugins: {
    preflight: false,
  },
  content: ["components/**/*.tsx", "pages/**/*.tsx"],
  theme: {
    extend: {
      letterSpacing: {
        widest: ".2em",
      },
      colors: {
        accent: "#00ffff",
      },
    },
  },
};
