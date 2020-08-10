#!/bin/bash

curl -4 -s 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=********************' \
  -H 'Content-Type: application/json' \
  -d "
  {
     \"msgtype\": \"markdown\",
     \"markdown\": {
        \"content\": \"**Logback 错误日志报警**\n\n> <font color="comment">Deployment:</font> $1\n\n> <font color="comment">Namespace:</font> $2\n\n> <font color="comment">AppName:</font> $3\n\n> <font color="comment">LogTime:</font> $4\n\n> <font color="comment">Class:</font> $5\n\n> <font color="comment">ErrorLog:</font> $6\"
    }
  }"