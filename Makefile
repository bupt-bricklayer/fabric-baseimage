#
# Copyright Greg Haskins All Rights Reserved.
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# -------------------------------------------------------------
# This makefile defines the following targets
#
#   - all - Builds the baseimages and the thirdparty images
#   - docker - Builds the baseimages (baseimage,basejvm,baseos)
#   - dependent-images - Builds the thirdparty images (couchdb,kafka,zookeeper)
#   - couchdb - Builds the couchdb image
#   - kafka - Builds the kafka image
#   - zookeeper - Builds the zookeeper image
#   - install - Builds the baseimage,baseos,basejvm and publishes the images to dockerhub
#   - clean - Cleans all the docker images

# 这里的?=是，如果左边的变量没有被定义，便定义为右边的值
# 另外关于Makefile中的=详见
# https://blog.csdn.net/FJDJFKDJFKDJFKD/article/details/83090568?utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromMachineLearnPai2%7Edefault-2.control&dist_request_id=1619681299808_75186&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromMachineLearnPai2%7Edefault-2.control
DOCKER_NS ?= hyperledger
BASENAME ?= $(DOCKER_NS)/fabric
VERSION ?= 0.4.22

# 这里的$()既可以执行命令行命令，也可以返回变量的值，和shell编程中不同，shell中变量的返回只能使用$变量，而Makefile中变量值的返回可以用$()，也可以直接$变量
ARCH=$(shell go env GOARCH)
DOCKER_TAG ?= $(ARCH)-$(VERSION)

# ifneq是判断两个变量是否不相等，这里第二个参数为空，就是当第一个参数不为空是会执行下边的命令
ifneq ($(http_proxy),)
DOCKER_BUILD_FLAGS+=--build-arg 'http_proxy=$(http_proxy)'
endif
ifneq ($(https_proxy),)
DOCKER_BUILD_FLAGS+=--build-arg 'https_proxy=$(https_proxy)'
endif
ifneq ($(HTTP_PROXY),)
DOCKER_BUILD_FLAGS+=--build-arg 'HTTP_PROXY=$(HTTP_PROXY)'
endif
ifneq ($(HTTPS_PROXY),)
DOCKER_BUILD_FLAGS+=--build-arg 'HTTPS_PROXY=$(HTTPS_PROXY)'
endif
ifneq ($(no_proxy),)
DOCKER_BUILD_FLAGS+=--build-arg 'no_proxy=$(no_proxy)'
endif
ifneq ($(NO_PROXY),)
DOCKER_BUILD_FLAGS+=--build-arg 'NO_PROXY=$(NO_PROXY)'
endif

DBUILD = docker build $(DOCKER_BUILD_FLAGS)

# NOTE this is for building the dependent images (kafka, zk, couchdb)
BASE_DOCKER_NS ?= hyperledger

DOCKER_IMAGES = baseos baseimage
DEPENDENT_IMAGES = couchdb kafka zookeeper
DUMMY = .$(DOCKER_TAG)

# 这是Makefile的语法
# target：目标
# (tab键)命令行
# Makefile只会执行一条target语句。可以在make命令后指定需要执行的target，这个文件的第8行给出了本文件所有的target
# 如果make后缺省命令，则只会执行第一条target（从上往下），例如这个文档中会执行all
all: docker dependent-images

# 由docker目标调用此目标
# %可能是baseos或者baseimage
build/docker/%/$(DUMMY):
	# eval可以理成变量的定义
	# ${@}代表所有目标项，这里只有一项，为build/docker/baseos/$(DUMMY)或者build/docker/baseimage/$(DUMMY)
	$(eval TARGET = ${patsubst build/docker/%/$(DUMMY),%,${@}})
	$(eval DOCKER_NAME = $(BASENAME)-$(TARGET))
	# $(@D)表示$@的目录部分
	# 如果@在命令前，则命令不会被make显示
	@mkdir -p $(@D)
	# 这里TARGET只可能是baseos或者baseimage
	@echo "Building docker $(TARGET)"
	docker build -f config/$(TARGET)/Dockerfile \
		-t $(DOCKER_NAME) \
		-t $(DOCKER_NAME):$(DOCKER_TAG) \
		.
	@touch $@

build/docker/%/.push: build/docker/%/$(DUMMY)
	@docker login \
		--username=$(DOCKER_HUB_USERNAME) \
		--password=$(DOCKER_HUB_PASSWORD)
	@docker push $(BASENAME)-$(patsubst build/docker/%/.push,%,$@):$(DOCKER_TAG)

# patsubst 子串查找函数，有三个参数，在第三个参数中查找第一个参数并替换为第二个参数然后返回
# %是通配符，类似linux中的*,当第二个参数中出现%后，会替换为第一个参数中%所匹配的内容
# 下边语句作用是将$(DOCKER_IMAGES)替换成为build/docker/$(DOCKER_IMAGES)/$(DUMMY)
docker: $(patsubst %,build/docker/%/$(DUMMY),$(DOCKER_IMAGES))

install: $(patsubst %,build/docker/%/.push,$(DOCKER_IMAGES))

dependent-images: $(DEPENDENT_IMAGES)

dependent-images-install:  $(patsubst %,build/image/%/.push,$(DEPENDENT_IMAGES))

couchdb: build/image/couchdb/$(DUMMY)

kafka: build/image/kafka/$(DUMMY)

zookeeper: build/image/zookeeper/$(DUMMY)

build/image/%/$(DUMMY):
	@mkdir -p $(@D)
	$(eval TARGET = ${patsubst build/image/%/$(DUMMY),%,${@}})
	@echo "Docker: building $(TARGET) image"
	$(DBUILD) ${BUILD_ARGS} -t $(DOCKER_NS)/fabric-$(TARGET) -f images/${TARGET}/Dockerfile images/${TARGET}
	docker tag $(DOCKER_NS)/fabric-$(TARGET) $(DOCKER_NS)/fabric-$(TARGET):$(DOCKER_TAG)
	@touch $@

build/image/%/.push: build/image/%/$(DUMMY)
	@docker login \
		--username=$(DOCKER_HUB_USERNAME) \
		--password=$(DOCKER_HUB_PASSWORD)
	@docker push $(BASENAME)-$(patsubst build/image/%/.push,%,$@):$(DOCKER_TAG)

clean:
	-rm -rf build
