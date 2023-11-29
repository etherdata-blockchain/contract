// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NEWnft is Ownable {
    address private Newcontract;

    function deployNFT(
        string memory _name,
        string memory _symbol,
        address _owner
    ) public returns(address){
        Newcontract = address(new Mycontract(_name, _symbol, _owner));
        return Newcontract;
    }
    function GetContract() public view returns(address){
        return Newcontract;
    }
}

contract Mycontract is ERC721 {
    address public owner;

    constructor(
        string memory name,
        string memory symbol,
        address _owner
    ) ERC721(name, symbol) {
        owner = _owner;
    }

    struct TokenMetadata {
        string name;
        string tokenurl; // tokenurl 属性
        string id;
    }

    mapping(uint256 => TokenMetadata) public tokenMetadata;

    function mintNFT(
        address _to,
        string memory name,
        string memory id,
        string memory tokenUrl,
        uint256 tokenID
    ) external {
        _mint(_to, tokenID);
        tokenMetadata[tokenID].name = name;
        tokenMetadata[tokenID].id = id;
        tokenMetadata[tokenID].tokenurl = tokenUrl;
    }
}
