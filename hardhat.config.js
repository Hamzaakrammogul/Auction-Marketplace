/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
module.exports = {
 solidity: {
  compilers: [
    {
      version: "0.8.17",
    },
    {
      version: "0.4.26",
      settings: {},
    },
  ],
 },
};
