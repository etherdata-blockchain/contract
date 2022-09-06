// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import   "./ERC1155.sol";
import   "./SafeMath.sol";
import   "./ERC165.sol";
import   "./ERC721.sol";

contract ImageContract{
  mapping(address => uint256[]) OwnersCollections;
  mapping(uint256 => address) TokensFromContract;
  mapping(uint256 => address) CollectionFromContract;
 /*
  mapping(address => uint256[]) OwnersTokens;
  mapping(address => uint256) OwnersTokensNum;
  mapping(uint256 => uint256) TokensIndex;
*/
  address[] allContract;

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

  //NFT_MINT NFTTOKEN;
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

  function AddCollection(string memory name_, uint256 collectionId, string memory _uri) public {
         if (allContract.length == 0){
           ERC1155 A = new ERC1155(admin);
           allContract.push(address(A));
         }
        ERC1155 NFTTOKEN = ERC1155(allContract[allContract.length-1]);
        if (NFTTOKEN.getCollectionsNum()>=1000){
          ERC1155 A = new ERC1155(admin);
          allContract.push(address(A));
        }
         NFTTOKEN = ERC1155(allContract[allContract.length-1]);
         NFTTOKEN.Addcollection(name_,collectionId,_uri);
         OwnersCollections[msg.sender].push(collectionId);
         CollectionFromContract[collectionId] = address(NFTTOKEN);
  }

/*
  function isNeedChangeContract() external  returns (bool){
        if (allContract.length == 0){
           ERC1155 A = new ERC1155(admin);
           allContract.push(address(A));
           return true;
         }
        ERC1155 NFTTOKEN = ERC1155(allContract[allContract.length-1]);
        if (NFTTOKEN.getCollectionsNum() <1000) return false;
        else {
          ERC1155 A = new ERC1155(admin);
          allContract.push(address(A));
          return true;
        }
  }
*/
  function addToken(string memory name_, string memory symbol_, uint256 _tokenId,bytes memory data,string memory _uri, uint256 collectionId) public {
         require(TokensFromContract[_tokenId] == address(0), "The Token is exist");
         require(CollectionFromContract[collectionId] != address(0), "The Collection is not exist!");
         ERC1155 NFTTOKEN = ERC1155(CollectionFromContract[collectionId]);
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
         TokensFromContract[_tokenId] = address(NFTTOKEN);
         
         /*
         OwnersTokensNum[msg.sender]++;
         TokensIndex[_tokenId] = OwnersTokens[msg.sender].length;
         OwnersTokens[msg.sender].push(_tokenId);   
         */
  }
  


  function updatePrice(uint _id, uint _price) public returns (bool){
    ERC1155 NFTTOKEN = ERC1155(TokensFromContract[_id]);
    require(NFTTOKEN._getOwner(_id) == msg.sender,"not owner!");
    require(NFTTOKEN.getAuctionState(_id) == false,"the product is auction");
    NFTTOKEN.setNFTPrice(_id,_price);
    return true;
  }

  function approveForSale(uint _tokenId, uint _price) public {
    ERC1155 NFTTOKEN = ERC1155(TokensFromContract[_tokenId]);
    require(NFTTOKEN._getOwner(_tokenId) == msg.sender,"not owner");
    require(NFTTOKEN.getAuctionState(_tokenId) == false,"the product is auction");
    require(NFTTOKEN.getSaleState(_tokenId) == false,"the product is selling");
    NFTTOKEN.setSaleState(_tokenId, true);
    updatePrice(_tokenId,_price);
    NFTTOKEN.setApprovalForAll(admin, true);
  }

  function approveForAuction(uint _tokenId, uint _price, uint _time) public {
    ERC1155 NFTTOKEN = ERC1155(TokensFromContract[_tokenId]);
    require(NFTTOKEN._getOwner(_tokenId) == msg.sender,"not owner!");
    require(NFTTOKEN.getSaleState(_tokenId) == false,"the product is selling");
    require(NFTTOKEN.getAuctionState(_tokenId) == false,"the product is auction");
    NFTTOKEN.setAuctionState(_tokenId, true);
    NFTTOKEN.setAuctionInfo(_tokenId, _price, block.timestamp + _time);
    NFTTOKEN.setApprovalForAll(admin, true);
    //approveNFT(admin,true);
  }

  function nftSold(uint _tokenId) internal {
    ERC1155 NFTTOKEN = ERC1155(TokensFromContract[_tokenId]);
    if (NFTTOKEN.getSaleState(_tokenId) == true){
      NFTTOKEN.setSaleState(_tokenId, false);
    }
    if (NFTTOKEN.getAuctionState(_tokenId) == true){
      NFTTOKEN.setAuctionState(_tokenId, false);
    }
  }
  
  function buyImage(uint256 _tokenId) public payable {
      ERC1155 NFTTOKEN = ERC1155(TokensFromContract[_tokenId]);
      uint256  _price =  NFTTOKEN.getNFTPrice(_tokenId);
      require(NFTTOKEN.getSaleState(_tokenId) == true,"The product is not available");
      require(msg.value >= _price,"too less etd");
      payable(msg.sender).transfer(msg.value - _price);

      address  _owner= NFTTOKEN._getOwner(_tokenId);
      payable(_owner).transfer(_price);
      NFTTOKEN.safeTransferFrom(_owner,msg.sender,_tokenId,1,"");
      //NFTTOKEN._setOwner(_tokenId,msg.sender);
      nftSold(_tokenId);
      
      /*
      delete(OwnersTokens[_owner][TokensIndex[_tokenId]]);
      OwnersTokensNum[_owner]--;
      OwnersTokensNum[msg.sender]++;
      OwnersTokens[msg.sender].push(_tokenId);
      TokensIndex[_tokenId] = OwnersTokens[msg.sender].length-1;
       */

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
    ERC1155 NFTTOKEN = ERC1155(TokensFromContract[_tokenId]);
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
    ERC1155 NFTTOKEN = ERC1155(TokensFromContract[_tokenId]);
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
    //NFTTOKEN._setOwner(_tokenId,highestbidbuyer);

     /*
     delete(OwnersTokens[ _owner][TokensIndex[_tokenId]]);
     OwnersTokensNum[ _owner]--;
     OwnersTokensNum[highestbidbuyer]++;
     OwnersTokens[highestbidbuyer].push(_tokenId);
     TokensIndex[_tokenId] = OwnersTokens[highestbidbuyer].length-1;
     */
  }
  

  function getTokenInfo(uint256 tokenId) public view returns (TokenInfo memory){
    require(TokensFromContract[tokenId] != address(0),"The Token is not exist!");
    ERC1155 NFTTOKEN = ERC1155(TokensFromContract[tokenId]);
    require(NFTTOKEN._getOwner(tokenId) != address(0),"The Token is not exist!");
    TokenInfo memory tokeninfo;
    tokeninfo._isSell = NFTTOKEN.getSaleState(tokenId);
    tokeninfo._isAuction = NFTTOKEN.getAuctionState(tokenId);
    tokeninfo._price = NFTTOKEN.getNFTPrice(tokenId);
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
  /*
  function getNftAddress() view public onlyOwner returns(address){
    return address(NFTTOKEN);
  }
 */
  function getRecentTokens() view public returns(uint256[50] memory){
    return recentTokens;
  }
  function getTokensFrom(uint256 tokenId) view public returns(address){
    require(TokensFromContract[tokenId] != address(0));
    return TokensFromContract[tokenId];
  }
  function getCollectionsFrom(uint256 collectionId) view public returns(address){
    require(CollectionFromContract[collectionId]!= address(0));
    return CollectionFromContract[collectionId];
  }

  function getOwnersTokens(address Owner) view public returns(uint256,uint256[] memory){
    //return (OwnersTokensNum[Owner],OwnersTokens[Owner]); 
  }


}

contract ImplementContract is ImageContract{
    
    address[] Contract721;
   // mapping TokensPrice;
    struct Token721Info{
      uint256 _id;
      address owner;
      string URI;
    }
    constructor(){
    }
    bytes4 internal constant INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;
    bytes4 internal constant INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;
    bytes4 internal constant INTERFACE_SIGNATURE_ERC721 = 0x80ac58cd;
    bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
    bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
    bytes4 private constant InterfaceId_Invalid = 0xffffffff;

    function doesContractImplementInterface(address _contract, bytes4 _interfaceId) internal view returns (bool) {
        uint256 success;
        uint256 result;

        (success, result) = noThrowCall(_contract, INTERFACE_SIGNATURE_ERC165);
        if ((success==0)||(result==0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, InterfaceId_Invalid);
        if ((success==0)||(result!=0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _interfaceId);
        if ((success==1)&&(result==1)) {
            return true;
        }
        return false;
    }

    function noThrowCall(address _contract, bytes4 _interfaceId) internal view returns (uint256 success, uint256 result) {
        bytes4 erc165ID = INTERFACE_SIGNATURE_ERC165;

        assembly {
                let x := mload(0x40)               // Find empty storage location using "free memory pointer"
                mstore(x, erc165ID)                // Place signature at beginning of empty storage
                mstore(add(x, 0x04), _interfaceId) // Place first argument directly next to signature

                success := staticcall(
                                    30000,         // 30k gas
                                    _contract,     // To addr
                                    x,             // Inputs are stored at location x
                                    0x24,          // Inputs are 36 bytes long
                                    x,             // Store output over input (saves space)
                                    0x20)          // Outputs are 32 bytes long

                result := mload(x)                 // Load the result
        }
    }
 
    function Implementation721(address Contract) external returns(uint256,Token721Info[] memory){
      require(doesContractImplementInterface(Contract,INTERFACE_SIGNATURE_ERC165), "Does not support 165");
      require(doesContractImplementInterface(Contract,INTERFACE_SIGNATURE_ERC721)
      &&doesContractImplementInterface(Contract,InterfaceId_ERC721Enumerable), "Does not support 721");
      Contract721.push(Contract);
      Token721Info[] memory all721Token;
      ERC721Enumerable erc721Enumerable = ERC721Enumerable(Contract);
      ERC721basic erc721basic = ERC721basic(Contract);
      ERC721Metadata erc721Metadata = ERC721Metadata(Contract);
      uint256 TokenSum = erc721Enumerable.totalSupply();
      for (uint i=0; i<TokenSum; i++){
          Token721Info memory x;
          x._id = erc721Enumerable.tokenByIndex(i);
          x.owner = erc721basic.ownerOf(x._id);
          x.URI = erc721Metadata.tokenURI(x._id);
          all721Token[i] = x;
      }
      return (TokenSum,all721Token);
    }

   // function buy721Token(address Contract,uint256 tokenId,uint256 price) external payable{
     //    require (msg.value>=price,"Too less ETD");
         
   // }
}