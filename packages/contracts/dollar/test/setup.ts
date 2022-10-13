import { expect, use } from "chai";
import { waffle } from "hardhat";

const { solidity } = waffle;
use(solidity);

const { provider } = waffle;

export { expect, provider };
