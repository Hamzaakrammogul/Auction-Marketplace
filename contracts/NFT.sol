// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC1155, Ownable {
  using Counters for Counters.Counter;  
  string public name;
  string public symbol;

  mapping(uint => string) public tokenURI;
  Counters.Counter private _tokenIdCounter;

  constructor() ERC1155("") {
    name = "Robot Drop NFT";
    symbol = "RD(NFT)";
  }

  /**
   * This function let user mint nfts
   * And let user set URI for each and every NFT
   */
  function newBatch(uint256[] memory ids, uint256[] memory amounts, string[] memory ipfsHashes)
  external
  {    
        for(uint256 y=0; y<ids.length; y++)
        {
            uint256 tokenId= _tokenIdCounter.current();
           _tokenIdCounter.increment();
            ids[y] = ids[y] + tokenId;
        }
        mintBatch(ids, amounts, "");
        for(uint256 i=0; i < ids.length; i ++)

        {
            uint256 _id= ids[i];
            string memory _ipfshashes= ipfsHashes[i];
            setURI(_id, _ipfshashes );
        }
        
  }
  function mint( uint _id, uint _amount, bytes memory data)
  internal
  {
    _mint(msg.sender, _id, _amount, data);
  }

  function mintBatch(  uint256[] memory _ids, uint256[] memory _amounts, bytes memory data) 
  internal
  {
    _mintBatch(msg.sender, _ids, _amounts, data);
  }

  function burn(uint _id, uint _amount)
  external
  {
    _burn(msg.sender, _id, _amount);
  }

  function burnBatch(uint[] memory _ids, uint[] memory _amounts)
  external
 {
    _burnBatch(msg.sender, _ids, _amounts);
 }

  function burnForMint(address _from, uint[] memory _burnIds, uint[] memory _burnAmounts, uint[] memory _mintIds, uint[] memory _mintAmounts) external onlyOwner {
    _burnBatch(_from, _burnIds, _burnAmounts);
    _mintBatch(_from, _mintIds, _mintAmounts, "");
  }

  function setURI(uint _id, string memory _uri) internal {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }
}
    