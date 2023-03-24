#!/bin/sh

log_path=/tmp/startQnlApp.log
app_path=/oem/newland
plugin_path=${app_path}/plugin        #变量的取用${}
meg_path=${app_path}/meg
err_num=0

#设置时区
export TZ='Asia/Shanghai'               #export将变量变为环境变量，以便在其他子程序运行
export $(dbus-launch)
#读取rtc时间，并设置成系统时间
hwclock -s -u                           # -s 将硬件时钟同步到系统时钟; -utc 格林威治时间
#如果时间很小，则设置一个默认的时间。
[ $(date +%s) -lt 1672506000 ] && date -s "01:00:10 2023-01-01"     
                                        # date +%s 从 1970 年 1 月 1 日 00:00:00 UTC 到目前为止的秒数

function log_msg {
    msg="[`date '+ %F %T'` ]: $@"       # %F 日期，同%Y%m%d; %T 24小时制时间hh:mm:ss; $@: 『 "$1" "$2" "$3" "$4" 』
    echo $msg
    echo $msg >>${log_path}             # 数据流重导向，将变量$msg叠加在log_path后
}

function kill_process()
{
    pid=`pidof $1`                      # 检索$1进程的PID并赋给pid
    if [ "${pid}" != "" ]
    then
        log_msg "start kill $1 = ${pid}"
        #echo nle | sudo -S 
        kill -9 ${pid}                  # 砍掉线程pid
    else 
        log_msg "$1 not run"
    fi
}

function run_QmegAuth()
{
    echo 
    time=`cat /proc/uptime |awk '{print $1}'`                       # 将文件/proc/uptime中第一列的内容赋值给time
    log_msg "run_QmegAuth at ${time}s"
    kill_process "QmegAuth"
    [ ! -d /tmp/meg_auth ] && mkdir /tmp/meg_auth                   # -d 检验目录是否存在；这里的意思即：目录不存在则生成
    [ ! -f /tmp/meg_auth/err_code ] && touch /tmp/meg_auth/err_code # -f 检验文件是否存在
    export HASPUSER_PREFIX=${meg_path}/auth
    cd ${app_path}
    export QT_QPA_FB_DRM=1
    export set QT_QPA_PLATFORM=linuxfb:rotation=90
    export "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${app_path}/lib"
    chmod +x QmegAuth
    ./QmegAuth              # 可执行文件
    cd -
}

function pre_run_Qmeg()
{
    [ ! -d "/data/newland/tts/" ] && mkdir -p /data/newland/tts             # -p 递归创建
    [ ! -d "/data/newland/adv/" ] && mkdir -p /data/newland/adv
    [ ! -d "/data/newland/log/" ] && mkdir -p /data/newland/log
    [ ! -d "/data/newland/db/" ] && mkdir -p /data/newland/db
    [ ! -d "/data/newland/cfg/" ] && mkdir -p /data/newland/cfg
    [ ! -d "/data/newland/update/" ] && mkdir -p /data/newland/update
    [ ! -d "/data/newland/plugin/" ] && mkdir -p /data/newland/plugin
}

function pre_run_QmegApp()
{
    #########check netserver is run########
    cnt=0
    while true
    do
        time=`cat /proc/uptime |awk '{print $1}'`
        log_msg "pre_run_QmegApp enter at ${time}s" 
        netserverPid=`pidof netserver`
        log_msg "netserver:${Pid}" 

        sleep 0.5                                   #休眠
        if [ $cnt -gt 10 ]; then
            break
        fi
        if [ "$netserverPid" != "" ];then
            sleep 0.5
            time=`cat /proc/uptime |awk '{print $1}'`
            log_msg "pre_run_QmegApp exit at ${time}s ,cnt:${cnt}" 
            break
        fi
        cnt=$(($cnt+1))
    done
    #################
}

function run_QmegApp()
{
    echo 
    time=`cat /proc/uptime |awk '{print $1}'`
    log_msg "run_QmegApp at ${time}s"
    kill_process "QmegApp"
    
    #export QT_DEBUG_PLUGINS=1
    export QT_QPA_FB_DRM=1
    export set QT_QPA_PLATFORM=linuxfb:rotation=90
    export "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${app_path}/lib"
    export HASPUSER_PREFIX=${meg_path}/auth
    cd ${app_path}
    chmod +x QmegApp
    ./QmegApp &
    cd -
}

function run_monitor()
{
    echo 
    time=`cat /proc/uptime |awk '{print $1}'`
    log_msg "run_monitor at ${time}s"
    kill_process "monitor"
    cd ${app_path}/monitor
    chmod +x monitor
    ./monitor 1>&2 >/tmp/monitor.log &          # &后台执行；1>&2
    cd -
}

function run_plugin()
{
    echo 
    time=`cat /proc/uptime |awk '{print $1}'`
    log_msg "run_plugin.sh at ${time}s"
    if [ -f ${plugin_path}/run_plugin.sh ]; then
        cd ${plugin_path}
        chmod +x run_plugin.sh 
        ./run_plugin.sh start &
        cd -
    fi
}

#限制core-dump大小 1000K
ulimit -c 1000      #-c core 文件的最大值
pre_run_Qmeg
run_QmegAuth
run_plugin
pre_run_QmegApp

#monitor died process,and restart.
while true
do
    
    ########start app
    QmegAppPid=`pidof QmegApp`
    if [ "$QmegAppPid" == "" ];then
        err_num=$(($err_num+1))
        run_QmegApp
        QmegAppPid=`pidof QmegApp`
        log_msg "restart QmegAppPid:${QmegAppPid}"
    fi
    
    ########start monitor
    monitorPid=`pidof monitor`
    if [ "$monitorPid" == "" ];then
        #err_num=$(($err_num+1))
        run_monitor
        monitorPid=`pidof monitor`
        log_msg "restart monitorPid:${monitorPid}"
    fi
    
    if [ $err_num -gt 10 ]; then
        #出现错误，post 上报 警告
        #./curl -H "Content-Type: application/json" -X POST -d '{"queryId":"DD67437A2DED4C47A5810F1C621813","devCode": "newland"}' "http://127.0.0.1:8000/faceList" &
        sleep 10
        log_msg "error ${err_num} times,begin reboot！！"
        sleep 5
        reboot
    fi
    
    sleep 10
    
done
