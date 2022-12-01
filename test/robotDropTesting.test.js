const { expect } = require("chai"); 

const toWei = (num) => ethers.utils.parseEther(num.toString());
const fromWei = (num) => ethers.utils.formatEther(num);

let CreateCubeContract;
let cube;
let WethContract;
let weth9;
let createAuctionContract;
let auction;
let addr1, addr2, deployer, addrs;

describe("Create Cube Contract", function () {
  beforeEach( async function(){
    CreateCubeContract = await ethers.getContractFactory("CreateCubeContract");
    [deployer, addr1, addr2,...addrs] = await ethers.getSigners();
    cube = await CreateCubeContract.deploy();
  });

describe("Deployment", function(){

  it("Should has the same name and right symbol", async function(){
    let name = "CUBE(NFT)";
    let symbol = "CNT";
    expect(await cube.name()).to.equal(name);
    expect(await cube.symbol()).to.equal(symbol);
  });
});
describe("Minting Cube NFTs", function(){
  it("Should able to mint cube NFT", async function (){
    //Minitng NFT from two addresses 
    await cube.connect(addr1).createCube("0x00");
    await cube.connect(addr2).createCube("0x00");
    //Checking addr1 and addr2 balances for confirmation
    let bal= await cube.balanceOf(addr1.address);
    expect(bal).to.equal("1");
    let bal2= await cube.balanceOf(addr2.address);
    expect(bal2).to.equal("1");
  });
});
describe("Transfer From Functionality", function(){
  it("Should be able to to transfer NFT", async function (){
    //Minting NFT from addr1
    await cube.connect(addr1).createCube("0x00");
    //Checking balamces of addr1 and addr2
    let initialBal1 = await cube.balanceOf(addr1.address);
    expect(initialBal1).to.equal("1");
    let initialBal2= await cube.balanceOf(addr2.address);
    expect(initialBal2).to.equal("0");
    //Transfering NFT from Addr1 to addr2
    await cube.connect(addr1).transferCube(addr1.address, addr2.address, "0" );
    //Checking balances after the transfer
    let finalBal1= await cube.balanceOf(addr1.address);
    expect(finalBal1).to.equal("0");
    let finalBal2= await cube.balanceOf(addr2.address);
    expect(finalBal2).to.equal("1");
  });
  it("it should allow thrid party to spend on behalf of owner", async function(){
    // Creating cube nft by addr1
    await cube.connect(addr1).createCube("0x00");
    //checking balance before transfer 
    expect(await cube.balanceOf(addr1.address)).to.equal("1");
    expect(await cube.balanceOf(addr2.address)).to.equal("0");
    // approving deployer to spend on addr1 behalf
    await cube.connect(addr1).setApprovalForAll(deployer.address, true);
    //Deployer transfer addr1 nft to addr2
    await cube.connect(deployer).transferCube(addr1.address, addr2.address, "0");
    //checking balance of addr1 and addr2 
    expect(await cube.balanceOf(addr1.address)).to.equal("0");
    expect(await cube.balanceOf(addr2.address)).to.equal("1");
  });
});
});
describe("Weth9 Contract", function() {
  beforeEach( async function(){
    WethContract = await ethers.getContractFactory("WETH9");
    [deployer, addr1, addr2,...addrs]= await ethers.getSigners();
    weth9= await WethContract.deploy()
  });
  describe("Deployment", function(){
    it("Should has the same name, symbol and decimals", async function(){
      let name = "Wrapped Ether";
      let symbol = "WETH";
      let decimals = 18;

      expect (await weth9.name()).to.equal(name);
      expect (await weth9.symbol()).to.equal(symbol);
      expect (await weth9.decimals()).to.equal(decimals);
    });
  });
  describe("Deposit Functionality Testing", async function(){
    it("Should be able to deposit the ether", async function(){
      //Depositing ether into the weth contract
      await weth9.connect(addr1).deposit({value: ethers.utils.parseEther("1")});
      //Checing balance of addr1 for confirmation
      let bal1= await weth9.balanceOf(addr1.address);
      expect(bal1).to.equal("1000000000000000000");
    });
  });
  describe("WithDraw Functionality", async function(){
    it("Should be able to withdraw ether", async function(){
      //deposit 1 ether into weth contract by addr1
      await weth9.connect(addr1).deposit({value: ethers.utils.parseEther("1")});
      //checkig balance before withdraw
      let initialBal= await weth9.balanceOf(addr1.address);
      expect(initialBal).to.equal("1000000000000000000");
      //Withdrawing ether from the contract
      await weth9.connect(addr1).withdraw("1000000000000000000");
      //checking balances after withdrawing 
      let finalBal= await weth9.balanceOf(addr1.address);
      expect(finalBal).to.equal("0");
    });
  });
  describe("transfer and transferFrom functionality", function(){
    it("Should be able to trasfer weth from one account to another", async function(){
      //Depositing weth form addr1 address
      await weth9.connect(addr1).deposit({value: ethers.utils.parseEther("1")});
      //Checking balances of addr1 and addr2 before transfer
      let initialBal1= await weth9.balanceOf(addr1.address);
      expect(initialBal1).to.equal("1000000000000000000");
      let initialBal2= await weth9.balanceOf(addr2.address);
      expect(initialBal2).to.equal("0");
      //Transfering from addr1 to addr2
      await weth9.connect(addr1).transfer(addr2.address, "1000000000000000000");
      //Checking balances after transfer
      let finalBal1= await weth9.balanceOf(addr1.address);
      expect(finalBal1).to.equal("0");
      let finalBal2= await weth9.balanceOf(addr2.address);
      expect(finalBal2).to.equal("1000000000000000000");
    });

    it("It should allow a thirdparty to spend on owner behalf", async function(){
      //deposit 1 ether from addr1
      await weth9.connect(addr1).deposit({value: ethers.utils.parseEther("1")});
      expect(await weth9.balanceOf(addr1.address)).to.equal("1000000000000000000");
      //approving deployer to spend on addr1 behalf
      await weth9.connect(addr1).approve(deployer.address, "1000000000000000000");
      // deployer spending on addr1 behalf
      await weth9.connect(deployer).transferFrom(addr1.address, addr2.address, "1000000000000000000");
      //Checing balnces after transfer 
      expect(await weth9.balanceOf(addr1.address)).to.equal("0");
      expect(await weth9.balanceOf(addr2.address)).to.equal("1000000000000000000");
    });
  });
});
describe("Auction Contract", function() {
  beforeEach( async function(){
    //Getting instances of all the contracts
    createAuctionContract= await ethers.getContractFactory("createAuctionContract");
    CreateCubeContract= await ethers.getContractFactory("CreateCubeContract");
    WethContract= await ethers.getContractFactory("WETH9");
    //Gettign the signers
    [deployer, addr1, addr2, ...addrs]= await ethers.getSigners();
    // Deploying the contracts
    auction= await createAuctionContract.deploy("Robot Drop Auction");
    cube= await CreateCubeContract.deploy();
    weth9= await WethContract.deploy();
  });
  describe("Deployment", function(){
    it("Should have same name as of the contracts", async function(){
      let name = "Robot Drop Auction";
      let wethname= "Wrapped Ether";
      let cubename= "CUBE(NFT)";
      expect(await auction.name()).to.equal(name);
      expect(await cube.name()).to.equal(cubename);
      expect(await weth9.name()).to.equal(wethname);
    });
  });
  describe("Checking new Auction functionality", function(){
    it("Should be able to create new auction", async function(){
      /**
       * First lets create cube nft using cube contract
       * Give approval to auction address
       */
      await cube.connect(addr1).createCube("0x00");
      await cube.connect(addr1).setApprovalForAll(auction.address, true);
      //lets create a new auction now
      await auction.connect(addr1).newAuction(
        cube.address,
        weth9.address,
        "0",
        toWei("0.1"),
        "1669913626",
        "1669914600"
      );
      // Confirming auction by index
      expect(await auction.index()).to.equal("1");
    });
    it("Should let other to bid on the open auction", async function(){
      // First deposit money into weth contract 
      await weth9.connect(addr2).deposit({value: ethers.utils.parseEther("1")});
      //Approving auction address
      await weth9.connect(addr2).approve(auction.address, true);
      // Biding on the auction 
      await auction.connect(addr2).bid("0", toWei("0.1"));

    })
  })
});