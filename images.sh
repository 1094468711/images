#!/bin/bash
G=`tput setaf 2`
C=`tput setaf 6`
Y=`tput setaf 3`
Q=`tput sgr0`

#时间
imageNewTag=`date +%Y%m%d-%H%M%S`

#内网镜像仓库地址
#registryAddr="registry.cn-shanghai.aliyuncs.com/lihaozhy/docker"
#docker login $registryAddr
echo -e "${C}\n\n镜像下载脚本:${Q}"
echo -e "${C}images.sh将读取images.txt中的镜像，拉取并保存到images.tar.gz中\n\n${Q}"

read -p "是否从公网下载镜像，请输入 Yes 或 No: " choice

if [ "$choice" = "Yes" ]; then
#循环读取images.txt,并存入list中

  n=0 
  for line in $(cat images.txt | grep ^[^#])
  do
	list[$n]=$line
	((n+=1))
  done
 
  echo "需推送的镜像地址如下："
  for variable in ${list[@]}
  do
	echo ${variable}
  done

# 创建文件夹
  mkdir images
  rm -rf images/*
  rm -rf images.tar.gz

  for variable in ${list[@]}
  do
	#下载镜像
        echo "${C}start: 拉取保存镜像${Q}"
	echo "准备拉取镜像: $variable"
	docker pull $variable
        fileName=${variable//:/__}
	docker save $variable | gzip -c > ./images/$fileName.tar.gz 
  done

  # 打包镜像
  echo "${C}start: 打包镜像${Q}"
  tar -czvf images.tar.gz images
  rm -rf images
  echo -e "${C}end: 打包完成\n\n${Q}"

elif [ "$choice" = "No" ]; then
    echo "不执行下载镜像，继续执行下一步。"
else
    echo "输入无效，请输入 Yes 或 No。"
fi

echo -e "${C}\n\n镜像上传脚本:${Q}"
echo -e "${C}push_images.sh将读取images.txt中的镜像名称，将images.tar.gz中的镜像推送到内网镜像仓库\n\n${Q}"

read -p "是否执行上传镜像到镜像仓库,请输入 Yes 或 No: " choice
# 判断输入是否为 Yes 或 No
# 获取内网镜像仓库地址

if [ "$choice" = "Yes" ]; then

   read -p "${C}内网镜像仓库地址:${Q}" registryAddr

   echo "${C}镜像仓库登录${Q}"
   docker login $registryAddr

# 解压文件夹
   echo "${C}start: 解压镜像包${Q}"
   rm -rf images
   tar -zxvf images.tar.gz
   echo -e "${C}end: 解压完成\n\n${Q}"

# tag、push镜像
   echo "${C}start: 推送镜像${Q}"
   for push_image in $(cat images.txt | grep ^[^#])
   do
      echo -e "${Y}    开始推送$push_image...${Q}"
      fileName=${push_image//:/__}
      docker load --input ./images/$fileName.tar.gz
      # #获取拉取的镜像ID
      imageId=`docker images -q $push_image`
      docker tag $imageId $registryAddr$push_image
      docker push $registryAddr$push_image
   done
   echo -e "${C}end: 推送完成\n\n${Q}"

elif [ "$choice" = "No" ]; then
    echo "跳出操作,不执行上传镜像到镜像仓库。"
else
    echo "输入无效，请输入 Yes 或 No。"
fi


read -p "${C}是否清理本地镜像(Y/N,默认N)?:${Q}" is_clean
#清理镜像
if [ -z "${is_clean}" ];then
   is_clean="N"
fi
if [ "${is_clean}" == "Y" ];then
   echo "${C}start: 清理镜像${Q}"
   read -p "${C}内网镜像仓库地址:${Q}" registryAddr
   for rm_image in $(cat images.txt | grep ^[^#] | awk -F':' '{print $1}')
   do
     docker rmi -f  $registryAddr$rm_image
   done
   echo -e "${C}end: 清理完成\n\n${Q}"
fi

echo -e "${C}执行结束~\n\n${Q}"

docker logout $registryAddr
