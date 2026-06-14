// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Common.sol";
import "./IERC1155TokenReceiver.sol";
import "./IERC1155.sol";
import "./ERC165.sol";
import "./IERC1155Metadata.sol";

// A sample implementation of core ERC1155 function.
contract ERC1155 is IERC1155, ERC165, CommonConstants, ERC1155Metadata_URI
{
    using SafeMath for uint256;
    using Address for address;

    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;

/////////////////////////////////////////// ERC165 //////////////////////////////////////////////

    /*
        bytes4(keccak256('supportsInterface(bytes4)'));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /*
        bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
        bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
        bytes4(keccak256("balanceOf(address,uint256)")) ^
        bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
        bytes4(keccak256("setApprovalForAll(address,bool)")) ^
        bytes4(keccak256("isApprovedForAll(address,address)"));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceId) external pure returns (bool) {
         if (_interfaceId == INTERFACE_SIGNATURE_ERC165 ||
             _interfaceId == INTERFACE_SIGNATURE_ERC1155) {
            return true;
         }

         return false;
    }
/////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */

    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {

        require(_to != address(0x0), "_to must be non-zero.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");
        if (allTokens[tokenFromCollection[_id]][allTokensindex[_id]].status != Tokenstatus.pending && msg.sender ==  _from){
            revert("The Token is locked!");
        }
        // SafeMath will throw with insuficient funds _from
        // or if _id is not valid (balance will be 0)
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to]   = _value.add(balances[_id][_to]);
        tokenOwners[_id] = _to;
        // MUST emit event
        emit TransferSingle(msg.sender, _from, _to, _id, _value);

        // Now that the balance is updated and the event was emitted,
        // call onERC1155Received if the destination is a contract.
        if (_to.isContract()) {
            _doSafeTransferAcceptanceCheck(msg.sender, _from, _to, _id, _value, _data);
        }
    }

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external {
      
        // MUST Throw on errors
        require(_to != address(0x0), "destination address must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array length must match.");
        require(_from == msg.sender || operatorApproval[_from][msg.sender] == true, "Need operator approval for 3rd party transfers.");
        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];
            if (allTokens[tokenFromCollection[id]][allTokensindex[id]].status != Tokenstatus.pending && msg.sender ==  _from){
            revert("The Token is locked!");
            }
            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to]   = value.add(balances[id][_to]);
            tokenOwners[id] = _to;
        }

        // Note: instead of the below batch versions of event and acceptance check you MAY have emitted a TransferSingle
        // event and a subsequent call to _doSafeTransferAcceptanceCheck in above loop for each balance change instead.
        // Or emitted a TransferSingle event for each in the loop and then the single _doSafeBatchTransferAcceptanceCheck below.
        // However it is implemented the balance changes and events MUST match when a check (i.e. calling an external contract) is done.

        // MUST emit event
        emit TransferBatch(msg.sender, _from, _to, _ids, _values);

        // Now that the balances are updated and the events are emitted,
        // call onERC1155BatchReceived if the destination is a contract.
        if (_to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(msg.sender, _from, _to, _ids, _values, _data);
        }
    }

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return balances[_id][_owner];
    }


    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external  view returns (uint256[] memory) {

        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external {
        operatorApproval[tx.origin][_operator] = _approved;
        emit ApprovalForAll(tx.origin, _operator, _approved);
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }

/////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _doSafeTransferAcceptanceCheck(address _operator, address _from, address _to, uint256 _id, uint256 _value, bytes memory _data) internal {

        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.


        // Note: if the below reverts in the onERC1155Received function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_ACCEPTED test.
        require(ERC1155TokenReceiver(_to).onERC1155Received(_operator, _from, _id, _value, _data) == ERC1155_ACCEPTED, "contract returned an unknown value from onERC1155Received");
    }

    function _doSafeBatchTransferAcceptanceCheck(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _values, bytes memory _data) internal {

        // If this was a hybrid standards solution you would have to check ERC165(_to).supportsInterface(0x4e2312e0) here but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. _to isn't a receiver, or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.

        // Note: if the below reverts in the onERC1155BatchReceived function of the _to address you will have an undefined revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level _to.call() style instead so the revert does not bubble up and you can revert yourself on the ERC1155_BATCH_ACCEPTED test.
        require(ERC1155TokenReceiver(_to).onERC1155BatchReceived(_operator, _from, _ids, _values, _data) == ERC1155_BATCH_ACCEPTED, "contract returned an unknown value from onERC1155BatchReceived");
    }

    function _mint(address to,uint256 id,uint256 amount,bytes memory data) internal  {
        require(to != address(0), "ERC1155: mint to the zero address");
        address operator = msg.sender;
        balances[id][to] += amount.add(balances[id][to]);
        emit TransferSingle(operator, address(0), to, id, amount);
        if (to.isContract()) {
        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
        }
    }

    function _mintBatch(address to,uint256[] memory ids,uint256[] memory amounts,bytes memory data) internal {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = msg.sender;

        for (uint256 i = 0; i < ids.length; i++) {
            balances[ids[i]][to] = amounts[i].add(balances[ids[i]][to]);
        }
        emit TransferBatch(operator, address(0), to, ids, amounts);
        if (to.isContract()) {
        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
        }
    }

