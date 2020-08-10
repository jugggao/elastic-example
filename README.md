# Elastic

## 工具介绍

- Logstash：用于收集、处理、传输日志数据
- Kafka：日志消息队列
- Kube-state-metrics: 用于监听 Kubernetes API，暴露每个资源对象状态相关指标数据
- Metricbeat: 用于收集指标数据
- Elasticsearch：用于实时查询和解析数据
- Kibana：用于数据可视化



## 部署

[使用 Ansible 部署 Elastic 集群](./elastic-ansible)

[使用 Ansible 部署 Kafka 集群](./kafka-ansible)

[Kubernetes 部署 Kafka 集群](./docs/Kubernetes%20部署%20Kafka%20集群.md)

[Elastic 配置 TLS 加密传输](./docs/Elastic%20配置%20TLS%20加密传输.md)

## 日志

### Logback Spring 日志处理

[Logback Spring 配置文件参考](./logback/logback-spring.conf)

[Logback kafka 依赖配置文件参考](./logback/pom.xml)

- 

[Logstash 处理 Logback 日志管道参考](./logstash/logback-spring.conf)


## 监控

[Kubernetes Kube-state-metrics 部署文件参考](./kubernetes/kube-state-metrics)

[Kubernetes Metricbeat 部署文件参考](./kubernetes/metricbeat)

