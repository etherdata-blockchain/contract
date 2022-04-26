// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import   "./NFTToken.sol";

contract ImageContract{

  struct TokenInfo {
    bool _isSell;
    bool _isAuction;
    uint256 _price;
    address _owner;
    uint256 _tokenId;
    string _name;
    string _symbol;
    string _uri;
    uint256 _aucPrice;
    uint256 _aucTime;
    uint256 _collectionnId;
  }

  NFT_MINT NFTTOKEN;
  address public admin;
  address public owner;
  
  event BoughtNFT(uint256 _tokenId, address _buyer, uint256 _price);
  event AuctionNFT(uint256 _tokenId, address _buyer, uint256 _price);

  uint256[50] public recentTokens;
  uint256 recent_point;
  
  modifier onlyAdmin() {
        require(
            msg.sender == admin,
            "Only admin can call this."
        );
        _;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only owner can call this."
        );
        _;
    }
  constructor(){
      owner = msg.sender;
      admin = address(this);
  }
  function setNftContract(address nftToken) public  {
         require(nftToken != address(0),"ERROR ADDRESS");
         NFTTOKEN = NFT_MINT(nftToken);
  }
/*
  function AddCollection(string memory name_, uint256 collectionId, string memory _uri) public {
         NFTTOKEN.Addcollection(name_,collectionId,_uri);
  }
  function addToken(string memory name_, string memory symbol_, uint256 _tokenId,bytes memory data,string memory _uri, uint256 collectionId) public {
         NFTTOKEN.AddToken(name_, symbol_, _tokenId, data, _uri, collectionId);
         if (recent_point < 50){
           recentTokens[recent_point++] = _tokenId;
         }
         else{
           for (uint i=0; i<49; i++){
              recentTokens[i]=recentTokens[i+1];
           }
           recentTokens[49] = _tokenId;
         }
  }
 */
 
  function addToken(string memory name_, string memory symbol_, uint256 _tokenId,bytes memory data,string memory _uri) public {
         NFTTOKEN.AddToken(name_, symbol_, _tokenId, data, _uri);
         if (recent_point < 50){
           recentTokens[recent_point++] = _tokenId;
         }
         else{
           for (uint i=0; i<49; i++){
              recentTokens[i]=recentTokens[i+1];
           }
           recentTokens[49] = _tokenId;
         }
  }

  function approveNFT(address _to,  bool _approved) internal {
    NFTTOKEN.setApprovalForAll(_to, _approved);
  }
  
  function isApprovedOrOwner(address _to) view public returns (bool){
    return NFTTOKEN.isApprovedForAll(msg.sender, _to);
  }


  function updatePrice(uint _id, uint _price) public returns (bool){
    require(NFTTOKEN._getOwner(_id) == msg.sender,"not owner!");
    NFTTOKEN.setImagePrice(_id,_price);
    return true;
  }

  function approveForSale(uint _tokenId, uint _price) public {
    require(NFTTOKEN._getOwner(_tokenId) == msg.sender,"not owner");
    require(NFTTOKEN.getAuctionState(_tokenId) == false,"the product is auction");
    require(NFTTOKEN.getSaleState(_tokenId) == false,"the product is selling");
    NFTTOKEN.setSaleState(_tokenId, true);
    updatePrice(_tokenId,_price);
    approveNFT(admin,true);
  }

  function approveForAuction(uint _tokenId, uint _price, uint _time) public {
    require(NFTTOKEN._getOwner(_tokenId) == msg.sender,"not owner!");
    require(NFTTOKEN.getSaleState(_tokenId) == false,"the product is selling");
    require(NFTTOKEN.getAuctionState(_tokenId) == false,"the product is auction");
    NFTTOKEN.setAuctionState(_tokenId, true);
    NFTTOKEN.setAuctionInfo(_tokenId, _price, block.timestamp + _time);
    approveNFT(admin,true);
  }

  function nftSold(uint _tokenId) internal {
    if (NFTTOKEN.getSaleState(_tokenId) == true){
      NFTTOKEN.setSaleState(_tokenId, false);
    }
    if (NFTTOKEN.getAuctionState(_tokenId) == true){
      NFTTOKEN.setAuctionState(_tokenId, false);
    }
  }
  
  function buyImage(uint256 _tokenId) public payable {
      uint256  _price =  NFTTOKEN.getImagePrice(_tokenId);
      require(NFTTOKEN.getSaleState(_tokenId) == true,"The product is not available");
      require(msg.value >= _price,"too less etd");
      payable(msg.sender).transfer(msg.value - _price);

      address  _owner= NFTTOKEN._getOwner(_tokenId);
      payable(_owner).transfer(_price);
      NFTTOKEN.safeTransferFrom(_owner,msg.sender,_tokenId,1,"");
      NFTTOKEN._setOwner(_tokenId,msg.sender);
      nftSold(_tokenId);
      emit BoughtNFT(_tokenId, msg.sender, _price);
  }
