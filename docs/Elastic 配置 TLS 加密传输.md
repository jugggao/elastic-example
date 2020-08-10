# Elastic 配置 TLS 加密传输



## 1 准备工作


### 1.1 环境信息



| 节点名称 | IP 地址 | 说明 |
| --- | --- | --- |
| elasticsearch-node-1 | 10.10.115.11 | ES 数据节点（选取主节点） |
| elasticsearch-node-2 | 10.10.115.12 | ES 数据节点（选取主节点） |
| elasticsearch-node-3 | 10.10.115.13 | ES 数据节点（选取主节点） |
| elasticsearch-coordinate | 10.10.115.14 | ES 协调节点（作为集群负载均衡器） |
| kibana | 10.10.115.15 | Kibana 节点 |



### 1.2 准备工作

<br />在各节点上添加 Hosts 解析。
```bash
# /etc/hosts
10.10.115.11 elasticsearch-node-1.elastic.local elasticsearch-node-1
10.10.115.12 elasticsearch-node-2.elastic.local elasticsearch-node-2
10.10.115.13 elasticsearch-node-3.elastic.local elasticsearch-node-3
10.10.115.14 elasticsearch-coordinate.elastic.local elasticsearch-coordinate
10.10.115.15 kibana.elastic.local kibana
```


## 2 创建 Elastic Stack CA 证书并为 Elasticsearch 启用 TLS

<br />选择任一节点作为证书的生成节点。以下过程若非说明都在 elasticsearch-coordinate 节点上实施。<br />

### 2.1 设置 Elasticsearch 环境变量
> 根据 Elasticsearch 的下载方式和存储位置调整以下路径。

```bash
[root@elasticsearch-coordinate ~]# ES_HOME=/usr/share/elasticsearch
[root@elasticsearch-coordinate ~]# ES_CONF_PATH=/etc/elasticsearch
```


### 2.2 创建 Elastic Stack 临时证书目录
```bash
[root@elasticsearch-coordinate ~]# mkdir -p ~/elastic-cert
[root@elasticsearch-coordinate ~]# cd ~/elastic-cert
```
### 
### 2.3 创建 Elasticsearch 实例信息文件
> 将以下信息文件中的 IP 和 DNS 修改为实际的信息。
> 也可以只选择 IP 或者 DNS 进行严格认证。

```bash
[root@elasticsearch-coordinate elastic-cert]# vim ~/elastic-cert/elasticsearch-instance.yaml
# 将 elasticsearch 实例信息添加到 yaml 文件中
instances:
- name: "elasticsearch-node-1"
  ip:
  - "10.10.115.11"
  dns: 
  - "elasticsearch-node-1.elastic.local"
  - "elasticsearch-node-1"
- name: "elasticsearch-node-2"
  ip:
  - "10.10.115.12"
  dns:
  - "elasticsearch-node-2.elastic.local"
  - "elasticsearch-node-2"
- name: "elasticsearch-node-3"
  ip:
  - "10.10.115.13"
  dns: 
  - "elasticsearch-node-3.elastic.local"
  - "elasticsearch-node-3"
- name: "elasticsearch-coordinate"
  ip:
  - "10.10.115.14"
  dns: 
  - "elasticsearch-coordinate.elastic.local"
  - "elasticsearch-coordinate"
```


### 2.4 生成 Elastic Stack CA 证书
```bash
[root@elasticsearch-coordinate elastic-cert]# cd $ES_HOME
[root@elasticsearch-coordinate elasticsearch]# bin/elasticsearch-certutil ca --pem --out ~/elastic-cert/elastic-stack-ca.zip --pass

```
> 可以直接回车不使用密码。



### 2.5 解压缩 Elastic Stack CA 证书
```bash
[root@elasticsearch-coordinate elasticsearch]# cd ~/elastic-cert/
[root@elasticsearch-coordinate elastic-cert]# unzip elastic-stack-ca.zip -d ./elastic-stack-ca
```
可以观察到解压的 CA 证书文件：
```bash
Archive:  elastic-stack-ca.zip
   creating: ./elastic-stack-ca/ca/
  inflating: ./elastic-stack-ca/ca/ca.crt  
  inflating: ./elastic-stack-ca/ca/ca.key
```


