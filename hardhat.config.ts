import * as dotenv from "dotenv";
import { HardhatUserConfig, task } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import './tasks'

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000
      },
      viaIR: true,
    }
  },
  paths: {
    sources: "./contracts",
  },
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      gas: 10000000
    },
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts: [process.env.PRIVATE_KEY_OWNER as string, process.env.PRIVATE_KEY_ADMIN as string]
    }
  },
  mocha: {
    timeout: 100000000
  }
};

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();
  const provider = hre.ethers.provider;

  for (const account of accounts) {
      const wei = await provider.getBalance(account.address)
      console.log("%s (%d ETH)", account.address, hre.ethers.utils.formatEther(wei));
  }
});

export default config;
