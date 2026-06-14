# 锁仓合约历史版本

## 持续释放版合约

### v0.1

初版合约

#### ABI

```json
[
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "addr",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "txid",
        "type": "string"
      }
    ],
    "name": "USDTLog",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "bool",
        "name": "flag",
        "type": "bool"
      }
    ],
    "name": "changeStatus",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "addr",
        "type": "address"
      },
      {
        "internalType": "uint64",
        "name": "timeSlice",
        "type": "uint64"
      },
      {
        "internalType": "uint64",
        "name": "count",
        "type": "uint64"
      },
      {
        "internalType": "string",
        "name": "txid",
        "type": "string"
      }
    ],
    "name": "lockLinear",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "addr",
        "type": "address"
      }
    ],
    "name": "transferLock",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "paramOwner",
        "type": "address"
      }
    ],
    "name": "transferOwner",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "withdrawAll",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "withdrawAmount",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [],
    "name": "getAllCount",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "count",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getOwner",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "isEnabled",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "start",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "size",
        "type": "uint256"
      }
    ],
    "name": "queryAll",
    "outputs": [
      {
        "components": [
          {
            "internalType": "address",
            "name": "addr",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "lockedAmount",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "withdrawed",
            "type": "uint256"
          },
          {
            "internalType": "uint64",
            "name": "startTime",
            "type": "uint64"
          },
          {
            "internalType": "uint64",
            "name": "slice",
            "type": "uint64"
          },
          {
            "internalType": "uint64",
            "name": "count",
            "type": "uint64"
          }
        ],
        "internalType": "struct Lock.QueryResult[]",
        "name": "",
        "type": "tuple[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "addr",
        "type": "address"
      }
    ],
    "name": "queryAny",
    "outputs": [
      {
        "components": [
          {
            "internalType": "address",
            "name": "addr",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "lockedAmount",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "withdrawed",
            "type": "uint256"
          },
          {
            "internalType": "uint64",
            "name": "startTime",
            "type": "uint64"
          },
          {
            "internalType": "uint64",
            "name": "slice",
            "type": "uint64"
          },
          {
            "internalType": "uint64",
            "name": "count",
            "type": "uint64"
          }
        ],
        "internalType": "struct Lock.QueryResult",
        "name": "result",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "querySelf",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      },
      {
        "components": [
          {
            "internalType": "address",
            "name": "addr",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "lockedAmount",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "withdrawed",
            "type": "uint256"
          },
          {
            "internalType": "uint64",
            "name": "startTime",
            "type": "uint64"
          },
          {
            "internalType": "uint64",
            "name": "slice",
            "type": "uint64"
          },
          {
            "internalType": "uint64",
            "name": "count",
            "type": "uint64"
          }
        ],
        "internalType": "struct Lock.QueryResult",
        "name": "result",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]
```

#### 生产版本

Address: 0x3d90df95377811A4E0574Dfe9069fD319FE5eB2D

## 540版本合约

### v0.1

初版合约

#### ABI

```json
[
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "addr",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "txid",
        "type": "string"
      }
    ],
    "name": "USDTLog",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "bool",
        "name": "flag",
        "type": "bool"
      }
    ],
    "name": "changeStatus",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "addr",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "internalType": "string",
        "name": "txid",
        "type": "string"
      }
    ],
    "name": "lock540",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "addr",
        "type": "address"
      }
    ],
    "name": "transferLock",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "paramOwner",
        "type": "address"
      }
    ],
    "name": "transferOwner",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "withdrawAll",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "withdrawAmount",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "inputs": [],
    "name": "getAllCount",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "count",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getOwner",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "isEnabled",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "start",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "size",
        "type": "uint256"
      }
    ],
    "name": "queryAll",
    "outputs": [
      {
        "components": [
          {
            "internalType": "address",
            "name": "addr",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "lockedAmount",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "withdrawed",
            "type": "uint256"
          },
          {
            "internalType": "uint64",
            "name": "startTime",
            "type": "uint64"
          }
        ],
        "internalType": "struct Lock.QueryResult[]",
        "name": "",
        "type": "tuple[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "addr",
        "type": "address"
      }
    ],
    "name": "queryAny",
    "outputs": [
      {
        "components": [
          {
            "internalType": "address",
            "name": "addr",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "lockedAmount",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "withdrawed",
            "type": "uint256"
          },
          {
            "internalType": "uint64",
            "name": "startTime",
            "type": "uint64"
          }
        ],
        "internalType": "struct Lock.QueryResult",
        "name": "result",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "querySelf",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      },
      {
        "components": [
          {
            "internalType": "address",
            "name": "addr",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "lockedAmount",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "withdrawed",
            "type": "uint256"
          },
          {
            "internalType": "uint64",
            "name": "startTime",
            "type": "uint64"
          }
        ],
        "internalType": "struct Lock.QueryResult",
        "name": "result",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]
```

