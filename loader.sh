#!/bin/bash
#升级包注意：
#1.打包的时候不包含文件夹。
#2.一定要包含version
#
update_name=update
update_path=/var/fs_disk/newland/update
target_path=/var/fs_disk/newland
log_path=/var/fs_disk/newland/log

function log_msg {
    msg="[`date '+ %F %T'` ]: $@"
    echo $msg
    echo $msg >>${log_path}/loader.log
}

log_msg " "
log_msg "----------------------------------------------------------------------"
log_msg " "
mkdir -p ${log_path}

if [ "$1" != "" ];then
    update_name=$1
fi

#如果升级文件存在，则进行解压、移动、重新软连接的动作
if [ -e ${update_path}/${update_name}.zip ]&&[ -e ${update_path}/md5.txt ];then     # -e 检验文件是否存在
    #0.验证md5sum
    md5=`cat ${update_path}/md5.txt`
    calc_md5=`md5sum ${update_path}/${update_name}.zip |awk '{print $1}'`
    if [ "${md5}" == "${calc_md5}" ];then
        log_msg "0.md5:${md5} == calc_md5:${calc_md5}"
        [[ -d ${update_path}/tmp ]] && rm -rf ${update_path}/tmp
        #1.解压update.zip
        log_msg "1.unzip ${update_name}.zip"
        cd ${update_path}
        ${target_path}/unzip ${update_name}.zip -d tmp              # -d 解压缩后存在该目录下
        if [ $? == 0 ];then                 # 上一个指令的返回值，成功返0，失败返1
            #2.移动到工作路径
            dirname=`cat tmp/version`
            #version 不存在或者该目录已经存在则dirname设置成时间命名。
            if [ "$dirname" == "" ]||[ -e ${target_path}/${dirname} ];then
                dirname=v`date +%F-%H%M%S`
            fi
            log_msg "2.mv tmp -> ${target_path}/${dirname}"
            mv tmp ${target_path}/${dirname}
            
            #3.重新软连接新版本
            log_msg "3.ln -s ${target_path}/${dirname} ${target_path}/run"
            [[ -e ${target_path}/run ]] && rm ${target_path}/run
            ln -s ${target_path}/${dirname} ${target_path}/run      # -s 建立软链接
            sync                           # 数据同步
            #echo  ${dirname} >${target_path}/run_version
            log_msg "update success!!"
        else
            log_msg "unzip ${update_name}.zip error!!"
        fi
    else
        log_msg "md5:${md5} != calc_md5:${calc_md5}"
    fi
    #4.不管升级成功与否，删除文件，防止下次继续升级
    rm ${update_path}/${update_name}.zip
    rm ${update_path}/md5.txt
else
    log_msg "${update_name}.zip or ${update_path}/md5.txt  not exist!!"
fi
