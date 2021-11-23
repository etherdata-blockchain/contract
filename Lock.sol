// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Lock {
    //合约拥有者账号地址
    address private owner;
    mapping(address => Record) records;
    mapping(address => uint) balances;
    address[] users;

    bool _enabled = true;

    uint durationOne = 15 days;
    uint durationSec = 540 days;

    //抵押状态
    struct Record {
        //抵押额度(wei)
        uint value;
        //用户索引
        uint index;
        //抵押起时间(s)
        uint64 startTime;
        //是否已释放首期抵押
        uint64 stageOne;
        //已释放二期抵押份数
        uint64 stageSec;
        //已释放抵押
        uint withdrawed;
    }

    struct QueryResult {
        address addr;
        uint lockedAmount;
        uint withdrawed;
        uint64 startTime;
    }

    constructor() {
        owner = msg.sender;
    }

    event USDTLog(address indexed addr, uint amount, string txid);

    //直接抵押函数
    function lock540(address addr, uint amount, string calldata txid) public payable {
        require(msg.value > 0, "value cannot be zero");
        require(msg.value >= amount, "illegal amount");
        require(_enabled, "is disabled");
        require(address(msg.sender) == address(tx.origin), "no contract");
        require(records[addr].value == 0, "lock exist");

        records[addr] = Record({
        value : msg.value,
        index : users.length,
        startTime : uint64(block.timestamp),
        stageOne : 0,
        stageSec : 0,
        withdrawed : 0
        });

        users.push(addr);
        emit USDTLog(addr, msg.value, txid);
    }

    //查询自身锁仓
    function querySelf() view public returns (uint, QueryResult memory result) {
        require(records[msg.sender].value > 0, "no record");
        Record storage curRecord = records[msg.sender];

        result = QueryResult({
        addr : msg.sender,
        lockedAmount : curRecord.value,
        withdrawed : curRecord.withdrawed - balances[msg.sender],
        startTime : curRecord.startTime
        });
        return (block.timestamp, result);
    }

    //查询指定锁仓
    function queryAny(address addr) view public onlyOwner returns (uint, QueryResult memory result) {
        require(records[addr].value > 0, "no record");
        Record storage curRecord = records[addr];

        result = QueryResult({
        addr : addr,
        lockedAmount : curRecord.value,
        withdrawed : curRecord.withdrawed - balances[addr],
        startTime : curRecord.startTime
        });
        return (block.timestamp, result);
    }

    //查询全部锁仓
    function queryAll(uint start, uint size) view public onlyOwner returns (uint, QueryResult[] memory) {
        require(start + size <= users.length, "overflow");
        QueryResult[] memory result = new QueryResult[](size);

        uint end = start + size;
        for (uint i = start; i < end; i++) {
            Record storage curRecord = records[users[i]];
            result[i - start] = QueryResult({
            addr : users[i],
            lockedAmount : curRecord.value,
            withdrawed : curRecord.withdrawed - balances[users[i]],
            startTime : curRecord.startTime
            });
        }
        return (block.timestamp, result);
    }

    function getAllCount() onlyOwner public view returns (uint count) {
        return users.length;
    }

    function deleteUser(address addr) private {
        //删除用户
        uint index = records[addr].index;
        uint end = users.length - 1;
        if (index < end) {
            users[index] = users[end];
            records[users[end]].index = index;
        }
        users.pop();
        delete records[addr];
    }

    //结算锁仓，返回是否已结清
    function settle_(address addr) private returns (bool) {
        Record storage curRecord = records[addr];
        uint curTime = block.timestamp;

        uint64 day = uint64((curTime / (1 days)) - (curRecord.startTime / (1 days)));
        //抵押已到期
        if (day >= 555) {// 15+540
            //剩余抵押
            uint amount = curRecord.value - curRecord.withdrawed;
            //已结清
            if (amount == 0) {
                return true;
            }
            curRecord.stageOne = 1;
            curRecord.stageSec = 540;
            curRecord.withdrawed = curRecord.value;
            balances[addr] += amount;
            return true;
        }

        if (day < 15) {
            return false;
        }
        day -= 15;

        //释放第一阶段
        uint shareOne = curRecord.value * 5 / 100;
        if (curRecord.stageOne == 0) {
            curRecord.stageOne = 1;
            curRecord.withdrawed += shareOne;
            balances[addr] += shareOne;
        }

        //释放第二阶段
        uint shareSec = curRecord.value - shareOne;
        if (day > curRecord.stageSec) {
            uint amount = shareSec * (day - curRecord.stageSec) / 540;
            curRecord.withdrawed += amount;
            curRecord.stageSec = day;
            balances[addr] += amount;
        }
        return false;
    }

    //提取指定余额
    function withdrawAmount(uint amount) public {
        require(address(msg.sender) == address(tx.origin), "no contract");
        if (settle_(msg.sender) && amount == balances[msg.sender]) {
            deleteUser(msg.sender);
        }

        require(balances[msg.sender] >= amount, "not enough");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    //提取全部余额
    function withdrawAll() public {
        require(address(msg.sender) == address(tx.origin), "no contract");
        if (settle_(msg.sender)) {
            deleteUser(msg.sender);
        }

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function transferLock(address addr) public {
        require(records[addr].value == 0, "lock exist");
        require(addr != msg.sender && addr != address(0), "no self");

        users.push(addr);
        records[addr] = records[msg.sender];
        deleteUser(msg.sender);
    }

    //设置开始状态
    function changeStatus(bool flag) public onlyOwner {
        _enabled = flag;
    }

    function transferOwner(address paramOwner) public onlyOwner {
        require(paramOwner != address(0));
        owner = paramOwner;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "only owner");
        _;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function isEnabled() public view returns (bool) {
        return _enabled;
    }
}