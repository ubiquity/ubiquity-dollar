/* eslint-disable @typescript-eslint/no-var-requires */
// const path = require("path");

module.exports = {
  output: "standalone",
  env: {
    GIT_COMMIT_REF: require("child_process").execSync("git rev-parse --short HEAD").toString().trim(),
  },
  // experimental: {
  // packages/dapp/next.config.js
  // outputFileTracingRoot: path.join(__dirname, "..", ".."),
  // turbotrace: {
  // control the log level of the turbotrace, default is `error`
  // logLevel?:
  // | 'bug'
  //   | 'fatal'
  //   | 'error'
  //   | 'warning'
  //   | 'hint'
  //   | 'note'
  //   | 'suggestions'
  //   | 'info',
  // control if the log of turbotrace should contain the details of the analysis, default is `false`
  // logDetail: true,
  // show all log messages without limit
  // turbotrace only show 1 log message for each categories by default
  // logAll: true,
  // control the context directory of the turbotrace
  // files outside of the context directory will not be traced
  // set the `experimental.outputFileTracingRoot` has the same effect
  // if the `experimental.outputFileTracingRoot` and this option are both set, the `experimental.turbotrace.contextDirectory` will be used
  // contextDirectory?: string
  // if there is `process.cwd()` expression in your code, you can set this option to tell `turbotrace` the value of `process.cwd()` while tracing.
  // for example the require(process.cwd() + '/package.json') will be traced as require('/path/to/cwd/package.json')
  // processCwd?: string,
  // control the maximum number of files that are passed to the `turbotrace`
  // default is 128
  // maxFiles?: number;
  // },
  // },
};