### 2.6 通过 CA 证书生成 Elasticsearch 节点证书
```bash
[root@elasticsearch-coordinate elastic-cert]# cd $ES_HOME
[root@elasticsearch-coordinate elasticsearch]# bin/elasticsearch-certutil cert \
> --ca-cert ~/elastic-cert/elastic-stack-ca/ca/ca.crt \
> --ca-key ~/elastic-cert/elastic-stack-ca/ca/ca.key \
> --in ~/elastic-cert/elasticsearch-instance.yaml \
> --out ~/elastic-cert/elasticsearch-certs.zip --pem
```


### 2.7 解压缩 Elasticsearch 节点证书
```bash
[root@elasticsearch-coordinate elasticsearch]# cd ~/elastic-cert/
[root@elasticsearch-coordinate elastic-cert]# unzip elasticsearch-certs.zip -d ./elasticsearch-certs
```
可以观察到解压的证书文件有各 Elasticsearch 节点的证书：
```bash
Archive:  elasticsearch-certs.zip
   creating: ./elasticsearch-certs/elasticsearch-node-1/
  inflating: ./elasticsearch-certs/elasticsearch-node-1/elasticsearch-node-1.crt  
  inflating: ./elasticsearch-certs/elasticsearch-node-1/elasticsearch-node-1.key  
   creating: ./elasticsearch-certs/elasticsearch-node-2/
  inflating: ./elasticsearch-certs/elasticsearch-node-2/elasticsearch-node-2.crt  
  inflating: ./elasticsearch-certs/elasticsearch-node-2/elasticsearch-node-2.key  
   creating: ./elasticsearch-certs/elasticsearch-node-3/
  inflating: ./elasticsearch-certs/elasticsearch-node-3/elasticsearch-node-3.crt  
  inflating: ./elasticsearch-certs/elasticsearch-node-3/elasticsearch-node-3.key  
   creating: ./elasticsearch-certs/elasticsearch-coordinate/
  inflating: ./elasticsearch-certs/elasticsearch-coordinate/elasticsearch-coordinate.crt  
  inflating: ./elasticsearch-certs/elasticsearch-coordinate/elasticsearch-coordinate.key
```


### 2.8 将证书分发到各个 Elasticsearch 节点
```bash
# 首先在各 elasticsearch 节点上创建证书目录
[root@elasticsearch-coordinate elastic-cert]# for node in $(cat /etc/hosts | awk '/elasticsearch/{print $NF}'); \
> do ssh ${node} mkdir $ES_CONF_PATH/certs; done
# 分发各节点证书
[root@elasticsearch-coordinate elastic-cert]# for node in $(cat /etc/hosts | awk '/elasticsearch/{print $NF}'); \
> do scp elastic-stack-ca/ca/ca.crt elasticsearch-certs/${node}/*  ${node}:$ES_CONF_PATH/certs; done
```
### 2.9 添加各 Elasticsearch 节点安全配置
在各 Elasticsearch 节点上编辑配置文件。<br />
<br />elasticsearch-node-1 节点配置文件末尾添加：
```yaml
# ---------------------------------- Security ----------------------------------
xpack.security.enabled: true
xpack.security.http.ssl.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.http.ssl.key: certs/elasticsearch-node-1.key
xpack.security.http.ssl.certificate: certs/elasticsearch-node-1.crt
xpack.security.http.ssl.certificate_authorities: certs/ca.crt
xpack.security.transport.ssl.key: certs/elasticsearch-node-1.key
xpack.security.transport.ssl.certificate: certs/elasticsearch-node-1.crt
xpack.security.transport.ssl.certificate_authorities: certs/ca.crt
```
elasticsearch-node-2 节点配置文件末尾添加：
```yaml
# ---------------------------------- Security ----------------------------------
xpack.security.enabled: true
xpack.security.http.ssl.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.http.ssl.key: certs/elasticsearch-node-2.key
xpack.security.http.ssl.certificate: certs/elasticsearch-node-2.crt
xpack.security.http.ssl.certificate_authorities: certs/ca.crt
xpack.security.transport.ssl.key: certs/elasticsearch-node-2.key
xpack.security.transport.ssl.certificate: /certs/elasticsearch-node-2.crt
xpack.security.transport.ssl.certificate_authorities: certs/ca.crt
```
elasticsearch-node-3 节点配置末尾添加：
```yaml
# ---------------------------------- Security ----------------------------------
xpack.security.enabled: true
xpack.security.http.ssl.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.http.ssl.key: certs/elasticsearch-node-3.key
xpack.security.http.ssl.certificate: certs/elasticsearch-node-3.crt
xpack.security.http.ssl.certificate_authorities: certs/ca.crt
xpack.security.transport.ssl.key: certs/elasticsearch-node-3.key
xpack.security.transport.ssl.certificate: certs/elasticsearch-node-3.crt
xpack.security.transport.ssl.certificate_authorities: certs/ca.crt
```
elasticsearch-coordinate 节点配置末尾添加：
```yaml
# ---------------------------------- Security ----------------------------------
xpack.security.enabled: true
xpack.security.http.ssl.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.http.ssl.key: certs/elasticsearch-coordinate.key
xpack.security.http.ssl.certificate: certs/elasticsearch-coordinate.crt
xpack.security.http.ssl.certificate_authorities: certs/ca.crt
xpack.security.transport.ssl.key: certs/elasticsearch-coordinate.key
xpack.security.transport.ssl.certificate: certs/elasticsearch-coordinate.crt
xpack.security.transport.ssl.certificate_authorities: certs/ca.crt
```


