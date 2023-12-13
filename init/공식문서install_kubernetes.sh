#!/bin/bash

# kubectl kubeadm kubelet 모두 설치함. 정상설치되는거 확인함. 명령어 테스트 아직임.
# https://kubernetes.io/ko/docs/setup/production-environment/tools/kubeadm/install-kubeadm/



IS_SHELLSCRIPTS=$(echo "$PATH" | grep -Ei 'shellScripts')

# conntrack-tools 는 Linux의 Connection Tracking System과 상호 작용할 수 있게 해주는 사용자 공간 도구 세트입니다1. 이 도구들은 시스템 관리자가 iptables에 대한 상태 유지 패킷 검사를 제공하는 모듈인 Connection Tracking System과 상호 작용할 수 있게 해줍니다1.
#  이 도구들은 또한 네트워크 주소 변환 (NAT) 설정에서 연결 추적을 검사하고 수정하는 데 사용될 수 있습니다3. 이 도구들은 방화벽의 성능과 안정성을 향상시키는 데 도움이 됩니다21.


# https://docs.docker.com/engine/install/centos/
# https://docs.docker.com/engine/install/ubuntu/



remove_install.sh yum-utils
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum -y update
if [ ! -z $IS_SHELLSCRIPTS ];then
	PACKAGES=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
	for PACKAGE in ${PACKAGES[*]};do
		remove_install.sh $PACKAGE 
	done
else
	echo -e "shellScripts 디렉이 PATH 변수에 할당되지않았음. 기본설치 진행"
	yum -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

systemctl start docker 
systemctl enable --now docker
systemctl status docker

sudo systemctl enable containerd.service

if [ ! -z $IS_SHELLSCRIPTS ];then
	PACKAGES=(epel-release vim-enhanced git conntrack-tools)
	for PACKAGE in ${PACKAGES[*]};do
		remove_install.sh $PACKAGE 
	done
else
	echo -e "shellScripts 디렉이 PATH 변수에 할당되지않았음. 기본설치 진행"

	yum -y install epel-release vim-enhanced git

fi

# NI 플러그인 설치(대부분의 파드 네트워크에 필요)
CNI_PLUGINS_VERSION="v1.1.1"
ARCH="amd64"
DEST="/opt/cni/bin"
sudo mkdir -p "$DEST"
curl -L "https://github.com/containernetworking/plugins/releases/download/${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-${CNI_PLUGINS_VERSION}.tgz" | sudo tar -C "$DEST" -xz


# Flatcar Container Linux를 실행 중인 경우, DOWNLOAD_DIR="/opt/bin" 을 설정한다.
DOWNLOAD_DIR="/usr/local/bin" # 명령어 파일을 다운로드할 디렉터리 정의. 쓰기 가능한 디렉터리로 설정되어야 한다. 
sudo mkdir -p "$DOWNLOAD_DIR"

# crictl 설치(kubeadm / Kubelet 컨테이너 런타임 인터페이스(CRI)에 필요)
CRICTL_VERSION="v1.25.0"
ARCH="amd64"
curl -L "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-${ARCH}.tar.gz" | sudo tar -C $DOWNLOAD_DIR -xz




# kubeadm, kubelet, kubectl 설치 및 kubelet systemd 서비스 추가
RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
ARCH="amd64"
cd $DOWNLOAD_DIR
sudo curl -L --remote-name-all https://dl.k8s.io/release/${RELEASE}/bin/linux/${ARCH}/{kubeadm,kubelet,kubectl}
sudo chmod +x {kubeadm,kubelet,kubectl}

RELEASE_VERSION="v0.4.0"
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service
sudo mkdir -p /etc/systemd/system/kubelet.service.d
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | sudo tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf


systemctl start kubelet && systemctl enable --now kubelet && systemctl status kubelet


# 참고: Flatcar Container Linux 배포판은 /usr 디렉터리를 읽기 전용 파일시스템으로 마운트한다. 
# 클러스터를 부트스트랩하기 전에, 쓰기 가능한 디렉터리를 구성하기 위한 추가 단계를 수행해야 한다. 
# 쓰기 가능한 디렉터리를 설정하는 방법을 알아 보려면 Kubeadm 문제 해결 가이드를 참고한다.







