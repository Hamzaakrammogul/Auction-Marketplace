// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
contract NFT is ERC1155, Ownable {
    
  string public name;
  string public symbol;

  mapping(uint => string) public tokenURI;

  constructor() ERC1155("") {
    name = "Robot Drop NFT";
    symbol = "RD(NFT)";
  }

   /**
     * new function to batch minting of a NFT
     * It accepts multiple hashes for data field
     */
  function newBatch(uint256[] memory ids, uint256[] memory amounts, bytes[] memory data)
  external
  {

        for(uint256 i=0; i < ids.length; i ++)

        {
            uint256 _id= ids[i];
            uint256 _amount= amounts[i];
            bytes memory _data= data[i];
            _mint(msg.sender, _id, _amount, _data );
        }
  }

  function mint( uint _id, uint _amount, bytes memory data)
  internal
  {
    _mint(msg.sender, _id, _amount, data);
  }

  function mintBatch( uint[] memory _ids, uint[] memory _amounts, bytes memory data) 
  external
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

  function setURI(uint _id, string memory _uri) external onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function uri(uint _id) public override view returns (string memory) {
    return tokenURI[_id];
  }
}
    