/*
  function getWetd(uint256 _value) payable public {
    require(msg.sender.value >= _value,"etd is not adequate");
    WTED.transfer(msg.sender,_value);
    msg.sender.transfer(msg.sender - _value);
  }
  
  function getWetdBalances() payable public returns(uint256){
     return WETD._balanceOf(msg.sender);
  }

  function AuctionImage(uint256 _tokenId, uint256 _value) public payable {
    require(_listedForAuction[_tokenId] == false,"The product is not available");
    require(getWetdBalances() >= _value,"balance is not adequate");
    
    emit AuctionNFT(_tokenId,msg.sender,_value);
  }
  */
  function AuctionImage(uint256 _tokenId) public payable {
    uint256  _TIME = NFTTOKEN.getAuctionTime(_tokenId);
    uint256  _PRICE = NFTTOKEN.getAuctionPrice(_tokenId);
    uint256 highestbidvalue;
    address highestbidbuyer;
    (highestbidvalue, highestbidbuyer) = NFTTOKEN.getHighestBidInfo(_tokenId);
    require(NFTTOKEN.getAuctionState(_tokenId) == true,"The product is not available");
    require(block.timestamp <= _TIME,"The auction is finished");
    require(msg.value >= _PRICE,"balance is not adequate");
    require(msg.value > highestbidvalue,"require more etd to acquire the product");
    payable(highestbidbuyer).transfer(highestbidvalue);
    NFTTOKEN.setHighestBidInfo(_tokenId, msg.value, msg.sender);
    emit AuctionNFT(_tokenId, msg.sender, msg.value);
  }

  function revealAuction(uint256 _tokenId) payable public{
    // Bid opening function When the time is up, the bid can be opened
    require(NFTTOKEN.getAuctionState(_tokenId) == true,"The product is not available");
    uint256  _TIME = NFTTOKEN.getAuctionTime(_tokenId);
    require(block.timestamp > _TIME,"THE AUCTION IS NOT FINISHED");//the auction time is not due;
    address  _owner= NFTTOKEN._getOwner(_tokenId);
    uint256 highestbidvalue;
    address highestbidbuyer;
    (highestbidvalue, highestbidbuyer) = NFTTOKEN.getHighestBidInfo(_tokenId);
    nftSold(_tokenId);
    require(highestbidbuyer != address(0),"ERROR ADDRESS");
      payable(_owner).transfer(highestbidvalue);
      NFTTOKEN.safeTransferFrom(_owner,highestbidbuyer,_tokenId,1,"");
      NFTTOKEN._setOwner(_tokenId,highestbidbuyer);
  }
  

  function getTokenInfo(uint256 tokenId) public view returns (TokenInfo memory){
    require(NFTTOKEN._getOwner(tokenId) != address(0),"The Token is not exist!");
    TokenInfo memory tokeninfo;
    tokeninfo._isSell = NFTTOKEN.getSaleState(tokenId);
    tokeninfo._isAuction = NFTTOKEN.getAuctionState(tokenId);
    tokeninfo._price = NFTTOKEN.getImagePrice(tokenId);
    tokeninfo._tokenId = tokenId;
    tokeninfo._name = NFTTOKEN.name(tokenId);
    tokeninfo._symbol = NFTTOKEN.symbol(tokenId);
    tokeninfo._uri = NFTTOKEN.uri(tokenId);
    tokeninfo._owner = NFTTOKEN._getOwner(tokenId);
    tokeninfo._aucPrice = NFTTOKEN.getAuctionPrice(tokenId);
    tokeninfo._aucTime = NFTTOKEN.getAuctionTime(tokenId); 
    tokeninfo._collectionnId = NFTTOKEN.getCollectionId(tokenId);
    return tokeninfo;
  }
  
  function getNftAddress() view public onlyOwner returns(address){
    return address(NFTTOKEN);
  }
 
  function getRecentTokens() view public returns(uint256[50] memory){
    return recentTokens;
  }
}