// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MyNFT is ERC721 {
    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {}

    struct TokenMetadata {
        string name;
        string tokenurl; // tokenurl 属性
        string id;
    }

    mapping(uint256 => TokenMetadata) public tokenMetadata;
    uint256 total = 0;

    function mintNFT(
        uint256 num,
        string memory _name,
        string memory _id,
        string memory _tokenUrl,
        address _to
    ) public {
        for (uint256 i = total + 1; i <= total + num; i++) {
            _mint(_to, i);
            tokenMetadata[i].name = _name;
            tokenMetadata[i].id = _id;
            tokenMetadata[i].tokenurl = _tokenUrl;
        }
        total = total + num;
    }
}