### 2.10 重启各 Elasticsearch 节点并查看集群日志
```bash
[root@elasticsearch-client elastic-cert]# systemctl restart elasticsearch & tail -f /data/log/elasticsearch/elasticsearch-cluster.log
```


### 2.11 生成 Elasticsearch 内置用户
```bash
[root@elasticsearch-client elastic-cert]# cd $ES_HOME
[root@elasticsearch-coordinate elasticsearch]# bin/elasticsearch-setup-passwords auto -b
```
会生成一系列角色的用户密码：
```bash
Changed password for user apm_system
PASSWORD apm_system = 隐藏

Changed password for user kibana_system
PASSWORD kibana_system = 隐藏

Changed password for user kibana
PASSWORD kibana = 隐藏

Changed password for user logstash_system
PASSWORD logstash_system = 隐藏

Changed password for user beats_system
PASSWORD beats_system = 隐藏

Changed password for user remote_monitoring_user
PASSWORD remote_monitoring_user = 隐藏

Changed password for user elastic
PASSWORD elastic = 隐藏
```


### 2.12 通过 HTTPS 查看 Elasticsearch 集群状态
```bash
[root@elasticsearch-coordinate elasticsearch]# curl --cacert ~/elastic-cert/elastic-stack-ca/ca/ca.crt \
> -u "elastic:隐藏" https://elasticsearch-coordinate.elastic.local:9200/_cat/nodes?v 
```
会看到以下信息：
```bash
ip           heap.percent ram.percent cpu load_1m load_5m load_15m node.role master name
10.10.115.12           54          97  14    0.53    1.07     0.54 dilmrt    *      elasticsearch-node-2
10.10.115.13           40          97   2    0.24    0.54     0.30 dilmrt    -      elasticsearch-node-3
10.10.115.11           50          97   6    0.69    1.07     0.53 dilmrt    -      elasticsearch-node-1
10.10.115.14           33          66   2    0.06    0.09     0.08 -         -      elasticsearch-coordinate
```


## 3 Kibana 启用 TLS

<br />除非特殊说明，其他步骤均在 Kibana 节点上进行。<br />

### 3.1 创建 Kibana 实例信息文件
> 在 elasticsearch-coordinate 节点上操作。

```bash
[root@elasticsearch-coordinate elastic-cert]# vim ~/elastic-cert/kibana-instance.yaml
# 添加 kibana 实例信息至 yaml 文件中
instances:
- name: "kibana"
  ip:
  - "10.10.115.15"
  dns:
  - "kibana.elastic.local"
  - "kibana"
```


### 3.2 通过 CA 证书生成 Kibana 节点证书
> 在 elasticsearch-coordinate 节点上操作。

```bash
[root@elasticsearch-coordinate elastic-cert]# cd $ES_HOME
[root@elasticsearch-coordinate elasticsearch]# bin/elasticsearch-certutil cert \
> --ca-cert ~/elastic-cert/elastic-stack-ca/ca/ca.crt \
> --ca-key ~/elastic-cert/elastic-stack-ca/ca/ca.key \
> --in ~/elastic-cert/kibana-instance.yaml \
> --out ~/elastic-cert/kibana-certs.zip --pem
```


### 3.3 解压缩 Kibana 节点证书
> 在 elasticsearch-coordinate 节点上操作。

```bash
[root@elasticsearch-coordinate elasticsearch]# cd ~/elastic-cert/
[root@elasticsearch-coordinate elastic-cert]# unzip kibana-certs.zip -d ./kibana-certs
```
可以观察到解压的证书文件有 Kibana 节点的证书：
```bash
Archive:  kibana-certs.zip
   creating: ./kibana-certs/kibana/
  inflating: ./kibana-certs/kibana/kibana.crt  
  inflating: ./kibana-certs/kibana/kibana.key
```
### 3.1 设置 Kibana 环境变量
> 同样，需要根据 Kiabna 的下载方式和存储位置调整以下路径。

```bash
[root@kibana ~]# KIBANA_HOME=/usr/share/kibana
[root@kibana ~]# KIBANA_CONF_PATH=/etc/kibana
```


### 3.2 创建 Kibana 证书目录并拷贝 Kibana 节点证书
```bash
[root@kibana ~]# cd $KIBANA_CONF_PATH
[root@kibana kibana]# mkdir certs
[root@kibana kibana]# scp elasticsearch-coordinate:"~/elastic-cert/elastic-stack-ca/ca/ca.crt ~/elastic-cert/kibana-certs/kibana/*" certs/
```


### 3.3 添加 Kibana 安全配置
```yaml
server.host: kibana.elastic.local
server.name: kibana
elasticsearch.hosts: ["https://elasticsearch-coordinate:9200"]
elasticsearch.username: kibana
elasticsearch.password: 隐藏
server.ssl.enabled: true
server.ssl.certificate: /etc/kibana/certs/kibana.crt
server.ssl.key: /etc/kibana/certs/kibana.key
elasticsearch.ssl.certificateAuthorities: ["/etc/kibana/ca.crt"]
```


### 3.4 重启 Kibana 并观察日志
```bash
[root@kibana kibana]# systemctl restart kibana & journalctl -f -u kibana
```

<br />

## 4 Filebaet 启用 TLS


### 4.1 创建 Filebeat 实例信息
```bash
[root@elasticsearch-coordinate elastic-cert]# vi filebeat-instance.yaml
instances:
- name: "filebeat"
  dns:
  - "filebeat.elastic.local"
  - "filebeat"
  - "filebeat.elastic"
  - "filebeat.elastic.svc.cluster.local"
```


### 4.2 生成 Filebeat 节点证书
```bash
[root@elasticsearch-coordinate elastic-cert]# cd $ES_HOME
[root@elasticsearch-coordinate elasticsearch]# bin/elasticsearch-certutil cert \
> --ca-cert ~/elastic-cert/elastic-stack-ca/ca/ca.crt \
> --ca-key ~/elastic-cert/elastic-stack-ca/ca/ca.key \
> --in ~/elastic-cert/filebeat-instance.yaml \
> --out ~/elastic-cert/filebeat-certs.zip --pem
[root@elasticsearch-coordinate elasticsearch]# cd ~/elastic-cert/
[root@elasticsearch-coordinate elastic-cert]# unzip filebeat-certs.zip -d ./filebeat-certs
```
可以观察到生产的 Filebeat 证书有：
```bash
Archive:  filebeat-certs.zip
   creating: ./filebeat-certs/filebeat/
  inflating: ./filebeat-certs/filebeat/filebeat.crt  
  inflating: ./filebeat-certs/filebeat/filebeat.key
```


### 4.3 拷贝 Filebeat 证书至 Filebeat 节点
> 非容器环境

```bash
[root@nginx ~]# mkdir /etc/filebeat/certs 
[root@nginx ~]# scp elasticsearch-coordinate:"~/elastic-cert/elastic-stack-ca/ca/ca.crt ~/elastic-cert/filebeat-certs/filebeat/*" /etc/filebeat/certs/
```


### 4.4 添加 Filebeat 安全配置
```bash
[root@nginx filebeat]# vim filebeat.yml 
output.elasticsearch:
  # Array of hosts to connect to.
  hosts: ["https://elasticsearch-coordinate:9200"]
  ssl.certificate_authorities: ["/etc/filebeat/certs/ca.crt"]
  ssl.certificate: "/etc/filebeat/certs/filebeat.crt"
  ssl.key: "/etc/filebeat/certs/filebeat.key"
```


### 4.5 启动 Filebeat 并观察日志
```bash
[root@nginx filebeat]# systemctl restart filebeat.service & journalctl -f -u filebeat.service
```


## 5 Metricbeat 启用 TLS

<br />Metricbeat 部署至 Kubernetes 集群中。<br />

### 5.1 创建 Merticbeat 实例信息
> 由于 Metricbeat 部署在 Kubernetes 集群中，IP 不固定。
> 所以只添加 DNS 认证，并添加多个备用域名。

