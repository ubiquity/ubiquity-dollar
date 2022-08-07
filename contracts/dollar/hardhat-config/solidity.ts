import HardhatUserConfig from 'hardhat/types';
export default {
  compilers: [
    {
      version: "0.8.3",
      settings: {
        optimizer: {
          enabled: true,
          runs: 800,
        },
        metadata: {
          // do not include the metadata hash, since this is machine dependent
          // and we want all generated code to be deterministic
          // https://docs.soliditylang.org/en/v0.7.6/metadata.html
          bytecodeHash: "none",
        },
      },
    },
  ]
} as HardhatUserConfig.SolidityConfig
