#!/bin/bash

function install_cri_dockerd_service() {
    cat > /usr/lib/systemd/system/cri-docker.service << EOF
    [Unit]
    Description=CRI Interface for Docker Application Container Engine
    Documentation=https://docs.mirantis.com
    After=network-online.target firewalld.service docker.service
    Wants=network-online.target
    Requires=cri-docker.socket
    [Service]
    Type=notify
    ExecStart=/usr/bin/cri-dockerd --network-plugin=cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.7
    ExecReload=/bin/kill -s HUP $MAINPID
    TimeoutSec=0
    RestartSec=2
    Restart=always
    StartLimitBurst=3
    StartLimitInterval=60s
    LimitNOFILE=infinity
    LimitNPROC=infinity
    LimitCORE=infinity
    TasksMax=infinity
    Delegate=yes
    KillMode=process
    [Install]
    WantedBy=multi-user.target
EOF
}

function install_cri_dockerd_socket() {
  cat > /usr/lib/systemd/system/cri-docker.socket <<"EOF"
           [Unit]
           Description=CRI Docker Socket for the API
           PartOf=cri-docker.service
           [Socket]
           ListenStream=%t/cri-dockerd.sock
           SocketMode=0660
           SocketUser=root
           SocketGroup=docker
           [Install]
           WantedBy=sockets.target
EOF
}

function rewrite_containerd_config() {
  CONFIG_FILE="/etc/containerd/config.toml"
  DISABLED_PLUGINS_LINE="disabled_plugins = \[\"cri\"\]"

  # 检查配置文件是否存在
  if [[ ! -f "$CONFIG_FILE" ]]; then
      echo "Error: Configuration file '$CONFIG_FILE' does not exist."
      exit 1
  fi

  # 备份原始配置文件
  cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

  # 使用sed命令注释掉指定行
  sed -i 's/'"$DISABLED_PLUGINS_LINE"'/#'"$DISABLED_PLUGINS_LINE"'/' "$CONFIG_FILE"

  # 检查注释是否成功
  if grep -q "^#$DISABLED_PLUGINS_LINE" "$CONFIG_FILE"; then
      echo "Line '$DISABLED_PLUGINS_LINE' successfully commented out in $CONFIG_FILE."
  else
      echo "Error: Failed to comment out line '$DISABLED_PLUGINS_LINE' in $CONFIG_FILE."
      rm "$CONFIG_FILE"  # 撤销修改
      mv "$CONFIG_FILE.bak" "$CONFIG_FILE"  # 恢复备份
#      exit 1
  fi

  echo "cri-docker (containerd) service has been restarted."
}



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

function start_service() {
    systemctl daemon-reload
    systemctl enable cri-docker
    systemctl restart cri-docker
    systemctl is-active cri-docker
    systemctl status cri-docker
}

if [ -f /usr/bin/cri-dockerd ]; then
  echo "cri-dockerd已安装"
  cri-dockerd --version
else
  cdtgz_path=$(find . -name 'cri-dockerd*.tgz')
  if [ -f "$cdtgz_path" ]; then
    echo "cri-dockerd.tgz文件存在"
    download_cri_dockerd
    install_cri_dockerd
  else
    echo "cri-dockerd.tgz文件不存在"
    install_cri_dockerd
  fi
fi

echo "配置服务"

install_cri_dockerd_service
install_cri_dockerd_socket
rewrite_containerd_config
start_service