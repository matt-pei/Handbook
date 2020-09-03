
## 删除数据表的三种方式
### 用法：
* 1、当你不再需要该表时,用drop;
* 2、当你仍要保留该表，但要删除所有记录时， 用 truncate;
* 3、当你要删除部分记录或者有可能会后悔的话,用delete。

### 删除程度可从强到弱如下排列：
* 1、`drop table tb`;drop 是直接将表格删除，无法找回。
    
    例如删除 user 表：
    ```
    drop table user;
    ```
* 2、`truncate (table) tb`;truncate 是删除表中所有数据，但不能与where一起使用；
    ```
    TRUNCATE TABLE user;
    ```
* 3、`delete from tb (where)`;
    delete 也是删除表中数据，但可以与where连用，删除特定行；
    ```
    删除表中所有数据
    delete from user;
    ```
    ```
    删除指定行
    delete from user where username ='Tom';
    ```

### truncate 和 delete 的区别：
1. 事物

    truncate删除后不记录mysql日志，因此不可以rollback，更不可以恢复数据；而 delete是可以rollback ；

    原因：truncate相当于保留原mysql表的结果，重新创建了这个表，所有的状态都相当于新的，而delete的效果相当于一行行删除，所以可以rollback;

2. 效果

    效率上truncate比delete快，而且truncate删除后将重建索引（新插入数据后id从0开始记起），而delete不会删除索引（新插入的数据将在删除数据的索引后继续增加）

3. truncate 不会触发任何 DELETE触发器；

4. 返回值

    delete操作后返回删除的记录数，而 truncate返回的是0或者-1（成功则返回0，失败返回-1）；

    delete与delete from区别：
如果只针对一张表进行删除，则效果一样；如果需要联合其他表，则需要使用from ：
    ```
    delete tb1 from tb1 m where id in (select id from tb2)
    ```