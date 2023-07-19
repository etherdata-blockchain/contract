// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Imarket.sol";

contract MarketContract is Imarket {
    using SafeMath for uint256;
    struct SellOrder {
        address seller; // 卖家地址
        address contractID; // NFT 合约地址
        uint256 tokenID; // NFT 的 tokenId
        uint256 price; // 卖单的价格
        bytes signature; // 签名
        uint256 expirationTime; // 时间戳
        bytes32 orderID; //订单ID
    }

    // 代理钱包合约
    address private proxyWalletContract;
    // 收取手续费的地址
    address private mall;
    //市场的费率
    uint256 private feeRate = 2;
    // 合约拥有者
    address private owner;

    // 用户地址到代理钱包地址的映射关系
    mapping(address => address) private userToProxyWallet;

    constructor(address _owner) payable {
        owner = _owner;
    }

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

    //修改费率（仅owner）
    function updateFeeRate(uint256 newFeeRate) public {
        require(msg.sender == owner, "only owner can call this");
        uint256 oldFeeRate = feeRate;
        feeRate = newFeeRate;
        emit UpdateFeeRate(oldFeeRate, newFeeRate);
    }

    //查询费率
    function getFeeRate() public view returns (uint256) {
        return feeRate;
    }

    //设置收取手续费的地址（仅owner）
    function setMall(address payable _mall) public {
        require(msg.sender == owner, "only owner can call this");
        mall = _mall;
    }

    // 获取用户的代理钱包地址
    function getProxyWallet(address user) public view returns (address) {
        return userToProxyWallet[user];
    }

    //卖家主动下架
    modifier onlySeller(address seller) {
        require(msg.sender == seller, "Only seller can call this function");
        _;
    }

    function CancelSellOrder(
        SellOrder memory sellOrder
    ) public onlySeller(sellOrder.seller) {
        _cancelSellOrder(sellOrder);
    }

    //撤销订单
    function _cancelSellOrder(SellOrder memory sellOrder) internal {
        //delagatecall调用代理钱包合约的cancelSellOrder方法
        (bool success1, bytes memory data) = userToProxyWallet[sellOrder.seller]
            .call(
                abi.encodeWithSignature(
                    "cancelOrder((address,address,uint256,uint256,bytes,uint256,bytes32))",
                    sellOrder
                )
            );
        require(success1, "Cancel sell order failed");
        //触发事件
        emit SellOrderCancelled(
            sellOrder.seller,
            sellOrder.contractID,
            sellOrder.orderID,
            sellOrder.tokenID
        );
    }

    function matchOrder(
        address seller, // 卖家地址
        address contractID, // NFT 合约地址
        uint256 tokenID, // NFT 的 tokenId
        uint256 price, // 卖单的价格
        bytes memory signature, // 签名
        uint256 expirationTime, // 时间戳
        bytes32 orderID //订单ID
    ) public payable {
        //发送代币给合约
        SellOrder memory sellOrder = SellOrder(
            seller,
            contractID,
            tokenID,
            price,
            signature,
            expirationTime,
            orderID
        );
        uint256 _value = msg.value;
        uint256 fee = sellOrder.price.mul(feeRate).div(100);

        // 校验 sellOrder 的签名
        require(
            verifySignature(
                sellOrder.seller,
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price,
                sellOrder.signature,
                sellOrder.expirationTime
            ),
            "Invalid signature"
        );
        // 获取买家的代理钱包地址
        address proxyWallet_Buy = userToProxyWallet[msg.sender];
        address proxyWallet_Sell = userToProxyWallet[sellOrder.seller];

        require(
            userToProxyWallet[msg.sender] != address(0),
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

        //检查订单是否超时
        if (block.timestamp > sellOrder.expirationTime) {
            _cancelSellOrder(sellOrder);
            emit OrderExpired(
                sellOrder.seller,
                sellOrder.contractID,
                sellOrder.orderID,
                sellOrder.tokenID
            );
            return;
        }
        //调用代理钱包的isOrderValid方法，检查订单是否有效
        bytes32 Hash = keccak256(
            abi.encodePacked(
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price,
                sellOrder.expirationTime,
                sellOrder.signature
            )
        );
        (bool isValid, bytes memory datas) = proxyWallet_Sell.call(
            abi.encodeWithSignature("isOrderInvalid(bytes32)", Hash)
        );
        //data是返回的bool值
        bool isOrderValid = abi.decode(datas, (bool));
        require(isValid && !isOrderValid, "Order is not valid");

        //delagatecall调用代理钱包合约的atomicTx方
        (bool success, bytes memory data) = proxyWallet_Sell.call(
            abi.encodeWithSignature(
                "AtomicTx((address,address,uint256,uint256,bytes,uint256,bytes32),uint256,address)",
                sellOrder,
                _value - fee,
                msg.sender
            )
        );

        //检查NFT被成功转移
        if (
            IERC721(sellOrder.contractID).ownerOf(sellOrder.tokenID) ==
            msg.sender
        ) {
            //匹配成功
            matchsuccess(sellOrder);
            payable(mall).transfer(fee);
            //转移剩余的钱,如果不成功，退还给买家
            if (!payable(sellOrder.seller).send(_value - fee)) {
                payable(msg.sender).transfer(_value - fee);
                payable(msg.sender).transfer(fee);
            }
        } else {
            matchfail(sellOrder);
            revert("matchfail");
        }
    }

    function matchsuccess(SellOrder memory sellOrder) internal {
        //匹配成功，触发事件
        emit MatchSuccess(
            sellOrder.seller,
            msg.sender,
            sellOrder.contractID,
            sellOrder.tokenID,
            sellOrder.orderID,
            sellOrder.price
        );
    }

    function matchfail(SellOrder memory sellOrder) internal {
        emit MatchFail(
            sellOrder.seller,
            msg.sender,
            sellOrder.contractID,
            sellOrder.tokenID,
            sellOrder.orderID,
            sellOrder.price
        );
    }

    //卖方买方调用进行授权
    function approveCollection(address collectionAddress) public {
        require(userToProxyWallet[msg.sender] != address(0), "no proxy wallet");
        (bool success, bytes memory data) = collectionAddress.delegatecall(
            abi.encodeWithSignature(
                "setApprovalForAll(address,bool)",
                userToProxyWallet[msg.sender],
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
        bytes memory signature,
        uint256 expirationTime
    ) internal pure returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(contractID, tokenID, price, expirationTime)
        );
        bytes32 OrderHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        return recoverSigner(OrderHash, signature) == seller;
    }

    function recoverSigner(
        bytes32 hash,
        bytes memory signature
    ) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(hash, v, r, s);
    }
}

