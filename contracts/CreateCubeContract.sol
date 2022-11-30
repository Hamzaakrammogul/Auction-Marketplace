// SPDX-License-Identifier:MIT
pragma solidity >= 0.7.0 < 0.9.0 ;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract createCubeContract is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("CUBE(NFT)", "CNT") {}

    /**
     * Function to create Cube 
     * parameter uri of NFT 
     * returns tokenID
     */
    function createCube(string memory uri)
     external 
     returns (uint256)
       {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);

        return tokenId;
        }
    /**
     * This function override required by the solidity
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )   internal
        override (ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
    /**
     * This function override required by the solidity
     */
    function _burn(
        uint256 tokenId
       )internal
        override(ERC721, ERC721URIStorage) {
        
        super._burn(tokenId);
        
    }
    /**
     * This function override required by the solidity
     */

     function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
    /**
     * This function override required by the solidity
     */

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

}