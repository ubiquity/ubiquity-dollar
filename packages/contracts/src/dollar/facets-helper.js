const fs = require('fs');


function getFacetsName(facetsFolder, callback) {
  fs.readdirSync(facetsFolder, (err, files) => {
    if (err) {
      callback(err, null);
      return;
    }

    const fileNames = files.map(file => file.split('.')[0]);
    callback(null, fileNames);
  });
}

module.exports = {
  getFacetsName: getFacetsName
}