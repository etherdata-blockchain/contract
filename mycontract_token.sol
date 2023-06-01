// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MyNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    mapping(uint256 => string) private _tokenURIs;

    function creatNFT(
        address _to,
        string memory tokenURI
    ) public returns (uint256) {
        //依次加一的方式生成新的tokenid
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(_to, newItemId);
        _setTokenURI(newItemId, tokenURI);
        return newItemId;
    }

    // //获取NFT总数
    // function totalSupply() public view returns (uint256) {
    //     return _tokenIds.current();
    // }

    //设置token的URI
    function _setTokenURI(
        uint256 tokenId,
        string memory tokenURI
    ) internal virtual {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = tokenURI;
    }

    //使用tokenid查询token的URI
    function getTokenURI(
        uint256 tokenId
    ) public view virtual  returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        return _tokenURIs[tokenId];
    }
}
