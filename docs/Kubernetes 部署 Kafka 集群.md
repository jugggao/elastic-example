# Kafka Kubernetes 部署 Kafka 集群

## 1 环境版本
```bash
# kubernetes 版本
Client Version: version.Info{Major:"1", Minor:"15", GitVersion:"v1.15.0", GitCommit:"e8462b5b5dc2584fdcd18e6bcfe9f1e4d970a529", GitTreeState:"clean", BuildDate:"2019-06-19T16:40:16Z", GoVersion:"go1.12.5", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"16+", GitVersion:"v1.16.9-aliyun.1", GitCommit:"4f7ea78", GitTreeState:"", BuildDate:"2020-05-08T07:29:59Z", GoVersion:"go1.13.9", Compiler:"gc", Platform:"linux/amd64"}

# helm 版本
version.BuildInfo{Version:"v3.1.1", GitCommit:"afe70585407b420d0097d07b21c47dc511525ac8", GitTreeState:"clean", GoVersion:"go1.13.8"}
```


## 2 添加仓库
```bash
helm repo add incubator http://mirror.azure.cn/kubernetes/charts-incubator/
helm repo update
```

<br />将 Kafka 的 Helm Chart 包下载到本地，这有助于我们了解 Chart 包的使用方法，当然也可以省去这一步：<br />

```bash
helm fetch incubator/kafka
tar zxf kafka-0.21.2.tgz
```
### 
## 3 创建变量文件
```bash
resources:
  limits:
    cpu: 200m
    memory: 1536Mi
  requests:
    cpu: 100m
    memory: 1024Mi

livenessProbe:
  initialDelaySeconds: 60

persistence:
  storageClass: "alicloud-nas-subpath" # 根据当前环境指定 storageClass，这里我使用的阿里云的 csi
```


## 4 部署
```bash
kubectl create namespace kafka

helm install -f kafka.yaml kafka incubator/kafka --namespace kafka
```


## 5 测试


### 5.1 创建测试 Pod


```bash
apiVersion: v1
kind: Pod
metadata:
  name: testclient
  namespace: kafka
spec:
  containers:
  - name: kafka
    image: confluentinc/cp-kafka:5.0.1
    command:
      - sh
      - -c
      - "exec tail -f /dev/null"
```
```bash
kubectl apply -f testclient.yaml
kubectl get pods -n kafka
```


### 5.2 创建 Topic
```bash
kubectl -n kafka exec testclient -- kafka-topics --zookeeper kafka-zookeeper:2181 --topic test1 --create --partitions 1 --replication-factor 1
```


### 5.3 监听 Topic
```bash
kubectl -n kafka exec -ti testclient -- kafka-console-consumer --bootstrap-server kafka:9092 --topic test1 --from-beginning
```


### 5.4 生成消息

<br />新开一个终端生成消息：
```bash
kubectl -n kafka exec -ti testclient -- kafka-console-producer --broker-list kafka-headless:9092 --topic test1
>Hello kafka on kubernetes
```
另一个终端的监视器可以看到对应的消息：
```bash
kubectl -n kafka exec -ti testclient -- kafka-console-consumer --bootstrap-server kafka:9092 --topic test1 --from-beginning
Hello kafka on kubernetes
```


## 6 完成

<br />到这里就表明我们部署的 kafka 已经成功运行在了 Kubernetes 集群上面。当然我们这里只是在测试环境上使用，对于在生产环境上是否可以将 kafka 部署在 Kubernetes 集群上需要考虑的情况就非常多了，对于有状态的应用都更加推荐使用 Operator 去使用，比如 [Confluent 的 Kafka Operator](https://www.confluent.io/product/confluent-platform/flexible-devops-automation/)，总之，你能 hold 住就无所谓。
