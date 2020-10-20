#!/bin/sh

# 构建，# Build image
docker build -t vapor_one . -f ./serverless/Dockerfile.build


# 创建，提取容器
docker create --name extract vapor_one
# 复制，容器内，内容
docker cp extract:/staging ./app
# 删除，提取容器
docker rm -f extract
