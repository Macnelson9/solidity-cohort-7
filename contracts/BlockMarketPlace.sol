// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct Listing{
    address owner;
    uint256 tokenId;
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
    bool status;
}

contract BlockMarketPlace {

mapping (uint256 listid => Listing list) public idToListing;
mapping (uint256 offerid => OfferDetails offer) public idToOffer;

uint256 public lastUpdatedid;
uint256 public lastOfferId;
address public marketOwner;

    constructor() {
        marketOwner = msg.sender;
    }    

    function listNft(Listing memory list) external {
       uint listId =  lastUpdatedid++;
       require(list.price > 0, "Invalid price");
       require(list.minOffer > 0, "Invalid min offer");
       if(list.isNative){
        require(address(list.paymentToken) == address(0), "ERC20 Payment is not supported");
       }
        Listing memory listing;
        listing.owner = msg.sender;
        listing.tokenId = list.tokenId;
        listing.paymentToken = list.paymentToken;
        listing.price = list.price;
        listing.isNative = list.isNative;
        listing.minOffer = list.minOffer;
        listing.NftToken = list.NftToken;
        idToListing[listId] = listing; 


        IERC721(list.NftToken).transferFrom(msg.sender, address(this), list.tokenId);
    }
    function getListing(uint256 listId) external view returns(Listing memory){
        return idToListing[listId];
    }
    function buyNft(uint256 listId) external payable {
        Listing memory l = idToListing[listId];
        require(!l.sold, "ALready Sold");
        idToListing[listId].sold = true;

        if(l.isNative){
            require(msg.value == l.price, "Incorrect price");
            (bool s,) = l.owner.call{value: l.price * 97/100}("");
            (bool ss,) = marketOwner.call{value: l.price * 3/100}("");
            require(s, "Owner transfer failed");
            require(ss, "MarketOwner Transfer failed");
        }else{
            l.paymentToken.transferFrom(msg.sender, l.owner, l.price * 97/100);
            l.paymentToken.transferFrom(msg.sender, marketOwner, l.price * 3/100);
        }
        IERC721(l.NftToken).transferFrom(address(this), msg.sender, l.tokenId);
    }

    function offer(uint256 listid, uint256 offerAmount) external payable {
        uint256 offerId = lastOfferId++;
        Listing memory l = idToListing[listid];
        require(!l.sold, "Already sold");
        if(l.isNative){
            require(msg.value >= l.minOffer, "Invalid offer");
            require(offerAmount == 0, "Cannot offer erc20");
        }else {
        require(offerAmount >= l.minOffer, "Invalid offer");  
        l.paymentToken.transferFrom(msg.sender, address(this), offerAmount);         
        }
        require(msg.sender != l.owner, "Owner cannot offer");
        OfferDetails memory offer_;
        offer_.listId = listid;
        offer_.offerrer = msg.sender;
        offer_.offerAmount = l.isNative ? msg.value : offerAmount;

        idToOffer[offerId] = offer_;
    }

    function getOffer(uint256 offerId) external view returns(OfferDetails memory o) {
        o = idToOffer[offerId];
    }

    function acceptOffer(uint256 offerid) external {
        OfferDetails memory offer_ = idToOffer[offerid];
        Listing memory l = idToListing[offer_.listId];
        // Checks
        require(l.owner == msg.sender, "Unauthorized seller");
        require(!l.sold, "Already Sold");
        require(offer_.offerrer != address(0), "Invalid offer");
        // Effects
        idToListing[offer_.listId].sold = true;
        idToOffer[offerid].status = true;
        // Interactions
        if(l.isNative){
            (bool success,) = l.owner.call{value: offer_.offerAmount * 97/100}("");
            (bool success2,) = marketOwner.call{value: offer_.offerAmount * 3/100}("");
            require(success, "Failed owner transfer");
            require(success2, "Failed marketPlace commission transfer");
        }else{
            l.paymentToken.transfer(l.owner, offer_.offerAmount * 97/100);
            l.paymentToken.transfer(marketOwner, offer_.offerAmount * 3/100);
        }
        IERC721(l.NftToken).transferFrom(address(this), offer_.offerrer, l.tokenId);
    }

    function cancelOffer(uint256 offerid) external{
        OfferDetails memory offer_ = idToOffer[offerid];
        Listing memory l = idToListing[offer_.listId];
        // Checks
        require(!offer_.status, "Offer already accepted");
        require(msg.sender == offer_.offerrer, "Unauthorized offerrer");
        // Effects
        delete idToOffer[offerid];
        // Interactions
        if(l.isNative){
            (bool s,) = offer_.offerrer.call{value: offer_.offerAmount}("");
            require(s, "Failed refund");
        }else{
            l.paymentToken.transfer(offer_.offerrer, offer_.offerAmount);
        }

    }

    function cancelListing(uint256 listid) external {
        Listing memory l = idToListing[listid];
        // Checks
        require(msg.sender == l.owner, "Unauthorized user");
        require(!l.sold, "Already sold");
        // Effects
        delete idToListing[listid];
        // Interaction
        IERC721(l.NftToken).transferFrom(address(this), l.owner, l.tokenId);
    }

}