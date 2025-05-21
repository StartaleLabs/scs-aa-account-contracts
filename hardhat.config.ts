import * as dotenv from "dotenv";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import { HardhatUserConfig } from "hardhat/config";
import "hardhat-spdx-license-identifier";
import "hardhat-contract-sizer";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.29",
    settings: {
      evmVersion: "prague",
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 499,
      },
    },
  },
  sourcify: {
    enabled: true,
  },
  networks: {
    hardhat: {
      chainId: 1337,
      hardfork: "prague"
    },
    minato: {
      url: process.env.MINATO_RPC_URL || "https://rpc.minato.network",
      chainId: 1946,
      accounts: [process.env.PRIVATE_KEY || ""],
      // gas: 30000000,
      // gasPrice: "auto"
    }
  },
  etherscan: {
    apiKey: {
      'soneium-minato': 'empty'
    },
    customChains: [
      {
        network: "soneium-minato",
        chainId: 1946,
        urls: {
          apiURL: "https://soneium-minato.blockscout.com/api",
          browserURL: "https://soneium-minato.blockscout.com"
        }
      }
    ]
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
