#!/usr/bin/env bash

#source $HOME/.bash_profile
if [ -e ./my_variables ] && [ -x ./my_variables ];then
	source ./my_variables
fi


# config for work_nodes only 
KUBEADM_JOIN="kubeadm join"

#printf "마스터노드에서 설정한 토큰값 입력 : "
#read TOCKEN

if [ ! -z $MY_KUBER_MNODE_TOKEN ]; then
	KUBEADM_JOIN=" --token ${MY_KUBER_MNODE_TOKEN}"
else
	echo -e "export MY_KUBER_MNODE_TOKEN 환경변수에 토큰값 설정안됨."
	KUBEADM_JOIN=" --token 123456.1234567890123456"
fi


printf "--discovery-token-unsafe-skip-ca-verification 값 입력 ($MY_KUBER_MNODE_IP:$MY_KUBER_API_SERVER_LISTEN_PORT): "
read DISCOVERY_TOKEN_UNSAFE_SKIP_CA_VERIFICATION

if [ ! -z $DISCOVERY_TOKEN_UNSAFE_SKIP_CA_VERIFICATION ];then
	KUBEADM_JOIN=" --discovery-token-unsafe-skip-ca-verification ${DISCOVERY_TOKEN_UNSAFE_SKIP_CA_VERIFICATION}" 
else
	KUBEADM_JOIN=" --discovery-token-unsafe-skip-ca-verification $MY_KUBER_MNODE_IP:$MY_KUBER_API_SERVER_LISTEN_PORT"
fi

/bin/bash -c "${KUBEADM_JOIN}"
 