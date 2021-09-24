import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();

import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'
//import '@nomiclabs/hardhat-waffle'
import "hardhat-deploy";

module.exports = {
  defaultNetwork: 'hardhat',
  networks: {
    hardhat: {
      chainId: 31337,
      gas: 12000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      timeout: 1800000,
      accounts: {
        mnemonic: "test test test test test test test test test test test junk",
        initialIndex: 0,
        count: 20,
        path: "m/44'/60'/0'/0",
        accountsBalance: "10000000000000000000000000",
      }
    },
    heco_main: {
      url: 'https://http-mainnet.hecochain.com',
      accounts: process.env.PRIKEY?[process.env.PRIKEY]:[],
    }
  },
  testnet: {
    url: 'https://data-seed-prebsc-1-s3.binance.org:8545',
    accounts: [process.env.BSC_TESTNET_PRIVATE_KEY],
  },
  mainnet: {
    url: 'https://bsc-dataseed3.ninicoin.io',
    accounts: [process.env.BSC_MAINNET_PRIVATE_KEY],
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  solidity: {
    version: '0.8.0',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "istanbul",
      outputSelection: {
        "*": {
          "": [
            "ast"
          ],
          "*": [
            "evm.bytecode.object",
            "evm.deployedBytecode.object",
            "abi",
            "evm.bytecode.sourceMap",
            "evm.deployedBytecode.sourceMap",
            "metadata"
          ]
        }
      },
    },
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
  },
  typechain: {
    outDir: './typechain',
    target: process.env.TYPECHAIN_TARGET || 'ethers-v5',
  },
};