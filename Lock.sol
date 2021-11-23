pragma solidity >=0.7.0 <0.9.0;

contract Lock {
    //合约拥有者账号地址
    address private owner;
    mapping(address => Record) records;
    mapping(address => uint) balances;
    address[] users;

    bool _enabled = true;

    //抵押状态
    struct Record {
        //抵押额度(wei)
        uint value;
        //单次提取时间(s)
        uint64 slice;
        //抵押起始时间(s)
        uint64 startTime;
        //总提取次数
        uint64 count;
        //已提取次数
        uint64 freeCount;
        //用户索引
        uint index;
    }

    struct QueryResult {
        address addr;
        uint lockedAmount;
        uint withdrawed;
        uint64 startTime;
        uint64 slice;
        uint64 count;
    }

    constructor() {
        owner = msg.sender;
    }

    event USDTLog(address addr, uint amount, string txid);

    //直接抵押函数
    function lockLinear(address addr, uint64 timeSlice, uint64 count, string calldata txid) public payable {
        require(msg.value > 0, "value cannot be zero");
        require(address(msg.sender) == address(tx.origin), "no contract");
        require(_enabled, "is disabled");
        require(count > 0 && count <= 36, "illegal count");
        require(timeSlice > 0 && timeSlice < 36500, "illegal time");
        require(records[addr].value == 0, "lock exist");

        records[addr] = Record({
        value : msg.value,
        slice : timeSlice * (1 days),
        startTime : uint64(block.timestamp),
        count : count,
        freeCount : 0,
        index : users.length
        });

        users.push(addr);
        emit USDTLog(addr, msg.value, txid);
    }

    //查询自身锁仓
    function querySelf() view public returns (uint, QueryResult memory result) {
        require(records[msg.sender].value > 0, "no record");
        Record storage curRecord = records[msg.sender];
        uint share = curRecord.value / curRecord.count;

        result = QueryResult({
        addr : msg.sender,
        lockedAmount : curRecord.value,
        withdrawed : share * curRecord.freeCount,
        startTime : curRecord.startTime,
        slice : curRecord.slice,
        count : curRecord.count
        });
        return (block.timestamp, result);
    }

    //查询指定锁仓
    function queryAny(address addr) view public onlyOwner returns (QueryResult memory result) {
        require(records[addr].value > 0, "no record");
        Record storage curRecord = records[addr];
        uint share = curRecord.value / curRecord.count;

        result = QueryResult({
        addr : addr,
        lockedAmount : curRecord.value,
        withdrawed : share * curRecord.freeCount,
        startTime : curRecord.startTime,
        slice : curRecord.slice,
        count : curRecord.count
        });
        return result;
    }

    //查询全部锁仓
    function queryAll(uint start, uint size) view public onlyOwner returns (QueryResult[] memory) {
        require(start + size <= users.length, "overflow");
        QueryResult[] memory result = new QueryResult[](size);

        uint end = start + size;
        for (uint i = start; i < end; i++) {
            Record storage curRecord = records[users[i]];
            uint share = curRecord.value / curRecord.count;
            result[i - start] = QueryResult({
            addr : users[i],
            lockedAmount : curRecord.value,
            withdrawed : share * curRecord.freeCount,
            startTime : curRecord.startTime,
            slice : curRecord.slice,
            count : curRecord.count
            });
        }
        return result;
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

    function settle_(address addr) private {
        Record storage curRecord = records[addr];
        uint share = curRecord.value / curRecord.count;
        uint curTime = block.timestamp;

        //抵押已到期
        if (curTime >= curRecord.startTime + curRecord.slice * curRecord.count) {
            //剩余抵押
            uint amount = curRecord.value - share * curRecord.freeCount;
            curRecord.freeCount = curRecord.count;
            balances[addr] += amount;
            deleteUser(addr);
            return;
        }

        uint times = (curTime - uint(curRecord.startTime)) / curRecord.slice;
        //按时间释放
        if (times > curRecord.freeCount) {
            uint amount = (times - curRecord.freeCount) * share;
            curRecord.freeCount = uint64(times);
            balances[addr] += amount;
        }
    }

    //提取指定余额
    function withdrawAmount(uint amount) public {
        require(address(msg.sender) == address(tx.origin), "no contract");
        if (records[msg.sender].value > 0) {
            settle_(msg.sender);
        }

        require(balances[msg.sender] >= amount, "not enough");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    //提取全部余额
    function withdrawAll() public {
        require(address(msg.sender) == address(tx.origin), "no contract");
        if (records[msg.sender].value > 0) {
            settle_(msg.sender);
        }

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function transferLock(address addr) public {
        require(records[addr].value == 0, "lock exist");
        require(addr != msg.sender, "no self");

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