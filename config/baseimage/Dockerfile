#
# Copyright Greg Haskins All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# 基础镜像改为ubuntu16.04
FROM ubuntu:16.04
# 这里将代码拷贝到容器里
COPY scripts /tmp/scripts
# 将protobuf源码拷贝进去，这里是因为学校的网没法访问GitHub，先在自己电脑上
COPY protobuf-3.1.0.tar.gz /tmp
# 运行一些脚本，这些脚本中，所有涉及到计算机架构的内容都得进行修改
RUN cd /tmp/scripts && \
    common/packages.sh && \
    common/setup.sh && \
    docker/fixup.sh && \
    common/cleanup.sh && \
    rm -rf /tmp/scripts
# 这里是增加一些工作路径，如果使用docker的ENV命令，那么在容器启动的时候就会设置好环境变量
# docker的容器和普通的操作系统不一样，每次启动的时候并不会运行一些配置文件，把这些环境变量添加到配置文件中并不会在docker启动时自动设置。
ENV GOPATH=/opt/gopath
ENV GOROOT=/opt/go
ENV PATH=$PATH:$GOROOT/bin:$GOPATH/bin
