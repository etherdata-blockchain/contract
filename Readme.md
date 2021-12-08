## ETD Lock Contract

address: 0x7b7c74c2d0f4b7222ede26cae13a4e85a3b69e90

1. Lock_540_once（addr, amount, usdtTxid）

   1.addr 为锁仓收款地址
   2.amount为锁定数量
   3.txidUSDT可以为空
   4.每⼀个addr持有的锁仓条⽬上限为1
   5. 释放规则(分为两个线性阶段)：
      1. 从锁仓开始记为第⼀天，第540天⼀次性释放

2. withdrawAll()

     提取msg.sender的当前可以提取的所有ETD（⼀次性释放，即为>=540天后，可提取全部，<540时可提取为0）


3. querySelf()// {now, addr, lockedAmount, withdrawed, startTime}

     查询msg.sender的锁仓列表

4. queryAll _owner(start, size)// {now, []{addr, lockedAmount, withdrawed, startTime}}

     查询所有的锁仓详情，owner权限

6. queryAny _owner(addr) // {now, addr, lockedAmount, withdrawed, startTime}

     查询addr的锁仓详情，owner权限

7. getAllCount _owner()

     当前锁仓总条数

8. transferLock(addr)

     转移msg.sender的锁仓记录给addr

9. transferOwner _owner(addr)

     转移owner权限

10. getOwer()

     返回owner地址

11. changeStatus _owner()

     开启/关闭锁仓功能
