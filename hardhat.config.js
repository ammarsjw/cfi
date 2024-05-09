require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("@openzeppelin/hardhat-upgrades");

module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.8.22",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000,
                    },
                },
            },
        ],
    },
    networks: {
        goerli: {
            url: process.env.URL_GOERLI,
            accounts: [process.env.PRIVATE_KEY_GOERLI],
        },
        sepolia: {
            url: process.env.URL_SEPOLIA,
            accounts: [process.env.PRIVATE_KEY_SEPOLIA],
        },
        bsc: {
            url: process.env.URL_BSC,
            accounts: [process.env.PRIVATE_KEY_BSC],
        },
    },
    etherscan: {
        apiKey: {
            goerli: process.env.BLOCK_EXPLORER_API_KEY_ETHEREUM,
            sepolia: process.env.BLOCK_EXPLORER_API_KEY_ETHEREUM,
            bsc: process.env.BLOCK_EXPLORER_API_KEY_BSC,
        },
    },
};