/////////////////////////////////////////// Token /////////////////////////////////////////////////////////////////////////
   using SafeMath for uint256;

   struct Collection {
       address owner;
       uint256[] allTokens;
       string uri;
       string name;
   }
   mapping(uint256 => uint256) tokenFromCollection;
   uint256[] public allCollection;
   mapping(uint256 => Collection) Collections;
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

/*
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
    */

    mapping(uint256 => string) internal _name;
    mapping(uint256 => string) internal _symbol;
 

    mapping(uint256 => string) internal tokenURIs;
    mapping(uint256 => address) internal tokenOwners;
    
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
    
    function Addcollection(string memory name_, uint256 collectionId, string memory _uri) public {
        require(msg.sender == admin,"You are not allowed to use this API");
        Collections[collectionId].owner = tx.origin;
        Collections[collectionId].name = name_;
        Collections[collectionId].uri = _uri;
        allCollection.push(collectionId);
        //SaleTokens[collectionId].push(0);
        //AucTokens[collectionId].push(0);
        //pendingTokens[collectionId].push(0);
    }


    function AddToken(string memory name_, string memory symbol_, uint256 _tokenId,bytes memory data,string memory _uri, uint256 collectionId) public {
        require(msg.sender == admin,"You are not allowed to use this API");
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
        //pendingTokens[collectionId].push(_tokenId);
        //_indexForPending[_tokenId] = pendingTokens[collectionId].length - 1; 
        //pendingTokens[collectionId][0]++;
        Collections[collectionId].allTokens.push(_tokenId);
        tokenFromCollection[_tokenId] = collectionId;
    }

    function _setURI(uint256 _id,string memory _uri)  internal {
       tokenURIs[_id] = _uri;
    }

    /*
    function _setOwner(uint256 _id,address _owner) external {
        require (tokenOwners[_id] == msg.sender || operatorApproval[tokenOwners[_id]][msg.sender] == true,"Is not owner!");
        tokenOwners[_id] = _owner;
    }
*/
    function _getOwner(uint256 _id) public view returns (address){
        return tokenOwners[_id];
    }
    
    function setNFTPrice(uint256 _id, uint256 _price) external {
        require(_getOwner(_id) == tx.origin,"not owner!");
        require(allTokens[tokenFromCollection[_id]][allTokensindex[_id]].status != Tokenstatus.onauction,"the product is auction");
        imagePrice[_id] = _price;
    }

    function getNFTPrice(uint256 _id) external view returns (uint256){
        return imagePrice[_id];
    }
    
    function setSaleState(uint256 _id, bool isSale) external {
        require(_getOwner(_id) == tx.origin,"not owner!");
        uint256 collectionId = tokenFromCollection[_id];
        if (isSale == true){
            allTokens[collectionId][allTokensindex[_id]].status = Tokenstatus.onsell;
            /*
            if (_listedForSale[_id].index == 0){
               SaleTokens[collectionId].push(_id);
               _listedForSale[_id].index = SaleTokens[collectionId].length-1; 
            }
            else{
               SaleTokens[collectionId][_listedForSale[_id].index] = _id;
            }
            SaleTokens[collectionId][0]=SaleTokens[collectionId][0].add(1); pendingTokens[collectionId][0]=pendingTokens[collectionId][0].sub(1);
            delete pendingTokens[collectionId][_indexForPending[_id]];
            */
        }
        else {
             allTokens[collectionId][allTokensindex[_id]].status = Tokenstatus.pending;
             /*
             pendingTokens[collectionId][_indexForPending[_id]] = _id;
             pendingTokens[collectionId][0]=pendingTokens[collectionId][0].add(1); SaleTokens[collectionId][0]=SaleTokens[collectionId][0].sub(1);
             delete SaleTokens[collectionId][_listedForSale[_id].index];
             */
        }
       // _listedForSale[_id].isOnSale = isSale;
    }

    function getSaleState(uint256 _id) external view returns (bool){
        if (allTokens[tokenFromCollection[_id]][allTokensindex[_id]].status == Tokenstatus.onsell)
           return true;
        else 
           return false;
        //return _listedForSale[_id].isOnSale;
    }

    function setAuctionState(uint256 _id, bool isAuction) external {
        require(_getOwner(_id) == tx.origin,"not owner!");
        uint256 collectionId = tokenFromCollection[_id];
        if (isAuction == true){
            allTokens[collectionId][allTokensindex[_id]].status = Tokenstatus.onauction;
            /*
            if (_listedForAuction[_id].index == 0){
               AucTokens[collectionId].push(_id);
               _listedForAuction[_id].index = AucTokens[collectionId].length-1;
            }
            else{
               AucTokens[collectionId][_listedForAuction[_id].index] = _id;
            }
            AucTokens[collectionId][0]=AucTokens[collectionId][0].add(1); pendingTokens[collectionId][0]=pendingTokens[collectionId][0].sub(1);
            delete pendingTokens[collectionId][_indexForPending[_id]];
            */
        }
        else {
            allTokens[collectionId][allTokensindex[_id]].status = Tokenstatus.pending;
            /*
            pendingTokens[collectionId][_indexForPending[_id]] = _id;
            pendingTokens[collectionId][0]=pendingTokens[collectionId][0].add(1); AucTokens[collectionId][0]=AucTokens[collectionId][0].sub(1);
            delete AucTokens[collectionId][_listedForAuction[_id].index];
            */
        }
       // _listedForAuction[_id].isOnSale = isAuction;
    }
    
    function getAuctionState(uint256 _id) external view returns (bool) {
        if (allTokens[tokenFromCollection[_id]][allTokensindex[_id]].status == Tokenstatus.onauction)
           return true;
        else 
           return false;
        //return _listedForAuction[_id].isOnSale;
    }

    function setAuctionInfo(uint256 _id, uint256 _price, uint256 _time) external{
        require(msg.sender == admin,"You are not allowed to use this API");
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
        //return SaleTokens;
        uint256 sum = 0;
       for (uint i =0; i<allTokens[collectionId].length; i++){
          if (allTokens[collectionId][i].status == Tokenstatus.onsell){
             sum++;
          }
       }
       uint256[] memory tokens = new uint256[](sum);
       uint j=0;
       for (uint i =0; i<allTokens[collectionId].length; i++){
          if (allTokens[collectionId][i].status == Tokenstatus.onsell){
             tokens[j++]= i;
          }
       }
       return tokens;
    }

    function getAuctionList(uint256 collectionId) external view returns (uint256[] memory){
        //return AucTokens;
         uint256 sum = 0;
       for (uint i=0; i<allTokens[collectionId].length; i++){
          if (allTokens[collectionId][i].status == Tokenstatus.onauction){
             sum++;
          }
       }
       uint256[] memory tokens = new uint256[](sum);
       uint j=0;
       for (uint i=0; i<allTokens[collectionId].length; i++){
          if (allTokens[collectionId][i].status == Tokenstatus.onauction){
             tokens[j++]= i;
          }
       }
       return tokens;
    }

    function getHighestBidInfo(uint256 _id) external view returns (uint256, address){
        return (tokenAuction[_id].HighestBid.value, tokenAuction[_id].HighestBid.buyer);
    }

    function setHighestBidInfo(uint256 _id, uint256 _value, address _buyer) external {
        require(msg.sender == admin,"You are not allowed to use this API");
        //require(_getOwner(_id) == tx.origin || operatorApproval[tokenOwners[_id]][msg.sender] == true,"not owner!");
        tokenAuction[_id].HighestBid.value = _value;
        tokenAuction[_id].HighestBid.buyer = _buyer;
    }

    function getAllTokens(uint256 CollectionId) public view returns(allTokenstatus[] memory){
        return allTokens[CollectionId];
    }

    function getPendingList(uint256 collectionId) external view returns (uint256[] memory){
        //return pendingTokens[collectionId];
         uint256 sum = 0;
       for (uint i =0; i<allTokens[collectionId].length; i++){
          if (allTokens[collectionId][i].status == Tokenstatus.pending){
             sum++;
          }
       }
       uint256[] memory tokens = new uint256[](sum);
       uint j=0;
       for (uint i =0; i<allTokens[collectionId].length; i++){
          if (allTokens[collectionId][i].status == Tokenstatus.pending){
             tokens[j++]= i;
          }
       }
       return tokens;
    }
    
    function getCollectionId(uint256 _tokenId) external view returns(uint256){
        return tokenFromCollection[_tokenId];
    }

    function getCollectionsNum() external view returns(uint256){
        return allCollection.length;
    }

    function getCollectionInfo(uint256 _collectionnId) external view returns(Collection memory){
        return Collections[_collectionnId];
    }
    
    function getOwnersTokens(address _owner) external  view returns(uint sum,uint256[] memory){
        for (uint i=0; i<allCollection.length;i++){
            for (uint j=0; j<=allTokens[allCollection[i]].length;j++){
                if (tokenOwners[allTokens[allCollection[i]][j].tokenId] == _owner) sum++;
            }
        }
        uint256[] memory tokens = new uint256[](sum);
        uint k=0;
        for (uint i=0; i<allCollection.length;i++){
            for (uint j=0; j<=allTokens[allCollection[i]].length;j++){
                if (tokenOwners[allTokens[allCollection[i]][j].tokenId] == _owner){
                    tokens[k++] = allTokens[allCollection[i]][j].tokenId;
                }
            }
        }
        return (sum, tokens);
    }
}