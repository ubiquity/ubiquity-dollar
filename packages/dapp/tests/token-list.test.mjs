import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import test from "node:test";

const readJson = (path) => JSON.parse(readFileSync(new URL(path, import.meta.url), "utf8"));
const tokenList = readJson("../public/token-list.json");

const findToken = (symbol) => {
  const token = tokenList.tokens.find((entry) => entry.symbol === symbol);
  assert.ok(token, `${symbol} must be present in the public list`);
  return token;
};

test("publishes versioned token-list metadata", () => {
  assert.ok(tokenList.name.length > 0 && tokenList.name.length <= 30);
  assert.equal(new Date(tokenList.timestamp).toISOString(), tokenList.timestamp);
  for (const part of ["major", "minor", "patch"]) {
    assert.ok(Number.isInteger(tokenList.version[part]) && tokenList.version[part] >= 0);
  }
  assert.ok(Array.isArray(tokenList.tokens) && tokenList.tokens.length > 0);
});

test("publishes valid, unique Ethereum token entries", () => {
  const identifiers = new Set();
  for (const token of tokenList.tokens) {
    assert.equal(token.chainId, 1);
    assert.match(token.address, /^0x[0-9a-fA-F]{40}$/);
    assert.notEqual(token.address.toLowerCase(), `0x${"0".repeat(40)}`);
    assert.ok(token.name.length > 0 && token.name.length <= 40);
    assert.ok(token.symbol.length > 0 && token.symbol.length <= 20);
    assert.ok(Number.isInteger(token.decimals) && token.decimals >= 0 && token.decimals <= 255);
    const identifier = `${token.chainId}:${token.address.toLowerCase()}`;
    assert.ok(!identifiers.has(identifier), `Duplicate token: ${identifier}`);
    identifiers.add(identifier);
  }
});

test("UUSD identifies the recorded mainnet dollar proxy, not its implementation or legacy uAD", () => {
  const deployment = readJson("../../contracts/broadcast/Deploy001_Diamond_Dollar_Governance.s.sol/1/run-latest.json");
  const implementation = deployment.transactions.find((tx) => tx.transactionType === "CREATE" && tx.contractName === "UbiquityDollarToken");
  assert.ok(implementation);
  const proxy = deployment.transactions.find(
    (tx) =>
      tx.transactionType === "CREATE" &&
      tx.contractName === "ERC1967Proxy" &&
      tx.arguments[0].toLowerCase() === implementation.contractAddress.toLowerCase()
  );
  assert.ok(proxy);
  const dollar = findToken("UUSD");
  assert.equal(dollar.chainId, Number(deployment.chain));
  assert.equal(dollar.address.toLowerCase(), proxy.contractAddress.toLowerCase());
  assert.notEqual(dollar.address.toLowerCase(), implementation.contractAddress.toLowerCase());
  assert.notEqual(dollar.address.toLowerCase(), "0x0f644658510c95cb46955e55d7ba9dda9e9fbec6");
  assert.equal(dollar.name, "Ubiquity Dollar");
  assert.equal(dollar.decimals, 18);
});

test("UBQ identifies the existing mainnet governance token", () => {
  const governance = findToken("UBQ");
  assert.equal(governance.address.toLowerCase(), "0x4e38d89362f7e5db0096ce44ebd021c3962aa9a0");
  assert.equal(governance.name, "Ubiquity");
  assert.equal(governance.decimals, 18);
});

test("allows cross-origin imports of the published token list", () => {
  const headers = readFileSync(new URL("../public/_headers", import.meta.url), "utf8");
  assert.match(headers, /^\/token-list\.json\r?\n[ \t]+Access-Control-Allow-Origin: \*$/m);
});
