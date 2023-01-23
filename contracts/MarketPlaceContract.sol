//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

//@author ameerhamzamogul
contract Marketplace is ReentrancyGuard, Ownable, Pausable {

    // Variables
    address payable public immutable feeAccount; // the account that receives fees
    uint256 public immutable feePercent; // the fee percentage on sales 
    //uint256 public itemCount; 

    struct Item {
        uint256 itemId;
        IERC721 nft;
        uint256 tokenId;
        uint256 price;
        address payable seller;
        bool sold;
        uint256 endTimeStamp;
    }

    // itemId -> Item
    mapping(uint256 => Item) public items;

    event NFTRefunded(
        uint256 tokenId,
        address owner
    );
    
    event Offered(
        uint256 itemId,
        address indexed nft,
        uint256 tokenId,
        uint256 price,
        address indexed seller
    );
    event Bought(
        uint256 itemId,
        address indexed nft,
        uint256 tokenId,
        uint256 price,
        address indexed seller,
        address indexed buyer
    );

    constructor(uint256 _feePercent) {
        feeAccount = payable(msg.sender);
        feePercent = _feePercent;
    }

    //Make item to offer on the marketplace
    //@param IERC721 _nft is address of NFT contract
    //@param _tokenId is id of NFT and also will represent the id of item on sale
    //@param _price sale price set by seller for particular NFT
    //@param endTimeStamp tells contract when to end the sale
    function createOrder(IERC721 _nft, uint256 _tokenId, uint256 _price, uint256 endTimeStamp)
    external 
    nonReentrant
    {     
        //Check if the item is still on sale 
        require(endTimeStamp > block.timestamp, "invalid endTimeStamp");
        //Check if entered price value is valid
        require(_price > 0, "Price must be greater than zero");
        //Check if the seller is the owner of the NFT 
        require(_nft.ownerOf(_tokenId) == msg.sender, "You are not the Owner of this NFT");       
        //transfer nft from msg.sender to this contract
        _nft.transferFrom(msg.sender, address(this), _tokenId);
        //add new item to items mapping
        items[_tokenId] = Item (
            _tokenId,
            _nft,
            _tokenId,
            _price,
            payable(msg.sender),
            false,
            endTimeStamp
        );
        // emit Offered event
        emit Offered(
            _tokenId,
            address(_nft),
            _tokenId,
            _price,
            msg.sender
        );
    }

    //claimNFT function for owner of item 
    //If nobody has purchased the item on sale 
    //Owner of item should be able to get it back 
    //@param IERC721 _nft is cube contract address
    //@param _tokenId of the cube and also use for item's Id 
    function claimNFT(IERC721 _nft, uint256 _tokenId)
    external 
    {
        Item storage item = items[_tokenId];
        //Check if item is still on sale 
        require(item.endTimeStamp <= block.timestamp, "This item is still on sale");
        //Check if caller is owner of item 
        require (item.seller == msg.sender, "You are not the owner of this item");
        //Transfer the item from this contract to the msg.sender address
        _nft.transferFrom(address(this), msg.sender, _tokenId);
        //change onSale from true to false
        //emit event NFTRefunded
        emit NFTRefunded
        (
            _tokenId,
            msg.sender
        );
    }

    //purchaseItem function let user purchase NFTs on Market Place 
    //@param _tokenId will get the cube on sale
    function purchaseItem(uint256 _tokenId) 
    external
    payable
    nonReentrant
    {
        //get the total price for the item NFT price + fee 
        uint256 _totalPrice = getTotalPrice(_tokenId);
        //Getting item from mapping by _tokenId
        Item storage item = items[_tokenId];
        //Check if the item is still on sale 
        require(item.endTimeStamp > block.timestamp, "Item is not on sale anymore");
        //Check price if enough to buy the particular item 
        require(msg.value >= _totalPrice, "not enough ether to cover item price and market fee");
        //Check is items already sold
        require(!item.sold, "item already sold");
        // pay seller and feeAccount
        item.seller.transfer(item.price);
        feeAccount.transfer(_totalPrice - item.price);
        // update item to sold
        item.sold = true;
        // transfer nft to buyer
        item.nft.transferFrom(address(this), msg.sender, item.tokenId);
        // emit Bought event
        emit Bought(
            _tokenId,
            address(item.nft),
            item.tokenId,
            item.price,
            item.seller,
            msg.sender
        );
    }

    //buyItem function let user purchase NFTs on Market Place 
    //@param _wethAddress is the address for payment token
    //@param _tokenId will get the cube on sale
    //@param _price isi the price of sale item
    function buyItem(IERC20 _wethAddress, uint256 _tokenId, uint256 _price) 
    external
    nonReentrant
    {
        //Getting item from mapping by _tokenId
        Item storage item = items[_tokenId];
        // //get the total price for the item NFT price + fee 
        // uint256 _totalPrice = getTotalPrice(_tokenId);
        // //feePrice 
        // uint256 feeprice= _totalPrice-item.price;
        //Check price if enough to buy the particular item 
        require(_price >= item.price, "not enough weth to cover item price");
        //Check is items already sold
        require(!item.sold, "item already sold");
        //pay seller the price of the NFT
        _wethAddress.transferFrom(msg.sender,item.seller,_price);
        //pay feepercentage of marketplace to feeAccount
        //_wethAddress.transferFrom(msg.sender,feeAccount,feeprice);
        // update item to sold
        item.sold = true;
        // transfer nft to buyer
        item.nft.transferFrom(address(this), msg.sender, item.tokenId);
        // emit Bought event
        emit Bought(
            _tokenId,
            address(item.nft),
            item.tokenId,
            item.price,
            item.seller,
            msg.sender
        );
    }

    //Get the total price buyer has to pay for the NFT
    function getTotalPrice(uint256 _tokenId) view public returns(uint){
        return((items[_tokenId].price*(100 + feePercent))/100);
    }
}
