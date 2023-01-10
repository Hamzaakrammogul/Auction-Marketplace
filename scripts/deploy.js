async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
  
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
     const createAuctionContract = await ethers.getContractFactory("contracts/CreateAuctionContract.sol:createAuctionContract");
     const auction = await createAuctionContract.deploy("Robot Drop MarketPlace","0x2D6eDc8E035Bd1c9E9fD105B5c4ef4e4B716ea20","0x9921CDd0d8819F22b4B53B1cb700cF0d7f8B7149");

    // const CreateCubeContract = await ethers.getContractFactory("CreateCubeContract");
    // const cube = await CreateCubeContract.deploy("0xE6f7A5CcB303909432Fa274F19bD5E671fAeaeE8");

    // const SwapContract = await ethers.getContractFactory("SwapContract");
    // const swap = await SwapContract.deploy();
  
    console.log("Token address:", auction.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });