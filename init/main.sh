#!/bin/bash
# mkdir -p /mnt/hgfs/VMWareSharedFolder/shellScripts/devSecOps/container/kubernetes/build/init

#sudo su - root
#chmod 755 $PWD/*.sh

if [ -e ./my_variables ];then
    echo -e "./my_variables 파일이 존재함. 파일내용을 비우시겠습니까? ( y | n ): "
    read line
    if [ $line == 'y' ] || [ $line == 'yes' ];then
        cat /dev/null > ./my_variables
    fi
fi


printf "kubernetes 를 설치하시겠습니까?( y | n ): "
read line
if [ $line = 'y' ] || [ $line = 'yes' ];then
    /bin/bash -c "./공식문서install_kubernetes.sh"
fi

printf "kubernetes 설정을 진행하시겠습니까?( y | n ): "
read line
if [ $line = 'y' ] || [ $line = 'yes' ];then
    /bin/bash -c "./config.sh"
fi

# 재부팅 후 실행 해야되므로 
# printf "node 설정 ( master | worker | 빈값일시 설정안함): "
# read line
# if [ $line = 'master' ]; then
#     /bin/bash -c "$INIT_DIR/set_master_node.sh";
# elif [ $line = 'worker' ]; then
#     /bin/bash -c "$INIT_DIR/set_worker_node.sh";
# fi
