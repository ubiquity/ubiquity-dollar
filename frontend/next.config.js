const WindiCSS = require("windicss-webpack-plugin").default;

module.exports = {
  webpack: (config) => {
    config.plugins.push(new WindiCSS());
    return config;
  },
  future: {
    webpack5: true,
  },
};
