#!/bin/bash

function install_cri_dockerd() {
    if [ -f "$cdtgz_path" ]; then
        echo "cri-dockerd.tgz文件存在"
        tar xf $cdtgz_path
        cp cri-dockerd/cri-dockerd /usr/bin/
        chmod +x /usr/bin/cri-dockerd
        echo "cri-dockerd安装完成"
      fi
}

function download_cri_dockerd() {
  wget https://mirror.ghproxy.com/https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.11/cri-dockerd-0.3.11.amd64.tgz
}


if [ -f /usr/bin/cri-dockerd ]; then
  echo "cri-dockerd已安装"
  cri-dockerd -v
  exit 0
fi

cdtgz_path=$(find . -name 'cri-dockerd*.tgz')
if [ -f "$cdtgz_path" ]; then
  echo "cri-dockerd.tgz文件不存在"
  download_cri_dockerd
  install_cri_dockerd
else
  echo "cri-dockerd.tgz文件存在"
  install_cri_dockerd
fi
