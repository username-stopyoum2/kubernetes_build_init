#!/usr/bin/env bash

# swapoff -a to disable swapping
swapoff -a
# sed to comment the swap partition in /etc/fstab
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

# kubernetes repo

# baseurl 값 x86-64 부분 시간날 때 변경ㄱ 

if [ ! -e ./my_variables ]; then
	echo -e "#!/bin/bash" >> ./my_variables
	#chmod 3755 ./my_variables;
	echo -e "./my_variables 파일 생성됨. source ./my_variables; 로 사용 ㄱ"
	ls -l ./my_variables
fi



MY_KUBER_GPG_KEY="packages.cloud.google.com/yum/doc" # Due to shorten addr for key
#echo -e "export MY_KUBER_GPG_KEY=${MY_KUBER_GPG_KEY};#MY_KUBER_SET" >> $HOME/.bash_profile
echo -e "export MY_KUBER_GPG_KEY=${MY_KUBER_GPG_KEY};" >> ./my_variables

cat << EOF >> /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://${MY_KUBER_GPG_KEY}/yum-key.gpg https://${MY_KUBER_GPG_KEY}/rpm-package-key.gpg
EOF

echo -e "/etc/yum.repos.d/kubernetes.repo 레포지토리 생성됨."
cat /etc/yum.repos.d/kubernetes.repo



cat << EOF >> /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

echo -e "/etc/modules-load.d/k8s.conf 생성됨."
cat /etc/modules-load.d/k8s.conf

sudo modprobe overlay
sudo modprobe br_netfilter

# 재부팅하지 않고 sysctl 파라미터 적용하기
sudo sysctl --system


# Set SELinux in permissive mode (effectively disabling it)
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

echo -e "setenforce 0;\nsed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config\n"
echo -e "SELinux 설정됨. 정책설정되어있는것들 적용 안됨.\n상태확인 Current Mode: permissive 이고 Mode from config file: permissive 여야됨."
sestatus


# 필요한 sysctl 파라미터를 설정하면, 재부팅 후에도 값이 유지된다.
# RHEL/CentOS 7 have reported traffic issues being routed incorrectly due to iptables bypassed
cat << EOF >>  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
echo -e "/etc/sysctl.d/k8s.conf 에 설정된 내용 : "
cat /etc/sysctl.d/k8s.conf
modprobe br_netfilter

# local small dns & vagrant cannot parse and delivery shell code.






# 재부팅하지 않고 sysctl 파라미터 적용하기
sudo sysctl --system



MYIP=$(myip.sh)
echo -e "내 ip주소 확인 : $MYIP"

ETC_HOSTS=""

printf "마스터노드 ip주소 입력 ($MYIP) : " # 로컬pc 주소와 같아도 상관없음
read MASTER_NODE_IP

if [ ! -z "${MASTER_NODE_IP}" ];then
	ETC_HOSTS+="${MASTER_NODE_IP}"
#	echo -e "export MY_KUBER_MNODE_IP=$MASTER_NODE_IP;#MY_KUBER_SET" >> $HOME/.bash_profile

	echo -e "export MY_KUBER_MNODE_IP=$MASTER_NODE_IP;" >> ./my_variables


elif [ -z "${MASTER_NODE_IP}" ];then
	ETC_HOSTS+="$MYIP"
#	echo -e "export MY_KUBER_MNODE_IP=$MYIP;#MY_KUBER_SET" >> $HOME/.bash_profile
	echo -e "export MY_KUBER_MNODE_IP=$MYIP;" >> ./my_variables
fi

printf "마스터노드 호스트 이름 입력 (m-k8s): "
read MASTER_NODE_HOSTNAME

if [ ! -z $MASTER_NODE_HOSTNAME ];then
	ETC_HOSTS+=" ${MASTER_NODE_HOSTNAME}"
#	echo -e "export MY_KUBER_MNODE_HOSTNAME=$MASTER_NODE_HOSTNAME;#MY_KUBER_SET" >> $HOME/.bash_profile

	echo -e "export MY_KUBER_MNODE_HOSTNAME=$MASTER_NODE_HOSTNAME;" >> ./my_variables

elif [ -z "${MASTER_NODE_HOSTNAME}" ];then
	ETC_HOSTS+=" m-k8s"	
#	echo -e "export MY_KUBER_MNODE_HOSTNAME='m-k8s';#MY_KUBER_SET" >> $HOME/.bash_profile	
	echo -e "export MY_KUBER_MNODE_HOSTNAME='m-k8s';" >> ./my_variables

fi

