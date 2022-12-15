/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
const INFURA_API_KEY= process.env.INFURA_KEY;
const GOERLI_PRIVATE_KEY= process.env.GOERLI_KEY;
const ETHERSCAN_API_KEY= process.env.API_KEY;
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
 networks: {
  goerli:{
    url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
    accounts: [GOERLI_PRIVATE_KEY]
  }
 },
 etherscan:{
  apiKey: ETHERSCAN_API_KEY,
 }
};
