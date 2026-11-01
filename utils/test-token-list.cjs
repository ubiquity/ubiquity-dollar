const assert = require("node:assert/strict");
const { readFileSync } = require("node:fs");
const path = require("node:path");
const { test } = require("node:test");

const root = path.resolve(__dirname, "..");
const tokenList = require("../packages/dapp/public/token-list.json");

test("includes the canonical Ethereum mainnet UUSD and UBQ metadata", () => {
  const expectedTokens = [
    ["UUSD", "0xb6919Ef2ee4aFC163BC954C5678e2BB570c2D103", "Ubiquity Dollar"],
    ["UBQ", "0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0", "Ubiquity"],
  ];
  for (const [symbol, address, name] of expectedTokens) {
    const token = tokenList.tokens.find((entry) => entry.chainId === 1 && entry.symbol === symbol);
    assert.ok(token, `Missing ${symbol} on Ethereum mainnet`);
    assert.equal(token.address, address);
    assert.equal(token.name, name);
    assert.equal(token.decimals, 18);
  }
});

test("provides a versioned token-list document", () => {
  assert.ok(tokenList.name.length > 0 && tokenList.name.length <= 30);
  assert.equal(new Date(tokenList.timestamp).toISOString(), tokenList.timestamp);
  for (const component of ["major", "minor", "patch"]) {
    assert.ok(Number.isInteger(tokenList.version[component]) && tokenList.version[component] >= 0);
  }
  assert.ok(tokenList.tokens.length >= 2);
});

test("has valid, unique token entries with repository-hosted logos", () => {
  const keys = new Set();
  const logoPrefix = "/ubiquity/ubiquity-dollar/development/";

  for (const token of tokenList.tokens) {
    assert.ok(Number.isInteger(token.chainId) && token.chainId > 0);
    assert.match(token.address, /^0x[\da-fA-F]{40}$/);
    assert.ok(token.name.length > 0 && token.name.length <= 40);
    assert.ok(token.symbol.length > 0 && token.symbol.length <= 20);
    assert.ok(Number.isInteger(token.decimals) && token.decimals >= 0 && token.decimals <= 255);

    const key = `${token.chainId}:${token.address.toLowerCase()}`;
    assert.ok(!keys.has(key), `Duplicate token: ${key}`);
    keys.add(key);

    const logo = new URL(token.logoURI);
    assert.equal(logo.protocol, "https:");
    assert.equal(logo.hostname, "raw.githubusercontent.com");
    assert.ok(logo.pathname.startsWith(logoPrefix));
    const logoPath = path.join(root, logo.pathname.slice(logoPrefix.length));
    assert.ok(readFileSync(logoPath).length > 0, `Missing logo for ${token.symbol}`);
  }
});
