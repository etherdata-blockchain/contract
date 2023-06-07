// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./mycontract_token.sol";

contract MarketContract {
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
    //事件：撤销订单
    event SellOrderCancelled(
        address indexed seller,
        address indexed contractID,
        uint256 tokenID
    );
    //事件：撮合失败
    event MatchFail(
        address indexed seller,
        address indexed buyer,
        address indexed contractID,
        uint256 tokenID,
        uint256 price
    );
    //匹配订单成功
    event MatchSuccess(
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
        bytes32 signature; // 签名
        bool isOnSale; // 是否在售
        uint256 timestamp; // 时间戳
    }

    // 代理钱包合约
    address private proxyWalletContract;
    // 收取手续费的地址
    address private mall;

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

    //查询手续费
    function getFee(SellOrder memory sellOrder) public pure returns (uint256) {
        return SafeMath.div(SafeMath.mul(sellOrder.price, 2), 100);
    }

    //设置收取手续费
    function PayFeeTO(address _mall) public {
        require(_mall != address(0), "invalid address");
        mall = _mall;
    }

    // 获取用户的代理钱包地址
    function getProxyWallet(address user) public view returns (address) {
        return userToProxyWallet[user];
    }

    //卖家主动下架
    function CancelSellOrder(SellOrder memory sellOrder) public {
        // 确保调用者是订单的卖家
        require(
            msg.sender == sellOrder.seller,
            "Only seller can cancel the order"
        );
        _cancelSellOrder(sellOrder);
    }

    //超时撤销
    function CancelSellOrderIfExpired(
        SellOrder memory sellOrder,
        uint256 expirationTime
    ) public {
        // 确保订单存在且正在售卖中
        require(sellOrder.isOnSale, "Order does not exist or is not on sale");

        // 检查订单是否已超过过期时间
        if (block.timestamp >= sellOrder.timestamp + expirationTime) {
            _cancelSellOrder(sellOrder);
        }
    }

    //撤销订单
    function _cancelSellOrder(SellOrder memory sellOrder) internal {
        // 确保订单存在
        require(sellOrder.isOnSale, "Order does not exist or is not on sale");

        //delagatecall调用代理钱包合约的cancelSellOrder方法
        (bool success, bytes memory data) = userToProxyWallet[sellOrder.seller]
            .delegatecall(
                abi.encodeWithSignature("cancelSellOrder(SellOrder)", sellOrder)
            );
        require(success, "Cancel sell order failed");
        //触发事件
        emit SellOrderCancelled(
            sellOrder.seller,
            sellOrder.contractID,
            sellOrder.tokenID
        );
        // 取消订单
        sellOrder.isOnSale = false;
    }

    function matchOrder(SellOrder memory sellOrder, uint256 _value) public {
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
        require(sellOrder.isOnSale == true, "This order is not on sale");

        //检查卖家是否是这个token的所有者
        require(
            IERC721(sellOrder.contractID).ownerOf(sellOrder.tokenID) ==
                sellOrder.seller,
            "Seller is not the owner of this token"
        );
        // 确保订单存在
        require(sellOrder.isOnSale, "Order does not exist or is not on sale");

        //delagatecall调用代理钱包合约的atomicTx方法
        (bool success, bytes memory data) = proxyWallet_Sell.delegatecall(
            abi.encodeWithSignature(
                "atomicTx(SellOrder,uint256)",
                sellOrder,
                _value
            )
        );
        bool Istransfer = abi.decode(data, (bool));
        if (success && Istransfer) {
            //匹配成功，触发事件
            emit MatchSuccess(
                sellOrder.seller,
                msg.sender,
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price
            );
            //进行交易
            _Trade(sellOrder, _value);
        } else {
            //匹配失败
            emit MatchFail(
                sellOrder.seller,
                msg.sender,
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price
            );
        }
    }

    //匹配成功执行交易
    function _Trade(SellOrder memory sellOrder, uint256 _value) internal {
        // 获取买家的代理钱包地址
        address proxyWallet_Buy = userToProxyWallet[msg.sender];
        address proxyWallet_Sell = userToProxyWallet[sellOrder.seller];
        //调用卖家的代理钱包合约的transferNFT，将NFT转移给买家
        (bool success_transfer, bytes memory data_Istransfer) = proxyWallet_Sell
            .delegatecall(
                abi.encodeWithSignature(
                    "transferNFT(SellOrder,address)",
                    sellOrder,
                    msg.sender
                )
            );
        bool Istransfer = abi.decode(data_Istransfer, (bool));
        if (Istransfer && success_transfer) {
            //成功转移nft给买家后，转移代币给卖家
            //买家发送交易附带的代币，将_value发送给合约地址
            (bool success_tra, bytes memory data) = proxyWallet_Buy
                .delegatecall(
                    abi.encodeWithSignature(
                        "paySeller(address,uint256)",
                        sellOrder.seller,
                        _value
                    )
                );
            require(success_tra, "Transfer failed");
            //收取手续费
            (bool success_fee, bytes memory data_fee) = proxyWallet_Buy
                .delegatecall(
                    abi.encodeWithSignature(
                        "payFee(address,uint256)",
                        mall,
                        getFee(sellOrder)
                    )
                );
            //触发交易成功事件
            emit TradeSuccess(
                sellOrder.seller,
                msg.sender,
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price
            );
        } else {
            //转移失败，退回钱和手续费给买家
            (bool success1, bytes memory data1) = proxyWallet_Buy.delegatecall(
                abi.encodeWithSignature("refund(uint256)", _value)
            );
            (bool success, bytes memory data) = proxyWallet_Buy.delegatecall(
                abi.encodeWithSignature("refund(uint256)", getFee(sellOrder))
            );
            //触发交易失败事件
            emit TradeFail(
                sellOrder.seller,
                msg.sender,
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price
            );
        }
    }

    //卖方买方调用进行授权
    function approveCollection(address collectionAddress) public {
        ProxyWallet proxyWallet = ProxyWallet(userToProxyWallet[msg.sender]);

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
        bytes32 hash = keccak256(abi.encodePacked(contractID, tokenID, price));
        bytes32 orderHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
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
    address private owner;

    //从订单的hash到订单是否被撤销或着被使用的bool映射·
    mapping(bytes32 => bool) public IsInvalid;

    struct SellOrder {
        address seller; // 卖家地址
        address contractID; // NFT 合约地址
        uint256 tokenID; // NFT 的 tokenId
        uint256 price; // 卖单的价格
        bytes32 signature; // 签名，使用 hash(token, price) 进行签名
    }

    constructor(address _owner) {
        owner = _owner;
    }

    function markOrderUsed(bytes32 orderHash) internal {
        // 将订单标记为无效
        IsInvalid[orderHash] = true;
    }

    function markOrderCancelled(bytes32 orderHash) internal {
        // 将订单标记为无效
        IsInvalid[orderHash] = true;
    }

    function AtomicTx(
        SellOrder memory sellOrder,
        uint256 _value
    ) public returns (bool) {
        //添加订单
        bytes32 Hash = keccak256(
            abi.encodePacked(
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price
            )
        );

        // 检查订单是否已被使用
        require(!IsInvalid[Hash], "Order has been used");

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

        if (_value >= sellOrder.price) {
            return true;

            bytes32 orderHash = keccak256(
                abi.encodePacked(
                    sellOrder.contractID,
                    sellOrder.tokenID,
                    sellOrder.price
                )
            );
            markOrderUsed(orderHash);
        } else {
            return false;
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
                sellOrder.signature
            ),
            "Invalid signature"
        );

        //添加订单
        bytes32 Hash = keccak256(
            abi.encodePacked(
                sellOrder.contractID,
                sellOrder.tokenID,
                sellOrder.price
            )
        );

        // 标记订单为已撤销
        markOrderCancelled(Hash);
    }

    //支付给卖家
    function paySeller(address seller, uint256 _value) public payable {
        require(_value > 0, "Insufficient funds");
        payable(seller).transfer(_value);
    }

    //收取手续费
    function payFee(address mall, uint256 _value) public payable {
        require(_value > 0, "Insufficient funds");
        //买家向mall支付手续费
        payable(mall).transfer(_value);
    }

    //返还代币给买家
    function refund(uint256 _value) public payable {
        require(_value > 0, "Insufficient funds");
        //仅有owner可以调用
        require(msg.sender == owner, "Only owner can call this function");
        payable(msg.sender).transfer(_value);
    }

    //nft的转移操作
    function transferNFT(
        SellOrder memory sellOrder,
        address _to
    ) public returns (bool) {
        //调用合约的transferFrom方法，将token转给_to
        try
            IERC721(sellOrder.contractID).transferFrom(
                sellOrder.seller,
                _to,
                sellOrder.tokenID
            )
        {
            return true;
        } catch {
            return false;
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
        bytes32 hash = keccak256(abi.encodePacked(contractID, tokenID, price));
        bytes32 orderHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
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
