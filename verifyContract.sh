#!/bin/bash

# 定义变量
API_URL="https://api.basescan.org/api"
MODULE="contract"
ACTION="verifysourcecode"
API_KEY="YourApiKeyToken" # 请替换为你的API密钥

# 发送请求
curl -X GET "$API_URL?module=$MODULE&action=$ACTION&apikey=$API_KEY"
