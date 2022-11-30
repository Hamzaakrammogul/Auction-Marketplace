// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 <0.9.0;


import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

contract Auctions is IERC721Receiver {
    // Name of the marketplace
    string public name;

    // Index of auctions
    uint256 public index = 0;

    // Structure to define auction properties
    struct Auction {
        uint256 index; // Auction Index
        address CubeContractAddress; // Address of the ERC721 NFT contract
        address addressPaymentToken; // Address of the ERC20 Weth Payment Token contract
        uint256 nftId; // NFT Id
        address creator; // Creator of the Auction
        address payable currentBidOwner; // Address of the highest bider
        uint256 currentBidPrice; // Current highest bid for the auction
        uint256 startAuction;
        uint256 endAuction; // Timestamp for the end day&time of the auction
        uint256 bidCount; // Number of bid placed on the auction
    }

    // Array will all auctions
    Auction[] private allAuctions;

    // Public event to notify that a new auction has been created
    event NewAuction(
        uint256 index,
        address CubeContractAddress,
        address addressPaymentToken,
        uint256 nftId,
        address Auctioneer,
        address currentBidOwner,
        uint256 currentBidPrice,
        uint256 startAuction,
        uint256 endAuction,
        uint256 bidCount
    );

    // Public event to notify that a new bid has been placed
    event NewBidOnAuction(uint256 auctionIndex, address bidder, uint256 newBid);

    // Public event to notif that winner of an
    // auction claim for his reward
    event NFTClaimed(uint256 auctionIndex, uint256 nftId, address claimedBy);

    // Public event to notify that the creator of
    // an auction claimed for his money
    event TokensClaimed(uint256 auctionIndex, uint256 nftId, address claimedBy);

    // Public event to notify that an NFT has been refunded to the
    // creator of an auction
    event NFTRefunded(uint256 auctionIndex, uint256 nftId, address claimedBy);

    // constructor of the contract
    constructor(string memory _name) {
        name = _name;
    }

    /**
     * Check if a specific address is
     * a contract address
     * @param _addr: address to verify
     */
    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /**
     * Create a new auction of a specific NFT
     * @param _cubeContractAddress address of the ERC721 NFT contract
     * @param _addressPaymentToken address of the ERC20 payment token contract
     * @param _nftId Id of the NFT for sale
     * @param _minBid Inital bid decided by the creator of the auction
     * @param _endAuction Timestamp with the end date and time of the auction
     */
    function createAuction(
        address _cubeContractAddress,
        address _addressPaymentToken,
        uint256 _nftId,
        uint256 _minBid,
        uint256 _startAuction,
        uint256 _endAuction
    ) external returns (uint256) {
        //Check is addresses are valid
        require(
            isContract(_cubeContractAddress),
            "Invalid NFT Collection contract address"
        );
        require(
            isContract(_addressPaymentToken),
            "Invalid Payment Token contract address"
        );
          // Check if the startAuction time is valid
        require(_startAuction <= block.timestamp, "Invalid start date for auction");

        // Check if the endAuction time is valid
        require(_endAuction > block.timestamp, "Invalid end date for auction");

        // Check if the initial bid price is > 0
        require(_minBid > 0, "Invalid initial bid price");

        // Get NFT collection contract
        IERC721 cubeNFT = IERC721(_cubeContractAddress);

        // Make sure the sender that wants to create a new auction
        // for a specific NFT is the owner of this NFT
        require(
            cubeNFT.ownerOf(_nftId) == msg.sender,
            "Caller is not the owner of the NFT"
        );

       
        //Make sure use setApprovalForAll function to allolw auction address to change ownership
        // Lock NFT in Marketplace contract
        cubeNFT.transferFrom(msg.sender, address(this), _nftId);

        //Casting from address to address payable
        address payable currentBidOwner = payable(address(0));
        // Create new Auction object
        Auction memory newAuction = Auction({
            index: index,
            CubeContractAddress: _cubeContractAddress,
            addressPaymentToken: _addressPaymentToken,
            nftId: _nftId,
            creator: msg.sender,
            currentBidOwner: currentBidOwner,
            currentBidPrice: _minBid,
            startAuction: _startAuction,
            endAuction: _endAuction,
            bidCount: 0
        });

        //update list
        allAuctions.push(newAuction);

        // increment auction sequence
        index++;

        // Trigger event and return index of new auction
        emit NewAuction(
            index,
            _cubeContractAddress,
            _addressPaymentToken,
            _nftId,
            msg.sender,
            currentBidOwner,
            _minBid,
            _startAuction,
            _endAuction,
            0
        );
        return index;
    }

    /**
     * Check if an auction is open
     * @param _auctionIndex Index of the auction
     */
    function isOpen(uint256 _auctionIndex) public view returns (bool) {
        Auction storage auction = allAuctions[_auctionIndex];
        if (block.timestamp >= auction.endAuction) return false;
        return true;
    }

    /**
     * Return the address of the current highest bider
     * for a specific auction
     * @param _auctionIndex Index of the auction
     */
    function getCurrentBidOwner(uint256 _auctionIndex)
        public
        view
        returns (address)
    {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");
        return allAuctions[_auctionIndex].currentBidOwner;
    }

    /**
     * Return the current highest bid price
     * for a specific auction
     * @param _auctionIndex Index of the auction
     */
    function getCurrentBid(uint256 _auctionIndex)
        public
        view
        returns (uint256)
    {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");
        return allAuctions[_auctionIndex].currentBidPrice;
    }

    /**
     * Place new bid on a specific auction
     * @param _auctionIndex Index of auction
     * @param _newBid New bid price
     */
    function bid(uint256 _auctionIndex, uint256 _newBid)
        external
        returns (bool)
    {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");
        Auction storage auction = allAuctions[_auctionIndex];

        // check if auction is still open
        require(isOpen(_auctionIndex), "Auction is not open");

        // check if new bid price is higher than the current one
        require(
            _newBid > auction.currentBidPrice,
            "New bid price must be higher than the current bid"
        );

        // check if new bider is not the owner
        require(
            msg.sender != auction.creator,
            "Creator of the auction cannot place new bid"
        );

        // get Weth ERC20 token contract
        ERC20 paymentToken = ERC20(auction.addressPaymentToken);

        // transfer token from new bider account to the marketplace account
        // to lock the tokens
        require(
            paymentToken.transferFrom(msg.sender, address(this), _newBid),
            "Tranfer of Weth failed"
        );

        // new bid is valid so must refund the current bid owner (if there is one!)
        if (auction.bidCount > 0) {
            paymentToken.transfer(
                auction.currentBidOwner,
                auction.currentBidPrice
            );
        }
      else{
        // update auction info
        address payable newBidOwner = payable(msg.sender);
        auction.currentBidOwner = newBidOwner;
        auction.currentBidPrice = _newBid;
        auction.bidCount++;

        // Trigger public event
        emit NewBidOnAuction(_auctionIndex, msg.sender, _newBid);
       
      }
       return true;
    }

    /**
     * Function used by the winner of an auction
     * to withdraw his NFT.
     * When the NFT is withdrawn, the creator of the
     * auction will receive the payment tokens in his wallet
     * @param _auctionIndex Index of auction
     */
    function claimNFT(uint256 _auctionIndex) external {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");

        // Check if the auction is closed
        require(!isOpen(_auctionIndex), "Auction is still open");

        // Get auction
        Auction storage auction = allAuctions[_auctionIndex];

        // Check if the caller is the winner of the auction
        require(
            auction.currentBidOwner == msg.sender,
            "Only highest current bidder can claim NFT"
        );

        // Get NFT collection contract
        IERC721 cubeNFT = IERC721(
            auction.CubeContractAddress
        );
        // Transfer NFT from marketplace contract
        // to the winner address
   
            cubeNFT.transferFrom(
                address(this),
                auction.currentBidOwner,
                auction.nftId
            );

        emit NFTClaimed(_auctionIndex, auction.nftId, msg.sender);
    }

    /**
     * Function used by the creator of an auction
     * to withdraw his tokens when the auction is closed
     * creator will get highest bid incase of there is a bidder 
     * otherwise creator will get his NFT back
     * When the Token are withdrawn, the winned of the
     * auction will receive the NFT in his wallet
     * @param _auctionIndex Index of the auction
     */
    function claimFunds(uint256 _auctionIndex) external {
        require(_auctionIndex < allAuctions.length, "Invalid auction index"); // XXX Optimize

        // Check if the auction is closed
        require(!isOpen(_auctionIndex), "Auction is still open");

        // Get auction
        Auction storage auction = allAuctions[_auctionIndex];

        // Check if the caller is the creator of the auction
        require(
            auction.creator == msg.sender,
            "Only Auction creator can claim funds"
        );

        if (auction.currentBidOwner== address(0)){
            
        // Get NFT Collection contract
        IERC721 cubeNFT = IERC721(
            auction.CubeContractAddress
        );
        // Transfer NFT back from marketplace contract
        // to the creator of the auction
        cubeNFT.transferFrom(
            address(this),
            auction.creator,
            auction.nftId
        );

        emit NFTRefunded(_auctionIndex, auction.nftId, msg.sender);

        }else {

     

        // Get ERC20 Payment token contract
        ERC20 paymentToken = ERC20(auction.addressPaymentToken);
        // Transfer locked tokens from the market place contract
        // to the wallet of the creator of the auction
        paymentToken.transfer(auction.creator, auction.currentBidPrice);

        emit TokensClaimed(_auctionIndex, auction.nftId, msg.sender);
        }
    }

    /**
     * Function used by the creator of an auction
     * to get his NFT back in case the auction is closed
     * but there is no bider to make the NFT won't stay locked
     * in the contract
     * @param _auctionIndex Index of the auction
     */
    function refundNFT(uint256 _auctionIndex) external {
        require(_auctionIndex < allAuctions.length, "Invalid auction index");

        // Check if the auction is closed
        require(!isOpen(_auctionIndex), "Auction is still open");

        // Get auction
        Auction storage auction = allAuctions[_auctionIndex];

        // Check if the caller is the creator of the auction
        require(
            auction.creator == msg.sender,
            "Tokens can be claimed only by the creator of the auction"
        );

        require(
            auction.currentBidOwner == address(0),
            "Existing bider for this auction"
        );

        // Get NFT Collection contract
        IERC721 cubeNFT = IERC721(
            auction.CubeContractAddress
        );
        // Transfer NFT back from marketplace contract
        // to the creator of the auction
        cubeNFT.transferFrom(
            address(this),
            auction.creator,
            auction.nftId
        );

        emit NFTRefunded(_auctionIndex, auction.nftId, msg.sender);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}