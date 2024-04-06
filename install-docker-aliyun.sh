#!/bin/bash

function install_docker() {
  sudo yum install -y yum-utils device-mapper-persistent-data lvm2
  sudo yum-config-manager --add-repo http://mirrors.cloud.aliyuncs.com/docker-ce/linux/centos/docker-ce.repo
  sudo sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
  sudo yum makecache fast
  sudo yum -y install docker-ce
  sudo service docker start
}

if [ ! -f /usr/bin/docker ]; then
  install_docker
  echo "Docker安装完成"
  docker -v
else
  echo "Docker已安装"
  docker -v
fi