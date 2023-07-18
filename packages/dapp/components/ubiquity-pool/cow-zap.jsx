import { ethers } from "ethers";
import useWeb3 from "../lib/hooks/use-web-3";

const { walletAddress, signer } = useWeb3();

const LUSD = new ethers.Contract(
  "0x5f98805A4E8be255a32880FDeC7F6728C6568bA0",
  [
    "function decimals() view returns (uint8)",
    "function name() view returns (string)",
    "function version() view returns (string)",
    "function nonces(address owner) view returns (string)",
    `function permit(
      address owner,
      address spender,
      uint256 value,
      uint256 deadline,
      uint8 v,
      bytes32 r,
      bytes32 s
    )`,
  ],
  signer
);

const SETTLEMENT = new ethers.Contract("0x9008D19f58AAbD9eD0D60971565AA8510560ab41", [], signer);

const VAULT_RELAYER = new ethers.Contract("0xC92E8bdf79f0507f65a392b0ab4667716BFE0110", [], signer);

const chainId = await signer?.getChainId();

async function cowZap(sellToken, sellAmount, minterAddress) {
  const Token = new ethers.Contract(
    sellToken,
    [
      "function decimals() view returns (uint8)",
      "function name() view returns (string)",
      "function version() view returns (string)",
      "function nonces(address owner) view returns (string)",
      `function permit(
      address owner,
      address spender,
      uint256 value,
      uint256 deadline,
      uint8 v,
      bytes32 r,
      bytes32 s
    )`,
    ],
    signer
  );

  const MINTER = new ethers.Contract(
    minterAddress,
    [`function getAccountAddress(address user) view returns (address)`, `function mintAll(address user view returns (address))`],
    signer
  );

  const orderConfig = {
    sellToken: Token.address,
    buyToken: LUSD.address,
    sellAmount: sellAmount,
    type: "sell",
    partiallyFillable: false,
    sellTokenBalance: "erc20",
    buyTokenBalance: "erc20",
    receiver: "",
    appData: JSON.stringify({
      backend: {
        hooks: {
          pre: [permitHook],
          post: [bridgeHook],
        },
      },
    }),
  };

  const permit = {
    owner: walletAddress,
    spender: VAULT_RELAYER.address,
    value: orderConfig.sellAmount,
    nonce: await Token.nonces(walletAddress),
    deadline: ethers.constants.MaxUint256,
  };

  const permitSignature = ethers.utils.splitSignature(
    await signer?._signTypedData(
      {
        name: await Token.name(),
        version: await Token.version(),
        chainId,
        verifyingContract: Token.address,
      },
      {
        Permit: [
          { name: "owner", type: "address" },
          { name: "spender", type: "address" },
          { name: "value", type: "uint256" },
          { name: "nonce", type: "uint256" },
          { name: "deadline", type: "uint256" },
        ],
      },
      permit
    )
  );

  const permitParams = [permit.owner, permit.spender, permit.value, permit.deadline, permitSignature.v, permitSignature.r, permitSignature.s];
  const permitHook = {
    target: Token.address,
    callData: Token.interface.encodeFunctionData("permit", permitParams),
    gasLimit: `${await Token.estimateGas.permit(...permitParams)}`,
  };

  orderConfig.receiver = await MINTER.getAccountAddress(walletAddress);
  const bridgeHook = {
    target: MINTER.address,
    callData: MINTER.interface.encodeFunctionData("mintAll", [walletAddress, LUSD.address]),
    // Approximate gas limit determined with Tenderly.
    gasLimit: "228533",
  };
  console.log("bridge hook:", bridgeHook);

  /*** Order Creation ***/

  orderConfig.appData = JSON.stringify({
    backend: {
      hooks: {
        pre: [permitHook],
        post: [bridgeHook],
      },
    },
  });
  const { id: quoteId, quote } = await fetch("https://barn.api.cow.fi/mainnet/api/v1/quote", {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      from: walletAddress,
      sellAmountBeforeFee: orderConfig.sellAmount,
      ...orderConfig,
    }),
  }).then((response) => response.json());
  console.log("quote:", quoteId, quote);

  const orderData = {
    ...orderConfig,
    sellAmount: quote.sellAmount,
    buyAmount: `${ethers.BigNumber.from(quote.buyAmount).mul(99).div(100)}`,
    validTo: quote.validTo,
    appData: ethers.utils.id(orderConfig.appData),
    feeAmount: quote.feeAmount,
  };
  const orderSignature = await signer._signTypedData(
    {
      name: "Gnosis Protocol",
      version: "v2",
      chainId,
      verifyingContract: SETTLEMENT.address,
    },
    {
      Order: [
        { name: "sellToken", type: "address" },
        { name: "buyToken", type: "address" },
        { name: "receiver", type: "address" },
        { name: "sellAmount", type: "uint256" },
        { name: "buyAmount", type: "uint256" },
        { name: "validTo", type: "uint32" },
        { name: "appData", type: "bytes32" },
        { name: "feeAmount", type: "uint256" },
        { name: "kind", type: "string" },
        { name: "partiallyFillable", type: "bool" },
        { name: "sellTokenBalance", type: "string" },
        { name: "buyTokenBalance", type: "string" },
      ],
    },
    orderData
  );

  const orderUid = await fetch("https://barn.api.cow.fi/mainnet/api/v1/orders", {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({
      ...orderData,
      from: walletAddress,
      appData: orderConfig.appData,
      appDataHash: orderData.appData,
      signingScheme: "eip712",
      signature: orderSignature,
      quoteId,
    }),
  }).then((response) => response.json());
  console.log("order:", orderUid);
}

export default cowZap;
