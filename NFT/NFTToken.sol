// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";


contract NFT_MINT is ERC1155,ERC1155Metadata_URI{
   struct Collection {
       address owner;
       uint256[] allTokens;
       string uri;
       string name;
   }
   mapping(uint256 => uint256) tokenFromCollection;
   uint256[] public allCollection;
   mapping(uint256 => Collection) Collections;
   mapping(address => uint256[])OwnersCollections;
   //collection的信息
   
   struct BidInfo {//竞标信息
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
   //拍卖NFT信息

    enum Tokenstatus{ pending, onsell, onauction }
    struct allTokenstatus {
       Tokenstatus status;
       uint256 tokenId;
    }
    mapping(uint256 => allTokenstatus[]) allTokens;
    mapping(uint256 => uint256) allTokensindex;
    //所有Token的信息

    struct TokenStatus {
      bool isOnSale;
      uint256 index;
    }
    mapping(uint256 => uint256[]) public SaleTokens;
    mapping(uint256 => uint256[]) public AucTokens;
    mapping(uint256 => uint256[]) public pendingTokens;
    mapping(uint256 => TokenStatus)  _listedForAuction;
    mapping(uint256 => TokenStatus)  _listedForSale;
    mapping(uint256 => uint256) _indexForPending;
    //出售的NFT，拍卖的NFT，以及无状态的NFT的信息

    mapping(uint256 => string) internal _name;
    mapping(uint256 => string) internal _symbol;
 

    mapping(uint256 => string) internal tokenURIs;
    mapping(uint256 => address) internal tokenOwners;

    constructor(){}

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
    
    function Addcollection(string memory name_, uint256 collectionId, string memory _uri) public {
        Collections[collectionId].owner = tx.origin;
        Collections[collectionId].name = name_;
        Collections[collectionId].uri = _uri;
        allCollection.push(collectionId);
        OwnersCollections[tx.origin].push(collectionId);
        SaleTokens[collectionId].push(0);
        AucTokens[collectionId].push(0);
        pendingTokens[collectionId].push(0);
    }

    function AddToken(string memory name_, string memory symbol_, uint256 _tokenId,bytes memory data,string memory _uri, uint256 collectionId) public {
        _mint(tx.origin,_tokenId,1,data);
        _name[_tokenId] = name_;
        _symbol[_tokenId] = symbol_;
        tokenOwners[_tokenId] = tx.origin;
        _setURI(_tokenId,_uri);
        allTokenstatus memory x;
        x.status = Tokenstatus.pending;
        x.tokenId = _tokenId;
        allTokens[collectionId].push(x);
        allTokensindex[_tokenId] = allTokens[collectionId].length - 1;
        pendingTokens[collectionId].push(_tokenId);
        _indexForPending[_tokenId] = pendingTokens[collectionId].length - 1; 
        pendingTokens[collectionId][0]++;
        Collections[collectionId].allTokens.push(_tokenId);
        tokenFromCollection[_tokenId] = collectionId;
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
        uint256 collectionId = tokenFromCollection[_id];
        if (isSale == true){
            allTokens[collectionId][allTokensindex[_id]].status = Tokenstatus.onsell;
            if (_listedForSale[_id].index == 0){
               SaleTokens[collectionId].push(_id);
               _listedForSale[_id].index = SaleTokens[collectionId].length-1; 
            }
            else{
               SaleTokens[collectionId][_listedForSale[_id].index] = _id;
            }
            SaleTokens[collectionId][0]++; pendingTokens[collectionId][0]--;
            delete pendingTokens[collectionId][_indexForPending[_id]];
        }
        else {
             allTokens[collectionId][allTokensindex[_id]].status = Tokenstatus.pending;
             pendingTokens[collectionId][_indexForPending[_id]] = _id;
             pendingTokens[collectionId][0]++; SaleTokens[collectionId][0]--;
             delete SaleTokens[collectionId][_listedForSale[_id].index];
        }
        _listedForSale[_id].isOnSale = isSale;
    }

    function getSaleState(uint256 _id) external view returns (bool){
        return _listedForSale[_id].isOnSale;
    }

    function setAuctionState(uint256 _id, bool isAuction) external {
        require(_getOwner(_id) == tx.origin,"not owner!");
        uint256 collectionId = tokenFromCollection[_id];
        if (isAuction == true){
            allTokens[collectionId][allTokensindex[_id]].status = Tokenstatus.onauction;
            if (_listedForAuction[_id].index == 0){
               AucTokens[collectionId].push(_id);
               _listedForAuction[_id].index = AucTokens[collectionId].length-1;
            }
            else{
               AucTokens[collectionId][_listedForAuction[_id].index] = _id;
            }
            AucTokens[collectionId][0]++; pendingTokens[collectionId][0]--;
            delete pendingTokens[collectionId][_indexForPending[_id]];
        }
        else {
            allTokens[collectionId][allTokensindex[_id]].status = Tokenstatus.pending;
            pendingTokens[collectionId][_indexForPending[_id]] = _id;
            pendingTokens[collectionId][0]++; AucTokens[collectionId][0]--;
            delete AucTokens[collectionId][_listedForAuction[_id].index];
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
    
    function getOnSaleList(uint256 collectionId) external view returns (uint256[] memory){
       /* uint256[] memory _List;
        for (uint i = 0; i < SaleTokens.length;i++){
            if (SaleTokens[i] != 0){
              _List.push(SaleTokens[i]);
            }
        }*/
        return SaleTokens[collectionId];
    }

    function getAuctionList(uint256 collectionId) external view returns (uint256[] memory){
        /*uint256[] memory _List; 
        for (uint i = 0; i < SaleTokens.length;i++){
            if (AucTokens[i] != 0){
              _List.push(AucTokens[i]);
            }
        }*/
        return AucTokens[collectionId];
    }

    function getHighestBidInfo(uint256 _id) external view returns (uint256, address){
        return (tokenAuction[_id].HighestBid.value, tokenAuction[_id].HighestBid.buyer);
    }

    function setHighestBidInfo(uint256 _id, uint256 _value, address _buyer) external {
        require(_getOwner(_id) == tx.origin || operatorApproval[tokenOwners[_id]][msg.sender] == true,"not owner!");
        tokenAuction[_id].HighestBid.value = _value;
        tokenAuction[_id].HighestBid.buyer = _buyer;
    }

    function getAllTokens(uint256 CollectionId) public view returns(allTokenstatus[] memory){
        return allTokens[CollectionId];
    }

    function getPendingList(uint256 collectionId) external view returns (uint256[] memory){
        /*uint256[] memory _List; 
        for (uint i = 0; i < SaleTokens.length;i++){
            if (AucTokens[i] != 0){
              _List.push(AucTokens[i]);
            }
        }*/
        return pendingTokens[collectionId];
    }
    
    function getCollectionId(uint256 _tokenId) external view returns(uint256){
        return tokenFromCollection[_tokenId];
    }

    function getallCollection() external view returns(uint256[] memory){
        return allCollection;
    }

    function getCollectionInfo(uint256 _collectionnId) external view returns(Collection memory){
        return Collections[_collectionnId];
    }
}
