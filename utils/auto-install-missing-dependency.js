/* eslint-disable no-undef */
/* eslint-disable no-global-assign */
/* eslint-disable @typescript-eslint/ban-ts-comment */
// @ts-nocheck
(function () {
  var r = require;
  require = function (n) {
    try {
      return r(n);
    } catch (e) {
      console.log(`Module "${n}" was not found and will be installed`);
      r("child_process").exec(`npm i ${n}`, function (err, body) {
        if (err) {
          console.log(`Module "${n}" could not be installed. Try again or install manually`);
          console.log(body);
          exit(1);
        } else {
          console.log(`Module "${n}" was installed. Will try to require again`);
          try {
            return r(n);
          } catch (e) {
            console.log(`Module "${n}" could not be required. Please restart the app`);
            console.log(e);
            exit(1);
          }
        }
      });
    }
  };
})();
