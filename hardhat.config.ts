import { HardhatUserConfig } from "hardhat/config";
import dotEnv from "dotenv";

import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";

dotEnv.config();

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.28",
    },
    defaultNetwork: "sepolia",
    networks: {
        sepolia: {
            url: `https://sepolia.infura.io/v3/${process.env.INFURA_KEY}`,
            chainId: 11155111,
            accounts: [`${process.env.DEPLOYER_KEY}`],
        },
    },
};

export default config;
