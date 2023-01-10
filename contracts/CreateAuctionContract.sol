// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";



contract createAuctionContract is IERC721Receiver, Ownable {

    //Name of the marketplace 
    string public name;
    address public CubeContractAddress;
    address public PaymentTokenContractAddress;
    //Index of Auction
    uint256 public index =0;

    //Structure to define auction properties 
    struct auction{
        uint256 index; //Auction index or in our project drop Id 
        uint256 nftId; //NFT id
        address auctioneer; // address of creator of auctioneer 
        address payable currentBidOwner; // Address of highhest bid owner
        uint256 currentBidPrice; // Current highest bid for the auction
        uint256 startAuctionTimestamp; // Timestamp of when auction start
        uint256 endAuctionTimestamp; // Timestamp of when auction will end 
        uint256 bidCount; // Number of bid placed on the auction 
    }
    //Array of all auction 
    auction[] private allAuctions;

    //Public event to notify that a new auction has been created 
     event newAuctions (
        uint256 index,
        uint256 nftId,
        address auctioneer,
        address currentBidOwner,
        uint256 currentBidPrice,
        uint256 startAuctionTimestamp,
        uint256 endAuctionTimestamp,
        uint256 bidCount
     );

    //Public event to notify that a new bid has been placed 
     event newBidonAuction(
        uint256 auctionIndex,
        address bidder,
        uint256 newBid
     );

    //Public event to notify the winner has calimed the NFT 
    event claimedNFT(
        uint256 auctionIndex,
        uint256 nftId,
        address winner
    );

    //Public event that Auctioneer has claimed funds
    event claimedFunds(
        uint256 auctionIndex,
        uint256 nftId,
        address auctioneer
    );

    //Public event to notfiy that NFT has be refunded by the auctioneer
    event refundedNFT(
        uint256 auctionIndex,
        uint256 nftId,
        address auctioneer
    );

    //constructor of the contract
    constructor(string memory _name,  address _CubeContractAddress, address _PaymentTokenContractAddress)
    {
        name = _name;
        CubeContractAddress= _CubeContractAddress;
        PaymentTokenContractAddress=_PaymentTokenContractAddress; 
    }
    /**
     * Check if the addres is a contract address
     * @param _addr address to verify
     */
    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
  
    function newAuction(
        uint256 _nftId,
        uint256 _minBid,
        uint256 _startAuction,
        uint256 _endAuction
    ) external returns (uint256) {

        //check the minimun bid validity 
        require(_minBid > 0, "Invalid minimum bid");

        //check the startAuction and endAuction Timestamp
        require(_startAuction <= block.timestamp, "Invalid start auction timestamp");
        require(_endAuction > block.timestamp, "Invaid end auction timestamp");

        //Get the NFT Contract 
        IERC721 cubeNFT = IERC721(CubeContractAddress);

        //Confirm that msg sender is owner of the NFT 
        require(
            cubeNFT.ownerOf(_nftId) == msg.sender,
            "You are not the owner of the NFT"
        );

        /**
         * Transfer NFT from msg sender to this contract
         * Only possible if the owner of NFT has approved this contract 
         * We can use setApprovalForAll since only adimn will be creating NFT
         */
        cubeNFT.transferFrom(msg.sender, address(this), _nftId);

        //Casting from address to address payable 
        address payable currentBidOwner = payable(address(0));

        //New object of struct auction 
        auction memory newAuc = auction({
         index: index,
         nftId: _nftId,
         auctioneer: msg.sender,
         currentBidOwner: currentBidOwner,
         currentBidPrice: _minBid,
         startAuctionTimestamp: _startAuction,
         endAuctionTimestamp: _endAuction,
         bidCount: 0
        });
   
        allAuctions.push(newAuc);
      
        //Emit the newAuction Eveny 
        emit newAuctions(
        index,
        _nftId,
        msg.sender,
        currentBidOwner,
        _minBid,
        _startAuction,
        _endAuction,
        0 
        );
        //Increment auction index
        index++;

        return index;

    }

    /**
     * Check if the auction is still open 
     * @param _auctionIndex is index of current auction
     */
    function isOpen(
        uint256 _auctionIndex
        ) public view returns(bool)
        {
            auction storage Auction = allAuctions[_auctionIndex];
            if(block.timestamp >= Auction.endAuctionTimestamp){
                return false;
            }else {
                return true;
            }
        }
        
    /**
     * Return the address of the current highest bider
     * for a specific auction
     * @param _auctionIndex Index of the auction
     */
    function getCurrentBidOwner(
        uint256 _auctionIndex)
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
        auction storage Auction = allAuctions[_auctionIndex];

        // check if auction is still open
        require(isOpen(_auctionIndex), "Auction is not open");

        // check if new bid price is higher than the current one
        require(
            _newBid > Auction.currentBidPrice,
            "New bid price must be higher than the current bid"
        );

        // check if new bider is not the owner
        require(
            msg.sender != Auction.auctioneer,
            "Creator of the auction cannot place new bid"
        );

        // get Weth ERC20 token contract
        IERC20 paymentToken = IERC20(PaymentTokenContractAddress);

        // transfer token from new bider account to the marketplace account
        // to lock the tokens
        paymentToken.transferFrom(msg.sender, address(this), _newBid);
       
        // new bid is valid so must refund the current bid owner (if there is one!)
        if (Auction.bidCount > 0) {
            paymentToken.transfer(
                Auction.currentBidOwner,
                Auction.currentBidPrice
            );
             // update auction info
        address payable newBidOwner = payable(msg.sender);
        Auction.currentBidOwner = newBidOwner;
        Auction.currentBidPrice = _newBid;
        Auction.bidCount++;

        // Trigger public event
        emit newBidonAuction(_auctionIndex, msg.sender, _newBid);
       
        }
      else{
        // update auction info
        address payable newBidOwner = payable(msg.sender);
        Auction.currentBidOwner = newBidOwner;
        Auction.currentBidPrice = _newBid;
        Auction.bidCount++;

        // Trigger public event
        emit newBidonAuction(_auctionIndex, msg.sender, _newBid);
       
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
        auction storage Auction = allAuctions[_auctionIndex];

        // Check if the caller is the winner of the auction
        require(
            Auction.currentBidOwner == msg.sender,
            "Only highest current bidder can claim NFT"
        );

        // Get NFT collection contract
        IERC721 cubeNFT = IERC721(
            CubeContractAddress
        );
        // Transfer NFT from marketplace contract
        // to the winner address
   
            cubeNFT.transferFrom(
                address(this),
                Auction.currentBidOwner,
                Auction.nftId
            );

        emit claimedNFT(_auctionIndex, Auction.nftId, msg.sender);
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
        require(_auctionIndex < allAuctions.length, "Invalid auction index"); 

        // Check if the auction is closed
        require(!isOpen(_auctionIndex), "Auction is still open");

        // Get auction
        auction storage Auction = allAuctions[_auctionIndex];

        // Check if the caller is the creator of the auction
        require(
            Auction.auctioneer == msg.sender,
            "Only Auction creator can claim funds"
        );

        // Get ERC20 Payment token contract
        IERC20 paymentToken = IERC20(PaymentTokenContractAddress);
        // Transfer locked tokens from the market place contract
        // to the wallet of the creator of the auction
        paymentToken.transfer(Auction.auctioneer, Auction.currentBidPrice);

        emit claimedFunds(_auctionIndex, Auction.nftId, msg.sender);
        
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
        auction storage Auction = allAuctions[_auctionIndex];

        // Check if the caller is the creator of the auction
        require(
            Auction.auctioneer == msg.sender,
            "Tokens can be claimed only by the creator of the auction"
        );

        require(
            Auction.currentBidOwner == address(0),
            "Existing bider for this auction"
        );

        // Get NFT Collection contract
        IERC721 cubeNFT = IERC721(
            CubeContractAddress
        );
        // Transfer NFT back from marketplace contract
        // to the creator of the auction
        cubeNFT.transferFrom(
            address(this),
            Auction.auctioneer,
            Auction.nftId
        );

        emit refundedNFT(_auctionIndex, Auction.nftId, msg.sender);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function setCubeContractAddress(address _newAddress) external onlyOwner{
        CubeContractAddress= _newAddress;
    }
    function setPaymentTokenContractAddress(address _newAddress) external onlyOwner{
        PaymentTokenContractAddress= _newAddress;
    }
}