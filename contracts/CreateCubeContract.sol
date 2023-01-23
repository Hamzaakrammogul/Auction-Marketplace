//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CreateCubeContract is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    address public auctionContractAddress;
    constructor(address _auction) ERC721("CUBE(NFT)", "CNT") {
        auctionContractAddress= _auction;
    }

    //This function will create Cube for the robotDrop 
    //@param uri will be provided from the front end 
    //When ever user create cube it will also call approve function on the auction contract 
    function createCube(string memory uri) external returns (uint256) {
       
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        approve(auctionContractAddress, tokenId);

        return (tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override (ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) 
    internal 
    override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
     function transferCube(
        address from,
        address to,
        uint256 tokenId
    ) public virtual returns (bool) {
        safeTransferFrom(from, to, tokenId);
        return true;
    }
    function setAuctionAddress(address newAuctionAddress) external onlyOwner
    {
        auctionContractAddress = newAuctionAddress;
    }

}