contract ProxyWallet {
    address private owner;

    //从订单的hash到订单是否被撤销或着被使用的bool映射·
    mapping(bytes32 => bool) public IsInvalid;

    struct SellOrder {
        address seller; // 卖家地址
        address contractID; // NFT 合约地址
        uint256 tokenID; // NFT 的 tokenId
        uint256 price; // 卖单的价格
        bytes signature; // 签名
        uint256 expirationTime; // 时间戳
        bytes32 orderID; //订单ID
    }

    constructor(address _owner) payable {
        owner = _owner;
    }

    function markOrderCancelled(bytes32 orderHash) internal {
        // 将订单标记为无效
        IsInvalid[orderHash] = true;
    }

    //用于查询订单是否被撤销或者被使用
    function isOrderInvalid(bytes32 orderHash) public view returns (bool) {
        return IsInvalid[orderHash];
    }

    function AtomicTx(
        SellOrder memory sellOrder,
        uint256 _value,
        address buyer
    ) public payable {
        //SellOrder memory sellOrder = abi.decode(sellOrderData, (SellOrder));

        bytes32 Hash = keccak256(
            abi.encodePacked(
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price,
                sellOrder.expirationTime,
                sellOrder.signature
            )
        );
        //检验订单是否已经超时
        if (sellOrder.expirationTime < block.timestamp) {
            markOrderCancelled(Hash);
            return;
        }

        // 检查订单是否已被使用
        require(!IsInvalid[Hash], "Order has been used");

        // 校验签名
        require(
            verifySignature(
                sellOrder.seller,
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price,
                sellOrder.signature,
                sellOrder.expirationTime
            ),
            "Invalid signature"
        );

        if (_value >= sellOrder.price) {
            //调用合约的transferFrom方法，将token转给_to
            try
                IERC721(sellOrder.contractID).transferFrom(
                    sellOrder.seller,
                    buyer,
                    sellOrder.tokenID
                )
            {
                markOrderCancelled(Hash);
                return;
            } catch {
                return;
            }
        } else {
            return;
        }
    }

    //撤销订单
    function cancelOrder(SellOrder memory sellOrder) public {
        // 校验签名
        require(
            verifySignature(
                sellOrder.seller,
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price,
                sellOrder.signature,
                sellOrder.expirationTime
            ),
            "Invalid signature"
        );

        //添加订单
        bytes32 Hash = keccak256(
            abi.encodePacked(
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price,
                sellOrder.expirationTime,
                sellOrder.signature
            )
        );

        // 标记订单为已撤销
        markOrderCancelled(Hash);
    }

    //校验签名
    function verifySignature(
        address seller,
        address contractID,
        uint256 tokenID,
        uint256 price,
        bytes memory signature,
        uint256 expirationTime
    ) internal pure returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(contractID, tokenID, price, expirationTime)
        );
        bytes32 OrderHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        return recoverSigner(OrderHash, signature) == seller;
    }

    function recoverSigner(
        bytes32 hash,
        bytes memory signature
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
