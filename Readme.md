## ETD Lock Contract

address: 0x4b5116c166e7E1682335fE50ACB9e7C01e34b14c
minutes version address: 0x2c8AAbD89dCc7aD8a8426011367680cAE267175B

1. Lock_540（addr, amount, usdtTxid）

   1. addr为锁仓收款地址
   2. amount为锁定数量，要求msg.sender.value >= amount
   3. 释放规则(分为两个线性阶段)：
      1. 从锁仓开始记为第⼀天，在第15天释放 amount * 5%；（⼀期）
      2. 从第16天开始，持续540天，每天释放amount*95%的1/540；（540期）

2. withdrawAll()

     提取msg.sender的当前可以提取的所有ETD

3. withdrawAmount(amount)// refuse if amount > num_unlocked

     提取msg.sender的当前可提取的amount数量ETD，若当前可提取数量不⾜amount，则失败

4. querySelf()// {now, addr, lockedAmount, withdrawed, startTime}

     查询msg.sender的锁仓列表

5. queryAll _owner(start, size)// {now, []{addr, lockedAmount, withdrawed, startTime}}

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