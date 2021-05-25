#!/usr/bin/env node

const args = process.argv.slice(2);

const fs = require("fs");
const path = require("path");

// console.log({
//     "process.cwd()": process.cwd(),
//     "path.resolve(deployment)": path.resolve(args[0])
// });

const deployment = require(path.resolve(args[0]));

try {
    const localhost = deployment[31337].localhost;
    fs.writeFileSync(path.resolve(args[1]), JSON.stringify(localhost));
} catch (e) {
    console.error(e);
    process.exit(1);
}

process.exit(0);