#!/usr/bin/env bash

# kubeadm init --token 123456.1234567890123456 --token-ttl 0 --pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.1.10
#echo -e "export MY_KUBER_API_SERVER_LISTEN_PORT=6443;#MY_KUBER_SET" >> $HOME/.bash_profile
echo -e "export MY_KUBER_API_SERVER_LISTEN_PORT=6443;" >> ./my_variables

#echo -e "export MY_KUBER_KUBERLET_PORT=10250;#MY_KUBER_SET" >> $HOME/.bash_profile
echo -e "export MY_KUBER_KUBERLET_PORT=10250;" >> ./my_variables

#source $HOME/.bash_profile

source ./my_variables


# 나중에 iptables 로 바꿀것
firewall-cmd --add-port="$MY_KUBER_API_SERVER_LISTEN_PORT/tcp" --permanent && firewall-cmd --add-port="$MY_KUBER_KUBERLET_PORT/tcp" --permanent
firewall-cmd --reload
firewall-cmd --list-ports
systemctl status firewalld
echo -e "필수 포트 확인 : nc 127.0.0.1 6443 로 통신이 되야됨."
echo -e "MAC 주소 및 product_uuid가 모든 노드에 대해 고유한지 확인 : ip link; cat /sys/class/dmi/id/product_uuid; 으로 비교 후 중복되면 안됨."

printf "2 GB 이상의 램을 장착한 머신.\n2 이상의 CPU.\n클러스터의 모든 머신에 걸친 전체 네트워크 연결.\n모든 노드에 대해 고유한 호스트 이름, MAC 주소 및 product_uuid.\n컴퓨터의 특정 포트들 개방.\n스왑의 비활성화.\n 모두 설정이 되었습니까? ( y | n ):"
echo -e "https://kubernetes.io/ko/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#verify-mac-address 에서 "


read line

if [ $line = 'y' ] || [ $line = 'yes' ];then
	KUBEADM_INIT="kubeadm init"

	printf "토큰값 입력 (123456.1234567890123456):"
	read TOCKEN
	if [ ! -z $TOCKEN ];then
		KUBEADM_INIT+=" --token ${TOCKEN}" 
#		echo -e "export MY_KUBER_MNODE_TOKEN=$TOKEN;#MY_KUBER_SET" >> $HOME/.bash_profile

		echo -e "export MY_KUBER_MNODE_TOKEN=$TOKEN;" >> ./my_variables


	elif [ -z $TOCKEN ];then
		KUBEADM_INIT+=" --token 123456.1234567890123456"
		#echo -e "export MY_KUBER_MNODE_TOKEN='123456.1234567890123456';#MY_KUBER_SET" >> $HOME/.bash_profile

		echo -e "export MY_KUBER_MNODE_TOKEN='123456.1234567890123456';" >> ./my_variables


	fi


	printf "토큰 ttl 입력 (0): "
	read TOCKEN_TTL
	if [ ! -z $TOCKEN_TTL ];then
		KUBEADM_INIT+=" --token-ttl ${TOCKEN_TTL}" 
		
	elif [ -z $TOCKEN_TTL ];then
		KUBEADM_INIT+=" --token-ttl 0" 
	fi

	NETWORK_BAND=$(my_network_manager.sh -gnb | jq '.NETWORK_BAND' | sed -r 's/(^"|"$)//g')
	PREFIX=$(my_network_manager.sh -gp | jq '.PREFIX' | sed -r 's/(^"|"$)//g')
	printf "pod-network-cidr 값 입력 ($NETWORK_BAND/$PREFIX) : " # 노드 모두에 적용됨. 파드간 통신때 쓰임.
	read POD_NETWORK_CIDR
	if [ ! -z $POD_NETWORK_CIDR ];then
		KUBEADM_INIT+=" --pod-network-cidr=${POD_NETWORK_CIDR}" 
#		echo -e "export MY_KUBER_POD_NETWORK_CIDR=${POD_NETWORK_CIDR};#MY_KUBER_SET" >> $HOME/.bash_profile
		echo -e "export MY_KUBER_POD_NETWORK_CIDR=${POD_NETWORK_CIDR};" >> ./my_variables


	elif [ -z $POD_NETWORK_CIDR ];then
		KUBEADM_INIT+=" --pod-network-cidr=$NETWORK_BAND/$PREFIX" 
#		echo -e "export MY_KUBER_POD_NETWORK_CIDR=$NETWORK_BAND/$PREFIX;#MY_KUBER_SET" >> $HOME/.bash_profile
		echo -e "export MY_KUBER_POD_NETWORK_CIDR=$NETWORK_BAND/$PREFIX;" >> ./my_variables
	fi

	printf "apiserver-advertise-address 값 입력 ($MY_KUBER_MNODE_IP): " # 마스터노드IP와 같아도 됨.
	read APISERVER_ADVERTISE_ADDRESS 
	if [ ! -z $APISERVER_ADVERTISE_ADDRESS ];then
		KUBEADM_INIT+=" --apiserver-advertise-address=${APISERVER_ADVERTISE_ADDRESS}" 
		
	elif [ -z $APISERVER_ADVERTISE_ADDRESS ];then
		KUBEADM_INIT+=" --apiserver-advertise-address=$MY_KUBER_MNODE_IP" 
	fi

	echo -e "${KUBEADM_INIT}"
	/bin/bash -c "${KUBEADM_INIT}"



	# config for master node only 


	ADMIN_CONFIG=""
	printf "/etc/kubernetes/admin.conf 복사될 파일 ($HOME/.kube/config): "
	read ADMIN_CONFIG_COPY_FILE
	if [ ! -z $ADMIN_CONFIG_COPY_FILE ];then
		DIRS_FILE=($(echo "$ADMIN_CONFIG_COPY_FILE" | tr '/' ' '))
		DIRS="/"
		for (( i=0; i < ${#DIRS_FILE[*]} - 1 ; i++ ));do  
			DIRS="$DIRS""${DIRS_FILE[$i]}""/";  
		done

		if [ ! -e $DIRS ];then
			mkdir -p "${DIRS}"
		fi
		
		cp -i /etc/kubernetes/admin.conf $ADMIN_CONFIG_COPY_FILE
		chown $(id -u):$(id -g) $ADMIN_CONFIG_COPY_FILE
		echo -e "파일 복사 및 권한할당됨 : "
		ls -l $ADMIN_CONFIG_COPY_FILE
	else
		mkdir -p $HOME/.kube
		cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
		chown $(id -u):$(id -g) $HOME/.kube/config
		echo -e "파일 복사 및 권한할당됨 : "
		ls -l $HOME/.kube/config
	fi



	# config for kubernetes's network 


	kubectl apply -f ./172.16_net_calico.yaml
	#kubectl apply -f https://raw.githubusercontent.com/sysnet4admin/IaC/master/manifests/172.16_net_calico.yaml



	# ssh root@호.도 명령어; 할 때 비번 입력 안해도 됨.
	echo -e "ssh-keygen 실행시킴. 기본 엔터 3번 입력 ㄱ"
	ssh-keygen
	NODES_HOSTNAME=(my.wnode.1 my.wnode.2 my.wnode.3 my.mini.kuber my.loadbalancer)
	for HOSTNAME in ${NODES_HOSTNAME[*]};do
		ssh-copy-id $HOSTNAME; # yes 입력;password 입력; 
		ssh root@$HOSTNAME 'ip addr;hostname;'; # 정상적으로 호.도 가 출력되는지 확인 ㄱ
	done
else
	echo -e "설정 후 다시 실행해주세요."
fi



