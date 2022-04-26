// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";


contract NFT_MINT is ERC1155,ERC1155Metadata_URI{
   struct BidInfo {
       address buyer;
       uint256 value;
   }


   mapping(uint256 => uint256)  imagePrice;
   struct auctionData { 
    uint256 price;
    uint256 time;
    BidInfo HighestBid;
   }
   mapping(uint256 => auctionData) tokenAuction;



    enum Tokenstatus{ pending, onsell, onauction }
    struct allTokenstatus {
       Tokenstatus status;
       uint256 tokenId;
    }
    allTokenstatus[] public allTokens;
    mapping(uint256 => uint256) allTokensindex;


    struct TokenStatus {
      bool isOnSale;
      uint256 index;
    }
    uint256[] public SaleTokens;
    uint256[] public AucTokens;
    uint256[] public pendingTokens;
    mapping(uint256 => TokenStatus)  _listedForAuction;
    mapping(uint256 => TokenStatus)  _listedForSale;
    mapping(uint256 => uint256) _indexForPending;


    mapping(uint256 => string) internal _name;
    mapping(uint256 => string) internal _symbol;
 

    mapping(uint256 => string) internal tokenURIs;
    mapping(uint256 => address) internal tokenOwners;

    constructor(){
        SaleTokens.push(0);
        AucTokens.push(0);
        pendingTokens.push(0);
    }
    function name(uint256 _id) external view returns (string memory){
        return _name[_id];
    }
    function symbol(uint256 _id) external view returns(string memory){
        return _symbol[_id];
    }
    function uri(uint256 _id) external view returns (string memory) {
       // require(exists(_id));
        return tokenURIs[_id];
    }

    function AddToken(string memory name_, string memory symbol_, uint256 _tokenId,bytes memory data,string memory _uri) external {
        _mint(tx.origin,_tokenId,1,data);
        _name[_tokenId] = name_;
        _symbol[_tokenId] = symbol_;
        tokenOwners[_tokenId] = tx.origin;
        _setURI(_tokenId,_uri);
        allTokenstatus memory x;
        x.status = Tokenstatus.pending;
        x.tokenId = _tokenId;
        allTokens.push(x);
        allTokensindex[_tokenId] = allTokens.length - 1;
        pendingTokens.push(_tokenId);
        _indexForPending[_tokenId] = pendingTokens.length - 1; 
        pendingTokens[0]++;
    }

    function _setURI(uint256 _id,string memory _uri)  internal {
       tokenURIs[_id] = _uri;
    }
    function _setOwner(uint256 _id,address _owner) public {
        require (tokenOwners[_id] == msg.sender || operatorApproval[tokenOwners[_id]][msg.sender] == true,"Is not owner!");
        tokenOwners[_id] = _owner;
    }

    function _getOwner(uint256 _id) public view returns (address){
        return tokenOwners[_id];
    }
    
    function setImagePrice(uint256 _id, uint256 _price) external {
        require(_getOwner(_id) == tx.origin,"not owner!");
        imagePrice[_id] = _price;
    }

    function getImagePrice(uint256 _id) external view returns (uint256){
        return imagePrice[_id];
    }
    
    function setSaleState(uint256 _id, bool isSale) external {
        require(_getOwner(_id) == tx.origin,"not owner!");
        if (isSale == true){
            allTokens[allTokensindex[_id]].status = Tokenstatus.onsell;
            if (_listedForSale[_id].index == 0){
               SaleTokens.push(_id);
               _listedForSale[_id].index = SaleTokens.length-1; 
            }
            else{
               SaleTokens[_listedForSale[_id].index] = _id;
            }
            SaleTokens[0]++; pendingTokens[0]--;
            delete pendingTokens[_indexForPending[_id]];
        }
        else {
             allTokens[allTokensindex[_id]].status = Tokenstatus.pending;
             pendingTokens[_indexForPending[_id]] = _id;
             pendingTokens[0]++; SaleTokens[0]--;
             delete SaleTokens[_listedForSale[_id].index];
        }
        _listedForSale[_id].isOnSale = isSale;
    }

    function getSaleState(uint256 _id) external view returns (bool){
        return _listedForSale[_id].isOnSale;
    }

    function setAuctionState(uint256 _id, bool isAuction) external {
        require(_getOwner(_id) == tx.origin,"not owner!");
        if (isAuction == true){
            allTokens[allTokensindex[_id]].status = Tokenstatus.onauction;
            if (_listedForAuction[_id].index == 0){
               AucTokens.push(_id);
               _listedForAuction[_id].index = AucTokens.length-1;
            }
            else{
               AucTokens[_listedForAuction[_id].index] = _id;
            }
            AucTokens[0]++; pendingTokens[0]--;
            delete pendingTokens[_indexForPending[_id]];
        }
        else {
            allTokens[allTokensindex[_id]].status = Tokenstatus.pending;
            pendingTokens[_indexForPending[_id]] = _id;
            pendingTokens[0]++; AucTokens[0]--;
            delete AucTokens[_listedForAuction[_id].index];
        }
        _listedForAuction[_id].isOnSale = isAuction;
    }
    
    function getAuctionState(uint256 _id) external view returns (bool) {
        return _listedForAuction[_id].isOnSale;
    }
    function setAuctionInfo(uint256 _id, uint256 _price, uint256 _time) external{
        require(_getOwner(_id) == tx.origin ,"not owner!");
        tokenAuction[_id].price = _price;
        tokenAuction[_id].time = _time;
        delete tokenAuction[_id].HighestBid;
    }
    
    function getAuctionPrice(uint256 _id) external view returns (uint256){
        return tokenAuction[_id].price;
    }

    function getAuctionTime(uint256 _id) external view returns (uint256){
        return tokenAuction[_id].time;
    }
    
    function getOnSaleList() external view returns (uint256[] memory){
       /* uint256[] memory _List;
        for (uint i = 0; i < SaleTokens.length;i++){
            if (SaleTokens[i] != 0){
              _List.push(SaleTokens[i]);
            }
        }*/
        return SaleTokens;
    }

    function getAuctionList() external view returns (uint256[] memory){
        /*uint256[] memory _List; 
        for (uint i = 0; i < SaleTokens.length;i++){
            if (AucTokens[i] != 0){
              _List.push(AucTokens[i]);
            }
        }*/
        return AucTokens;
    }

    function getHighestBidInfo(uint256 _id) external view returns (uint256, address){
        return (tokenAuction[_id].HighestBid.value, tokenAuction[_id].HighestBid.buyer);
    }

    function setHighestBidInfo(uint256 _id, uint256 _value, address _buyer) external {
        require(_getOwner(_id) == tx.origin || operatorApproval[tokenOwners[_id]][msg.sender] == true,"not owner!");
        tokenAuction[_id].HighestBid.value = _value;
        tokenAuction[_id].HighestBid.buyer = _buyer;
    }

    function getAllTokens() public view returns(allTokenstatus[] memory){
        return allTokens;
    }

    function getPendingList() external view returns (uint256[] memory){
        /*uint256[] memory _List; 
        for (uint i = 0; i < SaleTokens.length;i++){
            if (AucTokens[i] != 0){
              _List.push(AucTokens[i]);
            }
        }*/
        return pendingTokens;
    }

}