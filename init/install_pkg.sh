#!/usr/bin/env bash





# ./install_pkg.sh 버.전 Main 
# Main 은 마스터노드 아닐 시 생략 ㄱ

# 버.전은 책에서는 1.18.4지만 공식문서 업데이트는 최근 4개의 버전만 지원. 3개월마다 버전 한개씩 생성됨. 즉 1년에 최소1번은 업뎃해줘야됨.
# 최신버전 1.28




# install packages 
#yum install epel-release -y
#yum install vim-enhanced -y
#yum install git -y





echo "쿠버네티스 설치 버전 (1.18.4):"
read KUBERNETES_VERSION

if [ -z $KUBERNETES_VERSION ];then
	KUBERNETES_VERSION="1.18.4"
fi

# install kubernetes cluster 
yum install "kubectl-${KUBERNETES_VERSION}" "kubelet-${KUBERNETES_VERSION}" "kubeadm-${KUBERNETES_VERSION}" -y
systemctl enable --now kubelet




echo "현재 어떤 노드에서 설치중인지\n\t1.마스터노드\n\t2.워커노드\n(1): "
read MASTER_OR_WROKER_NODE

if [ -z $MASTER_OR_WROKER_NODE ];then
	MASTER_OR_WROKER_NODE="1"
fi

if [ $MASTER_OR_WROKER_NODE -eq "1" ];then
	git clone https://github.com/sysnet4admin/_Book_k8sInfra.git
	mv /home/vagrant/_Book_k8sInfra $HOME
	find $HOME/_Book_k8sInfra/ -regex ".*\.\(sh\)" -exec chmod 700 {} \;
fi

