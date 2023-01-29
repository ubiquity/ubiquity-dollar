/* eslint-disable @typescript-eslint/no-var-requires */
module.exports = {
  env: {
    GIT_COMMIT_REF: require("child_process").execSync("git rev-parse --short HEAD").toString().trim(),
  },
};
