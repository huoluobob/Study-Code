#!/system/bin/sh

let max_reboot_count=$1
let reboot_count=0
let time_out_count=0

rm /data/temp.txt
logcat -v time -f /data/temp.txt &                      # -v 设置输出格式; -f [filename] 将信息保存到文件中 

#1.记录开机次数，超过max_reboot_count 则退出测试。
date >>/data/rcount.txt
reboot_count=`cat /data/rcount.txt |busybox wc -l`      # busybox的wc
echo "     ">>/data/shlog_reboot_icntv.txt
echo "     --->${reboot_count}    ">>/data/shlog_reboot_icntv.txt
echo "     ">>/data/shlog_reboot_icntv.txt
date >>/data/shlog_reboot_icntv.txt
echo "reboot_count: ${reboot_count},max_reboot_count: ${max_reboot_count}." >>/data/shlog_reboot_icntv.txt
echo "reboot_count: ${reboot_count},max_reboot_count: ${max_reboot_count}."

if [ $reboot_count -gt $max_reboot_count ]; then
    echo "exit ${reboot_count} > ${max_reboot_count}">>/data/shlog_reboot_icntv.txt
    echo "exit ${reboot_count} > ${max_reboot_count}"
    exit 0
fi

while true
do
#2.查找是否进入lunch的关键字符串
    start_lunch_str=`cat /data/temp.txt  |grep "create UserData end" |busybox wc -l`            #busybox
    echo "start_lunch_str : ${start_lunch_str},time_out_count : ${time_out_count}." >>/data/shlog_reboot_icntv.txt
    echo "start_lunch_str : ${start_lunch_str},time_out_count : ${time_out_count}." 
#3.找到lunch的关键字符串,并打印进入的lunch的时间（从开机到启动lunch）。
    if [ "$start_lunch_str" == '1' ]; then
        start_lunch_time=`cat /proc/uptime |busybox awk '{printf("%d",$1)}'`
        echo "start_lunch_time: ${start_lunch_time}." >>/data/shlog_reboot_icntv.txt
        echo "start_lunch_time: ${start_lunch_time}."

        ###3.1.如果启动lunch超过30s，则说明有异常，停止并生成logcat_error.txt,否则20s后重启
        if [ $start_lunch_time -gt 30 ]; then
            cp /data/temp.txt /data/logcat_error.txt
            dmesg >/data/dmesg.txt
            echo "启动lunch异常 start lunch time > 30s!!!!" >>/data/shlog_reboot_icntv.txt
            echo "启动lunch异常 start lunch time > 30s!!!!"
            break;
        else
            echo "start lunch time normoal!,after 20s reboot" >>/data/shlog_reboot_icntv.txt
            echo "start lunch time normoal!,after 20s reboot"
            sleep 20
            reboot
        fi

    fi
#4.如果网络异常会超时60s，停止并生成logcat_time_out.txt
    if [ $time_out_count -gt 60 ]; then
        cp /data/temp.txt /data/logcat_time_out.txt
        echo "网络异常会超时60s time out!!!!" >>/data/shlog_reboot_icntv.txt
        echo "网络异常会超时60s time out!!!!"
        break;
    fi

    sleep 1
    time_out_count=$(($time_out_count+1))
    
done
