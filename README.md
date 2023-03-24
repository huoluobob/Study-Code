# Study-Code
### Summary:
Here are some of the codes I read and learned during my internship. The comments included in the code are personal notes in Chinese.
## startQnlApp.sh
#### study time: 2023/3/23
#### study note:
- **export** changes the variable to an environment variable to run in other subroutines
- **hwclock** -s Synchronize the hardware clock to the system clock; -utc GMT(Greenwich mean time)
- **pidof** Retrieve the pid of the process
- **kill** kill the process
- **[ ! -d /tmp/meg_auth ]** When the directory do not exit, it will sucesseed
## main.sh
#### study time: 2023/3/23
#### study note:
- **xargs** Convert stdout to a command parameter as stdin
## reboot_icntv.sh
#### Code Introduction: 
This is the reboot code of app, whose functions include the record of startup times, startup time detection and network timeout anomaly detection.
#### study time: 2023/3/24
#### study note:
- **logcat** -v format; -f [filename] Save the information to a file
- **busybox** is like a big toolbox. It integrates many Linux tools and commands, including the Linux system's own shell.
## loader.sh
#### Code Introduction: 
This is an upgrade file and contains the following steps:
- unzip update file
- move it into work path
- Resoft connect the new version
- delete the file to avoid updating next time
#### study time: 2023/3/24
#### study note:
- **[ -e ${update_path}/${update_name}.zip ]**  When exit, sucesseed
- **$?** The value returned by the previous instruction is 0 on success and 1 on failure
- **md5sum** Calculate and verify the MD5 checksum. MD5 Message digest algorithm, a widely used password hash function, 
can produce a 128-bit (16-byte) hash value, used to ensure complete and consistent transmission of information. 
**Is used to verify file consistency**
