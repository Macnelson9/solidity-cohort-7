// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Listing{
    address owner;
    uint256 id;
    IERC20 paymentToken;
    address NftToken;
    bool isNative;
    uint256 price;
    bool sold;
    uint minOffer;
}

struct OfferDetails{
    uint256 listId;
    uint256 offerAmount;
    address offerrer;
}

contract BlockMarketPlace {

mapping (uint256 listid => Listing list) public idToListing;
mapping (uint256 offerid => OfferDetails offer) public idToOffer;
    function listNft(Listing memory list) external {}

    function buyNft(uint256 listId) external payable {}

    function offer(uint256 listid) external payable {}

    function acceptOffer(uint256 offerid) external {}

    function cancelOffer(uint256 offerid) external{}

    function cancelListing(uint256 listid) external {}



    
}