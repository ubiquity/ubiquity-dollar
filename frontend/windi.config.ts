import { defineConfig } from "windicss/helpers";

export default defineConfig({
  // This is a CSS reset, but using it breaks existing styles
  preflight: false,
  extract: {
    include: ["components/**/*.tsx", "pages/**/*.tsx"],
  },
  attributify: true,
  shortcuts: {},
  theme: {
    extend: {
      letterSpacing: {
        widest: ".2em",
      },
    },
  },
});
