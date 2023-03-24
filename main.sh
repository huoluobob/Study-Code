#!/bin/bash
target_path=/var/fs_disk/newland/run
log_path=/var/fs_disk/newland/log
err_num=0

function log_msg {
    msg="[`date '+ %F %T'` ]: $@"
    echo $msg                                   # 终端显示
    echo $msg >>${log_path}/main.log            # 文件再存一遍
}

function kill_process()
{
    pid=`pidof $1`
    if [ "${pid}" != "" ]
    then
        log_msg "start kill $1 = ${pid}"        # [ 2023-03-26 08:56:20 ]: start kill ... = ...
        #echo nle | sudo -S 
        kill -9 ${pid}
    else 
        log_msg "$1 not run"
    fi
}

function run_nl_face()
{
    echo 
    time=`cat /proc/uptime |awk '{print $1}'`
    log_msg "run_nl_face at ${time}s"
    kill_process "NLFace"
    cd ${target_path}
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${PWD}/lib/"
    chmod +x NLFace
    ./NLFace $1 &
    cd -
}

function run_monitor()
{
    echo 
    time=`cat /proc/uptime |awk '{print $1}'`
    log_msg "run_monitor at ${time}s"
    kill_process "monitor"
    cd ${target_path}
    chmod +x monitor
    ./monitor $1 1>&2 >/tmp/monitor.log &
    cd -
}

function run_timing_task()
{
    #每天固定 00:03或者00:04重启
    reboot_time=`date +%H:%M`               # 就是当前时间e.g: 09:10 (24小时制)
    if [ "${reboot_time}" == "00:03" ]||[ "${reboot_time}" == "00:04" ];then
        log_msg "reboot time ${reboot_time}"
        #查找14天前的人脸文件夹/log，并删除。只保留14天内的face文件夹/log。
        cd ${log_path} && find . -type f -mtime +14 |xargs rm -rf               # -type f 指普通文档，如果是目录则为 -type d
                                                                                # xargs 将stdout转化成命令参数作为stdin       
        sleep 5
        #echo nle | sudo -S 
        reboot                              # 重启系统
    fi
}

################################################################################
log_msg " "
log_msg "----------------------------------------------------------------------"
log_msg " "
mkdir -p ${log_path}
#0.get sn
sn=`grep "DEVICE_SERIAL_NUMBER" /proc/env |awk -F"[:]" '{print$2}' |sed 's/\r$//' `     # -F"[:]" 以：为分隔符   sed 's/\r$//' 将\r$用 取代（删除）
log_msg "sn:[${sn}]"

sleep 2
#1.run nlface
run_nl_face $sn

#2.run monitor
run_monitor $sn

#3.monitor died process,and restart.
sleep 1
while true
do
    
    NLFacePid=`pidof NLFace`
    if [ "$NLFacePid" == "" ];then
        err_num=$(($err_num+1))
        log_msg "restart ${NLFacePid}"
        run_nl_face $sn
    fi
    
    ########start monitor
    monitorPid=`pidof monitor`
    if [ "$monitorPid" == "" ];then
        run_monitor $sn
        monitorPid=`pidof monitor`
        log_msg "restart monitorPid:${monitorPid}"
    fi
    
    if [ $err_num -gt 10 ]; then
        sleep 10
        log_msg "error ${err_num} times,begin reboot！！"
        sleep 5
        #echo nle | sudo -S 
        reboot
    else
        remote_ctrlPid=`pidof remote_ctrl`
        echo 
        log_msg "NLFace pid:[${NLFacePid}]"
        log_msg "monitor pid:[${monitorPid}]"
        log_msg "remote_ctrl pid:[${remote_ctrlPid}]"
    fi
    #每天固定 00:03或者00:04重启
    run_timing_task
    sleep 55
    
done
