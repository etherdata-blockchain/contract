// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

interface Imarket {
    //事件：交易成功
    event TradeSuccess(
        address indexed seller,
        address indexed buyer,
        address indexed contractID,
        bytes32 orderID,
        uint256 tokenID,
        uint256 price
    );
    //事件：交易失败
    event TradeFail(
        address indexed seller,
        address indexed buyer,
        address indexed contractID,
        bytes32 orderID,
        uint256 tokenID,
        uint256 price
    );
    //事件：撤销订单
    event SellOrderCancelled(
        address indexed seller,
        address indexed contractID,
        bytes32 orderID,
        uint256 tokenID
    );
    //事件：匹配失败
    event MatchFail(
        address indexed seller,
        address indexed buyer,
        address indexed contractID,
        uint256 tokenID,
        bytes32 orderID,
        uint256 price
    );
    //匹配订单成功
    event MatchSuccess(
        address indexed seller,
        address indexed buyer,
        address indexed contractID,
        uint256 tokenID,
        bytes32 orderID,
        uint256 price
    );
    //事件：更新费率
    event UpdateFeeRate(uint256 oldFeeRate, uint256 newFeeRate);
    //订单超时
    event OrderExpired(
        address indexed seller,
        address indexed contractID,
        bytes32 orderID,
        uint256 tokenID
    );
}
