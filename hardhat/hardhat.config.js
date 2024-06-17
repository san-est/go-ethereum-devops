require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    devnet: {
      url: "http://172.19.0.1:8545",
    },
  },
};
