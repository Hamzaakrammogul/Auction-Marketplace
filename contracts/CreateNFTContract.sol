// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.0 < 0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CreateNFTContract is ERC1155, Ownable, ERC1155Supply{

    string public name;
    string public symbol;

    uint256 public constant Mastercraft = 0;
    uint256 public constant Legendary = 1;
    uint256 public constant Epic = 2;
    uint256 public constant Rare = 3;
    uint256 public constant Uncommon = 4;
    uint256 public constant Common = 5;

    struct NFT {
        uint256 id;
        uint256 amount;
        bytes data;
    }

    NFT [] allNFT;

    constructor(string memory _name, string memory _symbol) ERC1155("") {
        name = _name;
        symbol= _symbol;
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }
    /**
     * new function to batch minting of a NFT
     * It accepts multiple hashes for data field
     */
     function batchMinting(uint256[] memory ids, uint256[] memory amounts, bytes[] memory data) external {

        for(uint256 i=0; i < ids.length; i ++)

        {
            uint256 _id= ids[i];
            uint256 _amount= amounts[i];
            bytes memory _data= data[i];
            mint(msg.sender, _id, _amount, _data );
        }
    }
    /**
     * Function to create new single or batch of NFTs 
    */
    function newBatch(
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
        ) external 
    {
            if(ids.length == 1){
                mint(msg.sender, ids[0], amounts[0], data);
            }
            else
            {
                mintBatch(msg.sender, ids, amounts, data);
            }
    }
    /**
     * Function to mint the single NFT
    */
    function mint(
       address account,
       uint256 id,
       uint256 amount,
       bytes memory data) internal {  
            _mint(account, id, amount, data);
    }

    /**
     *Function to mint batch of NFTs 
     */
    function mintBatch(
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data 
    ) internal {

        _mintBatch(to, ids, amounts, data);       
    }
    /**
     * Function that is required by solidity to override
     */
   function _beforeTokenTransfer(
     address operator,
     address from, 
     address to, 
     uint256[] memory ids, 
     uint256[] memory amounts,
     bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * Function that will show the specific uri of a token by accepting tokeId as an Parameter 
     */
    function uri(uint256 tokenId) override public pure returns (string memory) {
        return(
            string(abi.encodePacked("",
            Strings.toString(tokenId),
            ".json"))
        );
        
    }
 
}