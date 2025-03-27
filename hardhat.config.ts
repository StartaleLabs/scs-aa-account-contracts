import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import { HardhatUserConfig } from "hardhat/config";
import "hardhat-spdx-license-identifier";
import "hardhat-contract-sizer";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      evmVersion: "cancun",
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
      hardfork: "cancun"
    }
  },
  spdxLicenseIdentifier: {
    overwrite: false,
    runOnCompile: true
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: true,
  },
  paths: {
    sources: "./src", // Use src instead of contracts
    tests: "./test/hardhat", // Separate Hardhat tests
    cache: "./cache/hardhat", // Separate Hardhat cache
    artifacts: "./artifacts/hardhat", // Separate Hardhat artifacts
  },
};

export default config;
