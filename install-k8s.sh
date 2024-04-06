#!/bin/bash

cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=http://mirrors.cloud.aliyuncs.com/kubernetes-new/core/stable/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=http://mirrors.cloud.aliyuncs.com/kubernetes-new/core/stable/v1.28/rpm/repodata/repomd.xml.key
EOF

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo sysctl net.bridge.bridge-nf-call-iptables=1
echo 'net.bridge.bridge-nf-call-iptables = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl --system

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable kubelet.service

cat > /etc/docker/daemon.json << EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

systemctl daemon-reload
systemctl enable docker
systemctl enable kubelet

systemctl restart docker
systemctl status docker
systemctl restart kubelet
systemctl status kubelet

MASTER_IP=$(ip addr show eth0 | grep -oP 'inet \K[\d.]+')

kubeadm init \
--apiserver-advertise-address=$MASTER_IP \
--service-cidr=10.1.0.0/16 \
--kubernetes-version v1.28.2 \
--pod-network-cidr=10.244.0.0/16 \
--cri-socket unix:///var/run/cri-dockerd.sock \
--image-repository registry.aliyuncs.com/google_containers --v=10
