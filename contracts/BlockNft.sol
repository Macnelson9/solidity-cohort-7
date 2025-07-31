// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BlockNft is ERC721{
    uint256 public tokenID;
    constructor() ERC721("BlockNft", "BKN"){}
    
    function mint(address recepient) external returns(uint256){
     tokenID++;
     uint256 tokenId = tokenID;
        _safeMint(recepient, tokenId);
        return tokenId;
    }
}