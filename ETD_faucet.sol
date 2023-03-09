pragma solidity ^0.5.1;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Fauct{
    uint constant public tokenAmount = 1000000000000000000;
    //单笔限制 1 ETD
    uint constant public waitTime = 30 minutes;
    //代币领取冷却30min

    IERC20 public tokenInstance;
    mapping (address => uint) LastAcessTime;

    constructor(address _tokenInstance) public {
        require(address(_tokenInstance) != address(0));
        tokenInstance = IERC20(_tokenInstance);
    }

    function requestAmount() public {
        require(AllowToWithdraw(msg.sender),"request Token within 30 minutes");
        tokenInstance.transfer(msg.sender,tokenAmount);
        LastAcessTime[msg.sender] = block.timestamp + waitTime;
    }

    function AllowToWithdraw(address _address) view public returns (bool) {
        if (LastAcessTime[_address] == 0){
            return true;
        }
        else if (LastAcessTime[_address] <= block.timestamp){
            return true;
        }
        return false;
    }
}


