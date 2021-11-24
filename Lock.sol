// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lock {
    address private owner;
    mapping (address => Record) records;
    mapping (address => uint) balances;
    address[] users;
    
    bool _enabled = true;
    
    uint durationOne = 15 days;
    uint durationSec = 540 days;
    
    //抵押状态
    struct Record {
        //抵押额度 wei
        uint value;
        //抵押起始时间
        uint64 startTime;
        //总提取次数
        uint index;
        //是否已经释放首期
        uint64 stageOne;
        //二期抵押
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
    
    function lock_540_once(address addr, uint amount, string calldata txidUSDT) public payable {
        require(msg.value > 0,"value cannot be zero");
        require(address(msg.sender) == address(tx.origin),"no cantract");
        require(_enabled,"is disable");
        require(records[addr].value == 0,"lock exist");
        require(msg.value > amount);
        
        records[addr] = Record({
            value : msg.value,
            index : users.length,
            startTime : uint64(block.timestamp),
            stageOne : 0,
            stageSec : 0,
            withdrawed : 0
        });
        users.push(addr);
        emit USDTLog(addr, msg.value, txidUSDT);
    }
    
    function querySelf() view public returns(uint, QueryResult memory result) {
        require(records[msg.sender].value > 0,"no records");
        Record storage curRecord = records[msg.sender];
        
        result = QueryResult({
            addr : msg.sender,
            lockedAmount : curRecord.value,
            withdrawed : curRecord.withdrawed - balances[msg.sender],
            startTime : curRecord.startTime
        });
        return(block.timestamp, result);
    }  
 
    function queryAll(uint start, uint size) view public onlyOwner returns(uint, QueryResult[] memory) {
        require(start + size <= users.length,"overflow");
        QueryResult[] memory result = new QueryResult[](size);
        uint end =start + size;
        for (uint i = start; i < end; i++){
            Record storage curRecord = records[users[i]];
            result[i-start] = QueryResult({
                addr : users[i],
                lockedAmount : curRecord.value,
                withdrawed : curRecord.withdrawed - balances[users[i]],
                startTime : curRecord.startTime
            });
        }
        return (block.timestamp,result);
    }
    
    function QueryAny(address addr) view public onlyOwner returns(uint, QueryResult memory result){
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
    
    function deleteUser(address addr) private {
        uint index = records[addr].index;
        uint end = users.length - 1;
        if (index < end) {
            users[index] = users[end];
            records[users[end]].index = index; 
        }
        users.pop();
        delete records[addr];
    }
    
    function settle_(address addr) private returns(bool) {
        Record storage curRecord = records[addr];
        uint curTime = block.timestamp;
        
        uint64 day = uint64(((curTime) / (1 days)) - ((curRecord.startTime) / (1 days)));
        if (day >= 555){
            uint amount = curRecord.value - curRecord.withdrawed;
            if (amount == 0){
                return true;
            }
            curRecord.stageOne = 1;
            curRecord.stageSec = 1;
            curRecord.withdrawed = curRecord.value;
            balances[addr] += amount;
            return true;
        }
        
        if (day < 15){
            return false;
        }
        
        day -= 15;
    
        uint shareOne = curRecord.value *5 / 100;
         if (curRecord.stageOne == 0){
             curRecord.stageOne = 1;
             curRecord.withdrawed += shareOne;
             balances[addr] += shareOne;
        }
        
        return false;
    
    }
    
    function withdraAll() public {
        require(address(msg.sender) == address(tx.origin),"no cantract");
        if (settle_(msg.sender)){
            deleteUser(msg.sender);
        }
        
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
    
    
    function getAllCount() view public onlyOwner returns(uint) {
        return users.length;
    }
    
    function transferLock(address addr) public {
        require(records[addr].value ==0, "lock exist");
        require(addr != msg.sender && addr != address(0), "not self");
        
        users.push(addr);
        records[addr] = records[msg.sender];
        deleteUser(msg.sender);
    }
    
    function transferOnwer(address paramOwner) public onlyOwner {
        if (paramOwner != address(0)){
            owner = paramOwner;
        }
    }
    
    function changeStatus(bool flag) public onlyOwner {
       _enabled = flag;    
    }
    
    modifier onlyOwner() {
        require (msg.sender == owner,"only owner");
        _;
    }
    
    function getOwner() public view returns (address) {
        return owner;
    }
    
    function isEnable() public view returns (bool) {
        return _enabled;
    }
}