echo "${ETC_HOSTS}" >> /etc/hosts
echo -e "/etc/hosts 설정된 내용 : "
# 고정ip로 바꿔서 가능
# 192.168.2.60 my.mnode master master.example.com 


# hostnamectl set-hostname 호스트이름설정; 각각의 노드에서 설정해줘야됨
# /etc/sysconfig/network-scripts/ifcfg-ens33 
#    IPADDR=각노드ip주소
# systemctl restart network
# ip addr
# ping 8.8.8.8
# nslookup www.google.com
# ping 다른노드.ip.주소
cat /etc/hosts

remove_install.sh nmap









printf "워커노드 생성할 개수 입력 (3) : " # 3티어 구축을 위해 
read WORKER_NODE_COUNT

if [ -z $WORKER_NODE_COUNT ];then
	WORKER_NODE_COUNT=3
fi


OCTET_3=$(my_network_manager.sh -g3o | jq '.OCTET_3' | sed -r 's/(^"|"$)//g')

ETC_HOSTS=""
for (( i=2; i<=$WORKER_NODE_COUNT + 1; i++  )); do 
	let NAME_COUNT=$i-1;

	printf "워커노드 ip주소 입력 ($OCTET_3${i}) : "
	read WORKER_NODE_IP
	if [ ! -z $WORKER_NODE_IP ];then
		ETC_HOSTS+=$WORKER_NODE_IP
#		echo -e "export MY_KUBER_WNODE_$NAME_COUNT_IP=$WORKER_NODE_IP;#MY_KUBER_SET" >> $HOME/.bash_profile
		echo -e "export MY_KUBER_WNODE_$NAME_COUNT_IP=$WORKER_NODE_IP;" >> ./my_variables

	elif [ -z $WORKER_NODE_IP ];then
		ETC_HOSTS+="$OCTET_3${i}"
#		echo -e "export MY_KUBER_WNODE_$NAME_COUNT_IP=$OCTET_3${i};#MY_KUBER_SET" >> $HOME/.bash_profile
		echo -e "export MY_KUBER_WNODE_$NAME_COUNT_IP=$WORKER_NODE_IP;" >> ./my_variables

	fi

	
	printf "워커노드 호스트 이름 입력 (w${NAME_COUNT}-k8s) : " # my_wnode_1 node1.example.com node1 다수 입력 가능
	read WORKER_NODE_HOSTNAME
	if [ ! -z $WORKER_NODE_HOSTNAME ];then
		ETC_HOSTS+=" ${WORKER_NODE_HOSTNAME}""\n"
#		echo -e "export MY_KUBER_WNODE_$NAME_COUNT_HOSTNAME=${WORKER_NODE_HOSTNAME};#MY_KUBER_SET" >> $HOME/.bash_profile
		echo -e "export MY_KUBER_WNODE_$NAME_COUNT_HOSTNAME=${WORKER_NODE_HOSTNAME};" >> ./my_variables

	elif [ -z $WORKER_NODE_HOSTNAME ];then
		ETC_HOSTS+=" w${NAME_COUNT}-k8s""\n"
#		echo -e "export MY_KUBER_WNODE_$NAME_COUNT_HOSTNAME=w${NAME_COUNT}-k8s;#MY_KUBER_SET" >> $HOME/.bash_profile
		echo -e "export MY_KUBER_WNODE_$NAME_COUNT_HOSTNAME=w${NAME_COUNT}-k8s;" >> ./my_variables

	fi

done

#source $HOME/.bash_profile # 다른파일 전부에서 매번 해줘야됨. ㅈ같음.
source ./my_variables


echo -e "${ETC_HOSTS}" >> /etc/hosts
# 고정ip주소로 설정해서 가능.
# 192.168.2.61 my.wnode.1 node1 node1.example.com 
# 192.168.2.62 my.wnode.2 node2 node2.example.com 
# 192.168.2.63 my.wnode.3 node3 node3.example.com
# 192.168.2.70 my.mini.kuber minikube minikube.example.com 
# 192.168.2.80 my.loadbalancer loadbalancer loadbalancer.example.com 

# ping my.wnode.1

echo -e "/etc/hosts 설정된 내용 : "
cat /etc/hosts




# config DNS  
cat << EOF >> /etc/resolv.conf
nameserver 1.1.1.1 #cloudflare DNS
nameserver 8.8.8.8 #Google DNS
nameserver 126.168.63.1 #kt?
EOF
echo -e "/etc/resolv.conf 에 설정된 내용 : "
cat /etc/resolv.conf

printf "설정 적용을 위해 재부팅을 하시겠습니까? ( y | n ) : "
read line

if [ $line = 'y' ] || [ $line = 'yes' ];then
	init 0
fi