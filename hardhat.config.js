/** @type import('hardhat/config').HardhatUserConfig */
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
const INFURA_API_KEY= process.env.INFURA_KEY;
const WALLET_PRIVATE_KEY= process.env.WALLET_KEY;
const ETHERSCAN_API_KEY= process.env.ETHEREUM_KEY;
const POLYGONSCAN_API_KEY= process.env.POLYGON_KEY;
module.exports = {
 solidity: {
  compilers: [
    {
      version: "0.8.17",
    },
    {
      version: "0.5.2",
    },
    {
      version: "0.6.7"
    },
    {
      version: "0.4.26",
      settings: {},
    },
  ],
 },
 networks: {

  mainnet:{
    url: `https://mainnet.infura.io/v3/${INFURA_API_KEY}`,
    accounts: [WALLET_PRIVATE_KEY]
  },
  goerli:{
    url: `https://goerli.infura.io/v3/${INFURA_API_KEY}`,
    accounts: [WALLET_PRIVATE_KEY]
  },
  mumbai: {
    url: `https://polygon-mumbai.infura.io/v3/${INFURA_API_KEY}`,
    accounts: [WALLET_PRIVATE_KEY]
  },
  polygon:{
    url: `https://polygon-mainnet.infura.io/v3/${INFURA_API_KEY}`,
    accounts: [WALLET_PRIVATE_KEY]
  },
 },
 etherscan:{
  apiKey:
  { 
    polygonMumbai: POLYGONSCAN_API_KEY,
    polygon: POLYGONSCAN_API_KEY,
    goerli: ETHERSCAN_API_KEY,
    mainnet: ETHERSCAN_API_KEY
  },
 }
};