```bash
[root@elasticsearch-coordinate elastic-cert]# vim ~/elastic-cert/metricbeat-instance.yaml
# 将 metricbeat 实例信息添加至 yaml 文件中
instances:
- name: "metricbeat"
  dns:
  - "metricbeat.elastic.local"
  - "metricbeat"
  - "metricbeat.elastic"
  - "metricbeat.elastic.svc.cluster.local"
  - "metricbeat.example.com"
```


### 5.2 生成 Merticbeat 节点证书
> 以下步骤在 elasticsearch-coordinate 节点完成。

生成的步骤类似，都通过 Elastic Stack CA 证书来颁发节点证书。在此就简化为一个步骤。
```bash
[root@elasticsearch-coordinate elastic-cert]# cd $ES_HOME
[root@elasticsearch-coordinate elasticsearch]# bin/elasticsearch-certutil cert \
> --ca-cert ~/elastic-cert/elastic-stack-ca/ca/ca.crt \
> --ca-key ~/elastic-cert/elastic-stack-ca/ca/ca.key \
> --in ~/elastic-cert/metricbeat-instance.yaml \
> --out ~/elastic-cert/metricbeat-certs.zip --pem
[root@elasticsearch-coordinate elasticsearch]# cd ~/elastic-cert/
[root@elasticsearch-coordinate elastic-cert]# unzip metricbeat-certs.zip -d ./metricbeat-certs
```
可以观察到生产的 merticbeat 证书有：
```bash
Archive:  merticbeat-certs.zip
   creating: ./metricbeat-certs/metricbeat/
  inflating: ./metricbeat-certs/metricbeat/metricbeat.crt  
  inflating: ./metricbeat-certs/metricbeat/metricbeat.key
```


### 5.3 使用证书创建 Kubernetes Secret 对象
```bash
[root@elasticsearch-coordinate elastic-cert]# base64 elastic-stack-ca/ca/ca.crt
# 生成我们需要使用的加密上下文
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURTVENDQWpHZ0F3SUJBZ0lVUURNR1hmSDVL
...

[root@elasticsearch-coordinate elastic-cert]# base64 metricbeat-certs/merticbeat/merticbeat.crt 
LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURxekNDQXBPZ0F3SUJBZ0lWQUxMczlDVFJS
...

[root@elasticsearch-coordinate elastic-cert]# base64 metricbeat-certs/merticbeat/merticbeat.key 
LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb2dJQkFBS0NBUUVBblVad09OcVRY
...
```
创建 metricbeat-certs-internal Secret 对象：
```yaml
# metricbeat-certs-internal.yaml
---
apiVersion: v1
kind: Secret
metadata:
  labels:
    elasticsearch-cluster-name: elasticsearch-cluster
  name: metricbeat-certs-internal
  namespace: elastic
type: Opaque
data:
  ca.crt: |-
    LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURTVENDQWpHZ0F3SUJBZ0lVUURNR1hmSDVL
    ...
  metricbeat.crt: |-
    LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURxekNDQXBPZ0F3SUJBZ0lWQUxMczlDVFJS
    ...
  metricbeat.key: |-
    LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb2dJQkFBS0NBUUVBblVad09OcVRY
		...
```


### 5.4 Metricbeat ConfigMap 添加 TLS 配置
```bash
    output.elasticsearch:
      hosts: ['${ELASTICSEARCH_HOST:elasticsearch}:${ELASTICSEARCH_PORT:9200}']
      username: ${ELASTICSEARCH_USERNAME}
      password: ${ELASTICSEARCH_PASSWORD}
      protocol: ${ELASTICSEARCH_PROTOCOL}
      ssl.certificate_authorities: /usr/share/metricbeat/certs/ca.crt
      ssl.certificate: /usr/share/metricbeat/certs/metricbeat.crt
      ssl.key: /usr/share/metricbeat/certs/metricbeat.key
```


### 5.5 Metricbeat DaemonSet/Deployment 添加证书挂载
```bash
        volumeMounts:
        - name: certs
          mountPath: /usr/share/metricbeat/certs
          readOnly: true
      volumes:
      - name: certs
        secret:
          secretName: metricbeat-certs-internal
```


## 6 Logstash 启用 TLS


### 6.1 创建 Logstash 实例信息

<br />

## 参考


- [elasticsearch-certutil](https://www.elastic.co/guide/en/elasticsearch/reference/current/certutil.html)
- [Encrypting communications in Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/configuring-tls.html)
- [Setting up TLS on a cluster](https://www.elastic.co/guide/en/elasticsearch/reference/current/ssl-tls.html)
