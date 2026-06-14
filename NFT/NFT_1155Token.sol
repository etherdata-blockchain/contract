// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./erc1155.sol";
import "./SafeMath.sol";

contract NFT_ERC1155 is ERC1155,ERC1155Metadata_URI{
   using SafeMath for uint256;
   
   event BoughtNFT(uint256 _tokenId, address _buyer, uint256 _price);
   event AuctionNFT(uint256 _tokenId, address _buyer, uint256 _price);
   
   struct BidInfo {//竞标信息
       address buyer;
       uint256 value;
   }
   
   mapping(uint256 => mapping(uint256 => uint256)) imagePrice;
   struct auctionData { 
    uint256 price;
    uint256 time;
    BidInfo HighestBid;
   }
   mapping(uint256 => mapping(uint256 => auctionData)) tokenAuction; 
   //拍卖NFT信息

    enum Tokenstatus{ pending, onsell, onauction}
    struct allTokenstatus {
       uint256 tokenId;
     //  mapping(uint256 => Tokenstatus) status;
       uint256 totalSupply;

       address originOwner;

    }

    allTokenstatus[] allTokens;
    mapping(uint256 => uint256) allTokensindex;
    mapping(uint256 => mapping (uint256 => Tokenstatus)) status;
    //所有Token的信息

    struct TokenInfo{
      string name;
      string symbol;
      string tokenURI;
      address originOwner;
      uint256 totalSupply; 
    }


    mapping(uint256 => string) internal _name;
    mapping(uint256 => string) internal _symbol;
    mapping(uint256 => string) internal tokenURIs;
    //Metadata

    mapping(uint256 => mapping(uint256 => address)) internal tokenOwners;

    address admin;
    constructor(address Admin){admin = Admin;}

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
    

    function AddToken(string memory name_, string memory symbol_, uint256 _tokenId, uint256 _amount, bytes memory data,string memory _uri) public {
        _mint(msg.sender,_tokenId,_amount,data);
        _name[_tokenId] = name_;
        _symbol[_tokenId] = symbol_;
        _setURI(_tokenId,_uri);
        allTokenstatus memory x;
        x.originOwner = msg.sender;
        x.tokenId = _tokenId;
        x.totalSupply = _amount;
        allTokens.push(x);
        allTokensindex[_tokenId] = allTokens.length - 1;
    }

    function _setURI(uint256 _id,string memory _uri)  internal {
       tokenURIs[_id] = _uri;
    }

    function _setOwner(uint256 _id, uint256 _order, address _owner) internal {
        require (_getOwner(_id,_order) == msg.sender || operatorApproval[_getOwner(_id,_order)][msg.sender] == true,"Is not owner!");
        tokenOwners[_id][_order] = _owner;
    }

    function TransferToken(address _from, address _to, uint256 _id, uint256[] calldata _order, bytes calldata data) external {
        for (uint i=0; i<_order.length; i++){
          if (msg.sender == _from &&  status[_id][_order[i]] != Tokenstatus.pending){
            revert("The token is locked!");
          }
          _setOwner(_id, _order[i], _to);
        }
        safeTransferFrom(_from, _to, _id, _order.length, data);
    }

    function _getOwner(uint256 _id, uint256 _order) public view returns (address){
        require(allTokens[allTokensindex[_id]].originOwner != address(0), "No NFT!");
        if (tokenOwners[_id][_order] == address(0)) return allTokens[allTokensindex[_id]].originOwner;
        else return tokenOwners[_id][_order];
    }

    function setNFTPrice(uint256 _id, uint256 _order, uint256 _price) internal {
           require(_getOwner(_id, _order) == msg.sender ,"not owner!");
           imagePrice[_id][_order] = _price;
    }

    function getNFTPrice(uint256 _id, uint256 _order) public view returns (uint256){
        return imagePrice[_id][_order];
    }
    
    function setSaleState(uint256 _id, uint256 _order, bool isSale) internal{
        require(_getOwner(_id,_order) == msg.sender || operatorApproval[_getOwner(_id,_order)][msg.sender] == true,"not owner!");
        if (isSale == true){
              status[_id][_order] = Tokenstatus.onsell;
              /*
              if (_listedForSale[_id][_order] == 0){
                 SaleTokens[_id].push(_order);
                 _listedForSale[_id][_order] = SaleTokens[_id].length-1; 
              }
              else{
                 SaleTokens[_id][_listedForSale[_id][_order]] = _order;
              }
              SaleTokens[_id][0]=SaleTokens[_id][0].add(1); pendingTokens[_id][0]=pendingTokens[_id][0].sub(1);
              delete pendingTokens[_id][_indexForPending[_id][_order]];
              */
        }
        else {
             status[_id][_order] = Tokenstatus.pending;
             /*
             pendingTokens[_id][_indexForPending[_id][_order]] = _order;
             pendingTokens[_id][0]=pendingTokens[_id][0].add(1); SaleTokens[_id][0]=SaleTokens[_id][0].sub(1);
             delete SaleTokens[_id][_listedForSale[_id][_order]];
             */
        }
    }
    
    function updatePrice(uint _id, uint256 _order, uint _price) public returns (bool){
      require(_getOwner(_id,_order) == msg.sender,"not owner!");
      require(getSaleState(_id, _order) == Tokenstatus.onsell,"the product is pending or at auction");
      setNFTPrice(_id, _order, _price);
      return true;
  }

    function approveForSale(uint256 _tokenId, uint256 _order, uint _price) public {
        require(_getOwner(_tokenId,_order) == msg.sender,"not owner!");
        require(getSaleState(_tokenId,_order) == Tokenstatus.pending,"the product is not pending");
        setSaleState(_tokenId, _order, true);
        updatePrice(_tokenId, _order, _price);
        operatorApproval[msg.sender][admin] = true;
        emit ApprovalForAll(msg.sender, admin, true);
    }

    function approveForAuction(uint _tokenId, uint _order, uint _price, uint _time) public {
      require(_getOwner(_tokenId, _order) == msg.sender,"not owner!");
      require(getSaleState(_tokenId, _order) == Tokenstatus.pending,"the product is not pending");
      setAuctionState(_tokenId, _order, true);
      setAuctionInfo(_tokenId, _order, _price, block.timestamp + _time);
      operatorApproval[msg.sender][admin] = true;
      emit ApprovalForAll(msg.sender, admin, true);
  }

  function withDrawToken(uint _tokenId, uint _order) public {
    require(_getOwner(_tokenId, _order) == msg.sender,"not owner!");
    require(getSaleState(_tokenId, _order) != Tokenstatus.pending,"the product is pending");
    operatorApproval[msg.sender][admin] = false;
    if (getSaleState(_tokenId, _order) == Tokenstatus.onauction){
       uint256 highestbidvalue;
       address highestbidbuyer;
       (highestbidvalue, highestbidbuyer) = getHighestBidInfo(_tokenId, _order);
       payable(highestbidbuyer).transfer(highestbidvalue);
    }
    status[_tokenId][_order] = Tokenstatus.pending;
  }

    function getSaleState(uint256 _id, uint256 _order) public view returns (Tokenstatus){
        return status[_id][_order];
    }
    
    function nftSold(uint _tokenId, uint _order) internal {
       if (getSaleState(_tokenId, _order) == Tokenstatus.onsell){
          setSaleState(_tokenId, _order, false);
       }
       if (getSaleState(_tokenId, _order) == Tokenstatus.onauction){
          setAuctionState(_tokenId, _order, false);
       }
  }


    function buyToken1155(uint256 _tokenId, uint256 _order) public payable {
        uint256 _price = imagePrice[_tokenId][_order];
        require(getSaleState(_tokenId, _order) == Tokenstatus.onsell,"The product is not available");
        require(msg.value >= _price,"too less etd");
        payable(msg.sender).transfer(msg.value - _price);

        address  _owner= _getOwner(_tokenId,_order);
        payable(_owner).transfer(_price);
        //safeTransferFrom(_owner,msg.sender,_tokenId,1,"");
        //_setOwner(_tokenId, _order, msg.sender);
        
        status[_tokenId][_order] = Tokenstatus.pending;

        /*
        pendingTokens[_tokenId][_indexForPending[_tokenId][_order]] = _order;
        pendingTokens[_tokenId][0]=pendingTokens[_tokenId][0].add(1); SaleTokens[_tokenId][0]=SaleTokens[_tokenId][0].sub(1);
        delete SaleTokens[_tokenId][_listedForSale[_tokenId][_order]];
        */

       
        emit BoughtNFT(_tokenId, msg.sender, _price);

      }

    function setAuctionState(uint256 _id, uint256 _order, bool isAuction) internal {
        require(_getOwner(_id, _order) == msg.sender || operatorApproval[tokenOwners[_id][_order]][msg.sender] == true,"not owner!");
        if (isAuction == true){
            status[_id][_order] = Tokenstatus.onauction;
            /*
            if (_listedForAuction[_id][_order] == 0){
               AucTokens[_id].push(_id);
               _listedForAuction[_id][_order] = AucTokens[_id].length-1;
            }
            else{
               AucTokens[_id][_listedForAuction[_id][_order]] = _order;
            }
            AucTokens[_id][0]=AucTokens[_id][0].add(1); pendingTokens[_id][0]=pendingTokens[_id][0].sub(1);
            delete pendingTokens[_id][_indexForPending[_id][_order]];
            */
        }
        else {
            status[_id][_order] = Tokenstatus.pending;
            /*
            pendingTokens[_id][_indexForPending[_id][_order]] = _order;
            pendingTokens[_id][0]=pendingTokens[_id][0].add(1); AucTokens[_id][0]=AucTokens[_id][0].sub(1);
            delete AucTokens[_id][_listedForAuction[_id][_order]];
            */
        }
    }
    
    function setAuctionInfo(uint256 _id, uint256 _order, uint256 _price, uint256 _time) internal{
        require(_getOwner(_id, _order) == tx.origin ,"not owner!");
        tokenAuction[_id][_order].price = _price;
        tokenAuction[_id][_order].time = _time;
        delete tokenAuction[_id][_order].HighestBid;
    }
    
    function getAuctionPrice(uint256 _id, uint256 _order) public view returns (uint256){
        return tokenAuction[_id][_order].price;
    }

    function getAuctionTime(uint256 _id, uint256 _order) public view returns (uint256){
        return tokenAuction[_id][_order].time;
    }
    
    function AuctionToken1155(uint256 _tokenId, uint256 _order) public payable {
    uint256  _TIME = getAuctionTime(_tokenId, _order);
    uint256  _PRICE =getAuctionPrice(_tokenId, _order);
    uint256 highestbidvalue;
    address highestbidbuyer;
    (highestbidvalue, highestbidbuyer) = getHighestBidInfo(_tokenId, _order);
    require(getSaleState(_tokenId, _order) == Tokenstatus.onauction,"The product is not available");
    require(block.timestamp <= _TIME,"The auction is finished");
    require(msg.value >= _PRICE,"balance is not adequate");
    require(msg.value > highestbidvalue,"require more etd to acquire the product");
    payable(highestbidbuyer).transfer(highestbidvalue);
    setHighestBidInfo(_tokenId, _order, msg.value, msg.sender);
    emit AuctionNFT(_tokenId, msg.sender, msg.value);
  }

  function revealAuction(uint256 _tokenId, uint256 _order) payable public returns(uint256,address){
    // Bid opening function When the time is up, the bid can be opened
    require(getSaleState(_tokenId, _order) == Tokenstatus.onauction,"The product is not available");
    uint256  _TIME = getAuctionTime(_tokenId, _order);
    require(block.timestamp > _TIME,"THE AUCTION IS NOT FINISHED");//the auction time is not due;
    address  _owner= _getOwner(_tokenId, _order);
    uint256 highestbidvalue;
    address highestbidbuyer;
    (highestbidvalue, highestbidbuyer) = getHighestBidInfo(_tokenId, _order);
    require(highestbidbuyer != address(0),"ERROR ADDRESS");
    
    status[_tokenId][_order] = Tokenstatus.pending;
    /*
    pendingTokens[_tokenId][_indexForPending[_tokenId][_order]] = _order;
    pendingTokens[_tokenId][0]=pendingTokens[_tokenId][0].add(1); AucTokens[_tokenId][0]=AucTokens[_tokenId][0].sub(1);
    delete AucTokens[_tokenId][_listedForAuction[_tokenId][_order]];
    */

    payable(_owner).transfer(highestbidvalue);
    //safeTransferFrom(_owner,highestbidbuyer,_tokenId,1,"");
    //_setOwner(_tokenId, _order, highestbidbuyer);
    return (highestbidvalue, highestbidbuyer);
  }

    function getOnSaleList(uint256 _id) external view returns (uint256, uint256[] memory){
       uint256 sum=0;uint256 j=0;
       for (uint i =1; i<=allTokens[allTokensindex[_id]].totalSupply; i++){
          if (status[_id][i] == Tokenstatus.onsell)sum++;
        }
        uint256[] memory tokens = new uint256[](sum);
        for (uint i =1; i<=allTokens[allTokensindex[_id]].totalSupply; i++){
          if (status[_id][i] == Tokenstatus.onsell)tokens[j++] = i;
        }
        return (sum, tokens);
    }

    function getAuctionList(uint256 _id) external view returns (uint256, uint256[] memory){
       uint256 sum=0;uint256 j=0;
       for (uint i =1; i<=allTokens[allTokensindex[_id]].totalSupply; i++){
          if (status[_id][i] == Tokenstatus.onauction)sum++;
        }
        uint256[] memory tokens = new uint256[](sum);
        for (uint i =1; i<=allTokens[allTokensindex[_id]].totalSupply; i++){
          if (status[_id][i] == Tokenstatus.onauction)tokens[j++] = i;
        }
        return (sum, tokens);
    }

    function getHighestBidInfo(uint256 _id, uint256 _order) public view returns (uint256, address){
        return (tokenAuction[_id][_order].HighestBid.value, tokenAuction[_id][_order].HighestBid.buyer);
    }

    function setHighestBidInfo(uint256 _id, uint256 _order, uint256 _value, address _buyer) private {
        //require(_getOwner(_id, _order) == tx.origin || operatorApproval[tokenOwners[_id][_order]][msg.sender] == true,"not owner!");
        tokenAuction[_id][_order].HighestBid.value = _value;
        tokenAuction[_id][_order].HighestBid.buyer = _buyer;
    }

    function getAllTokens() public view returns(allTokenstatus[] memory){
        return allTokens;
    }
    
    function getTokenInfo(uint256 _tokenId) external view returns(TokenInfo memory){
      TokenInfo memory x;
      x.totalSupply = allTokens[allTokensindex[_tokenId]].totalSupply;
      x.originOwner = allTokens[allTokensindex[_tokenId]].originOwner;
      x.name = _name[_tokenId];
      x.symbol = _symbol[_tokenId];
      x.tokenURI = tokenURIs[_tokenId];
      return x;
    }

    function getPendingList(uint256 _id) external view returns (uint256,uint256[] memory){
       uint256 sum=0;uint256 j=0;
       for (uint i =1; i<=allTokens[allTokensindex[_id]].totalSupply; i++){
          if (status[_id][i] == Tokenstatus.pending)sum++;
        }
        uint256[] memory tokens = new uint256[](sum);
        for (uint i =1; i<=allTokens[allTokensindex[_id]].totalSupply; i++){
          if (status[_id][i] == Tokenstatus.pending)tokens[j++] = i;
        }
        return (sum, tokens);
    }
    
    function getBalance(address owner) external view returns(uint256,uint256[] memory){
        uint256 sum=0;
        for (uint i =0;i<allTokens.length;i++){
          if (balances[allTokens[i].tokenId][owner] > 0)sum++;
        }
        uint256[] memory tokens = new uint256[](sum);
        uint j=0;
        for (uint i =0;i<allTokens.length;i++){
          if (balances[allTokens[i].tokenId][owner] > 0){
            tokens[j++] = allTokens[i].tokenId;
          }
        }
        return (sum, tokens);
    }

    function getBalanceOfToken(address owner, uint256 _tokenId) external view returns(uint256,uint256[] memory){
       uint256 sum=0;
       for (uint i =1;i<=allTokens[allTokensindex[_tokenId]].totalSupply;i++){
          if (_getOwner(_tokenId, i) == owner)sum++;
       }
       uint256[] memory tokens = new uint256[](sum);
       uint j=0;
       for (uint i =1;i<=allTokens[allTokensindex[_tokenId]].totalSupply;i++){
          if (_getOwner(_tokenId, i) == owner){
            tokens[j++] = i;
          }
        }
        return (sum,tokens);
    }
}

