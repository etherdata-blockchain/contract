// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WETH9 {
    string internal name;     
    string internal symbol;
    uint8  internal decimals;
    uint256 internal totalsupply;

    event  Approval(address indexed src, address indexed guy, uint wad);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    event  Deposit(address indexed dst, uint wad);
    event  Withdrawal(address indexed src, uint wad);

    mapping (address => uint) internal balanceOf;
    mapping (address => mapping (address => uint)) internal allowance;
    
    constructor (){
       name =  "Wrapped Etd";
       symbol = "WETH";
       decimals  = 18;
       totalsupply = 100000000000 * (10 ** decimals);
       balanceOf[msg.sender] = totalsupply;
    }

    function withdraw(uint wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return totalsupply;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        require(balanceOf[src] >= wad);

        if (src != msg.sender) {
            require(allowance[src][msg.sender] != 0,"Not permit");
            require(allowance[src][msg.sender] >= wad,"allowance is too low");
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }

    function _balanceOf(address who) external view returns (uint256){
        return balanceOf[who];
    }
}