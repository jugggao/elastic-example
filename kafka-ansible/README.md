# Kafka 集群

## 常用命令

**查看 Zookeeper 状态**

```bash
# 修改 zookeeper-server-start.sh
EXTRA_ARGS=${EXTRA_ARGS-'-name zookeeper -loggc -Dzookeeper.4lw.commands.whitelist=*'}

# 重启 zookeeper
systemctl restart zookeeper.service
```

```bash
# 输入可以被用来监视群集健康状态的变量列表
echo mntr | nc localhost 2181
# 列出端和连接的客户端的简明信息
echo stat | nc localhost 2181
# 列出服务端的详细信息
echo srvr | nc localhost 2181
# 打印服务端详细信息
echo envi | nc localhost 2181
```


## 配置说明

**Zookeeper 配置说明**

| 配置项 | 名称 | 说明 |
| --- | --- | --- |
| tickTime | CS 通信心跳间隔 | 服务器之间或客户端与服务器之间维持心跳的时间间隔，也就是每间隔 tickTime 时间就会发送一个心跳。tickTime 以毫秒为单位。 |
| initLimit | LF 初始通信时限 | 集群中的 follower server(F) 与 leader server(L) 之间初始连接时能容忍的最多心跳数 |
| syncLimit | LF 同步通信时限 | 集群中的 follower 服务器与 leader 服务器之间请求和应答之间能容忍的最多心跳数 |
| dataDir | 数据文件目录 | Zookeeper 保存数据的目录，默认情况下，Zookeeper 将写数据的日志文件也保存在这个目录里 |
| dataLogDir | 日志文件目录 | Zookeeper 保存日志文件的目录 |
| clientPort | 客户端连接端口 | 客户端连接 Zookeeper 服务器的端口，Zookeeper 会监听这个端口，接受客户端的访问请求 |
| server.N | 服务器名称与地址 | 从N开始依次为：服务编号、服务地址、LF通信端口、选举端口；例如：server.1=192.168.88.11:2888:3888 |

**Kafka 配置说明**

| 配置项 | 默认值/示例值 | 说明 |
| --- | --- | --- |
| broker.id | 0 | Broker 唯一标识 |
| listeners | PLAINTEXT://192.168.88.53:9092 | 监听信息，PLAINTEXT 表示明文传输 |
| log.dirs | kafka/logs | kafka 数据存放地址，可以填写多个。用 "," 间隔 |
| message.max.bytes | message.max.bytes | 单个消息长度限制，单位是字节 |
| num.partitions | 1 | 默认分区数 |
| log.flush.interval.messages | Long.MaxValue | 在数据被写入到硬盘和消费者可用前最大累积的消息的数量 |
| log.flush.interval.ms | Long.MaxValue | 在数据被写入到硬盘前的最大时间 |
| log.flush.scheduler.interval.ms | Long.MaxValue | 检查数据是否要写入到硬盘的时间间隔。 |
| log.retention.hours | 24 | 控制一个 log 保留时间，单位：小时 |
| zookeeper.connect | 192.168.88.21:2181 | ZooKeeper 服务器地址，多台用 "," 间隔 |