#### 生产版本

Address: 0xDA158ecc1A88900e00154Eb83E306eCc48c777D8

### v0.2

#### 更新内容

queryAny及queryAll返回值添加当前时间戳

#### ABI

```json
[
  {
    "inputs": [],
    "stateMutability": "nonpayable",
    "type": "constructor"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "addr",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "string",
        "name": "txid",
        "type": "string"
      }
    ],
    "name": "USDTLog",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "bool",
        "name": "flag",
        "type": "bool"
      }
    ],
    "name": "changeStatus",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getAllCount",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "count",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "getOwner",
    "outputs": [
      {
        "internalType": "address",
        "name": "",
        "type": "address"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "isEnabled",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "addr",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "internalType": "string",
        "name": "txid",
        "type": "string"
      }
    ],
    "name": "lock540",
    "outputs": [],
    "stateMutability": "payable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "start",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "size",
        "type": "uint256"
      }
    ],
    "name": "queryAll",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      },
      {
        "components": [
          {
            "internalType": "address",
            "name": "addr",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "lockedAmount",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "withdrawed",
            "type": "uint256"
          },
          {
            "internalType": "uint64",
            "name": "startTime",
            "type": "uint64"
          }
        ],
        "internalType": "struct Lock.QueryResult[]",
        "name": "",
        "type": "tuple[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "addr",
        "type": "address"
      }
    ],
    "name": "queryAny",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      },
      {
        "components": [
          {
            "internalType": "address",
            "name": "addr",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "lockedAmount",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "withdrawed",
            "type": "uint256"
          },
          {
            "internalType": "uint64",
            "name": "startTime",
            "type": "uint64"
          }
        ],
        "internalType": "struct Lock.QueryResult",
        "name": "result",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "querySelf",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      },
      {
        "components": [
          {
            "internalType": "address",
            "name": "addr",
            "type": "address"
          },
          {
            "internalType": "uint256",
            "name": "lockedAmount",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "withdrawed",
            "type": "uint256"
          },
          {
            "internalType": "uint64",
            "name": "startTime",
            "type": "uint64"
          }
        ],
        "internalType": "struct Lock.QueryResult",
        "name": "result",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "addr",
        "type": "address"
      }
    ],
    "name": "transferLock",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "paramOwner",
        "type": "address"
      }
    ],
    "name": "transferOwner",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "withdrawAll",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "withdrawAmount",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
```

#### 生产版本

Address: 0x3b97CD91e9081EB172E963de48f256B38DE2541B

#### 分钟级测试版本

Address: 0x566D0d33B47e0bB20109b1C1dAbD51937FF17AD7

### v0.3

#### 更新内容

更正withdrawed字段约定：

该笔锁仓已结算ETH数额 -> 该账户已提取ETH数额

#### ABI

同v0.2

#### 生产版本

Address: 0x2A7f9509eebF1a50f1103A8e51ED6009c56641d9

#### 分钟级测试版本

Address: 0xCbA7E6074e250c3CbB782811B294BcAc40310E5A

### v0.4

#### 更新内容

对锁仓event添加address索引，transferLock校验目标地址是否有效

#### ABI

同v0.2

#### 生产版本

Address: 0x4b5116c166e7E1682335fE50ACB9e7C01e34b14c

#### 分钟级测试版本

Address: 0x2c8AAbD89dCc7aD8a8426011367680cAE267175B

