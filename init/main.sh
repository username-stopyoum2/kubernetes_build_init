#!/bin/bash
# mkdir -p /mnt/hgfs/VMWareSharedFolder/shellScripts/devSecOps/container/kubernetes/build/init

#sudo su - root
#chmod 755 $PWD/*.sh

INIT_DIR=/mnt/hgfs/VMWareSharedFolder/shellScripts/devSecOps/container/kubernetes/build/init
cd $INIT_DIR

printf "kubernetes 를 설치하시겠습니까?( y | n ): "
read line
if [ $line = 'y' ] || [ $line = 'yes' ];then
    /bin/bash -c "$INIT_DIR/공식문서install_kubernetes.sh"
fi

printf "kubernetes 설정을 진행하시겠습니까?( y | n ): "
read line
if [ $line = 'y' ] || [ $line = 'yes' ];then
    /bin/bash -c "$INIT_DIR/config.sh"
fi

# 재부팅 후 실행 해야되므로 
# printf "node 설정 ( master | worker | 빈값일시 설정안함): "
# read line
# if [ $line = 'master' ]; then
#     /bin/bash -c "$INIT_DIR/set_master_node.sh";
# elif [ $line = 'worker' ]; then
#     /bin/bash -c "$INIT_DIR/set_worker_node.sh";
# fi
