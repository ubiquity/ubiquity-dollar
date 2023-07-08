const fs = require('fs');


function getFacetsName(facetsFolder, callback) {
  fs.readdir(facetsFolder, (err, files) => {
    if (err) {
      callback(err, null);
      return;
    }

    const fileNames = files.map(file => file.split('.')[0]);
    return callback(null, fileNames);
  });
}

module.exports = {
  getFacetsName: getFacetsName
}