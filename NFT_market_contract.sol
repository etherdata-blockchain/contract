// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./mycontract_token.sol";

contract MarketContract {
    // 事件：匹配订单
    event MatchOrder(
        address indexed seller,
        address indexed buyer,
        address indexed contractID,
        uint256 tokenID,
        uint256 price
    );

    struct SellOrder {
        address seller; // 卖家地址
        address contractID; // NFT 合约地址
        uint256 tokenID; // NFT 的 tokenId
        uint256 price; // 卖单的价格
        bytes32 signature; // 签名，使用 hash(token, price) 进行签名
    }
    struct BuyOrder {
        address buyer; // 买家地址
        address contractID; // NFT 合约地址
        uint256 tokenID; // NFT 的 tokenId
        uint256 price; // 买单的价格
        bytes32 signature; // 签名，使用 hash(token, price) 进行签名
    }

    // 代理钱包合约
    address private proxyWalletContract;

    // 用户地址到代理钱包地址的映射关系
    mapping(address => address) private userToProxyWallet;

    // 创建代理钱包
    function createProxyWallet() public {
        // 检查用户是否已有代理钱包
        require(
            userToProxyWallet[msg.sender] == address(0),
            "Proxy wallet already exists"
        );

        // 部署代理钱包合约
        proxyWalletContract = address(new ProxyWallet(msg.sender));

        // 将用户地址和代理钱包地址建立映射关系
        userToProxyWallet[msg.sender] = proxyWalletContract;
    }

    // 获取用户的代理钱包地址
    function getProxyWallet(address user) public view returns (address) {
        return userToProxyWallet[user];
    }

    function matchOrder(
        SellOrder memory sellOrder,
        BuyOrder memory buyOrder
    ) public {
        // 校验 sellOrder 的签名
        require(
            verifySignature(
                sellOrder.seller,
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price,
                sellOrder.signature
            ),
            "Invalid signature"
        );
        // 校验 buyOrder 的签名
        require(
            verifySignature(
                buyOrder.buyer,
                buyOrder.contractID,
                buyOrder.tokenID,
                buyOrder.price,
                buyOrder.signature
            ),
            "Invalid signature"
        );

        //匹配订单的地址是否一致
        require(
            sellOrder.contractID == buyOrder.contractID,
            "ContractID not match"
        );
        require(sellOrder.tokenID == buyOrder.tokenID, "TokenID not match");


        // 获取买家的代理钱包地址
        address proxyWalletAddress = userToProxyWallet[buyOrder.buyer];

        require(
            userToProxyWallet[buyOrder.buyer] != address(0),
            "Proxy wallet not found"
        );
        require(
            userToProxyWallet[sellOrder.seller] != address(0),
            "Proxy wallet not found"
        );

        //检查卖家是否是这个token的所有者
        require(
            IERC721(sellOrder.contractID).ownerOf(sellOrder.tokenID) ==
                sellOrder.seller,
            "Seller is not the owner of this token"
        );

        //买家发送交易附带的代币，将_value发送给合约地址
        // 通过买家身份调用对应的 ProxyWallet 的 AtomicTx 函数
        (bool success, bytes memory data) = proxyWalletAddress.delegatecall(
            abi.encodeWithSignature(
                "AtomicTx(SellOrder, BuyOrder)",
                sellOrder,
                buyOrder
            )
        );
        require(success, "AtomicTx execution failed");

        //匹配成功，触发事件
        emit MatchOrder(
            sellOrder.seller,
            buyOrder.buyer,
            sellOrder.contractID,
            sellOrder.tokenID,
            sellOrder.price
        );
    }

    //卖方买方调用进行授权
    function approveCollection(address collectionAddress) public{
        address seller = msg.sender;
        ProxyWallet proxyWallet = ProxyWallet(userToProxyWallet[seller]);

        //contractid为collectionAddress的合约，调用approveAll给该用户对应的ProxyWallet
        //调用delegateCall，调用指定collection合约的approveAll给该用户对应的ProxyWallet
        //同时触发approveAll事件
        (bool success, bytes memory data) = collectionAddress.delegatecall(
            abi.encodeWithSignature(
                "setApprovelForAll(address,bool)",
                address(proxyWallet),
                true
            )
        );
    }

    // 校验签名
    function verifySignature(
        address seller,
        address contractID,
        uint256 tokenID,
        uint256 price,
        bytes32 signature
    ) internal pure returns (bool) {
        bytes32 orderHash = keccak256(
            abi.encodePacked(contractID, tokenID, price)
        );
        address recoveredSigner = recoverSigner(orderHash, signature);
        return recoveredSigner == seller;
    }

    function recoverSigner(
        bytes32 hash,
        bytes32 signature
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(hash, v, r, s);
    }
}

contract ProxyWallet {
    //事件：交易成功
    event TradeSuccess(
        address indexed seller,
        address indexed buyer,
        address indexed contractID,
        uint256 tokenID,
        uint256 price
    );
    //事件：交易失败
    event TradeFail(
        address indexed seller,
        address indexed buyer,
        address indexed contractID,
        uint256 tokenID,
        uint256 price
    );

    address private owner;

    struct SellOrder {
        address seller; // 卖家地址
        address contractID; // NFT 合约地址
        uint256 tokenID; // NFT 的 tokenId
        uint256 price; // 卖单的价格
        bytes32 signature; // 签名，使用 hash(token, price) 进行签名
    }
    struct BuyOrder {
        address buyer; // 买家地址
        address contractID; // NFT 合约地址
        uint256 tokenID; // NFT 的 tokenId
        uint256 price; // 买单的价格
        bytes32 signature; // 签名，使用 hash(token, price) 进行签名
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function AtomicTx(
        SellOrder memory sellOrder,
        BuyOrder memory buyOrder
    ) public payable {
        // 校验签名
        require(
            verifySignature(
                sellOrder.seller,
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price,
                sellOrder.signature
            ),
            "Invalid signature"
        );
        require(
            verifySignature(
                buyOrder.buyer,
                buyOrder.contractID,
                buyOrder.tokenID,
                buyOrder.price,
                buyOrder.signature
            ),
            "Invalid signature"
        );

        // 判断 _value ≥ sellOrder.price
        uint256 _value=buyOrder.price;
        require(_value >= sellOrder.price, "Insufficient funds");

        // 调用 sellOrder 指定的 NFT 合约的 TransferFrom 方法将指定 token 转给买家（msg.sender）
        try 
        IERC721(sellOrder.contractID).transferFrom(
        sellOrder.seller,
        buyOrder.buyer,
        sellOrder.tokenID
        )

        {
        // 转移成功，将 _value 转给卖家
        payable(sellOrder.seller).transfer(_value);

        } catch {

        // 转移失败，退还 _value
        payable(owner).transfer(_value);
        revert("Failed to transfer NFT");

        }

    // 根据转移操作的结果触发相应的事件
    if (IERC721(sellOrder.contractID).ownerOf(sellOrder.tokenID) == buyOrder.buyer) {
        emit TradeSuccess(
            sellOrder.seller,
            buyOrder.buyer,
            sellOrder.contractID,
            sellOrder.tokenID,
            sellOrder.price
        );
    } else {
        emit TradeFail(
            sellOrder.seller,
            buyOrder.buyer,
            sellOrder.contractID,
            sellOrder.tokenID,
            sellOrder.price
        );
    }

    }

    // 校验签名
    function verifySignature(
        address seller,
        address contractID,
        uint256 tokenID,
        uint256 price,
        bytes32 signature
    ) internal pure returns (bool) {
        bytes32 orderHash = keccak256(
            abi.encodePacked(contractID, tokenID, price)
        );
        address recoveredSigner = recoverSigner(orderHash, signature);
        return recoveredSigner == seller;
    }

    function recoverSigner(
        bytes32 hash,
        bytes32 signature
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(hash, v, r, s);
    }
}
