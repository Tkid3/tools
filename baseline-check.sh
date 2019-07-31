#!/bin/bash 
#vesion 1.0
#author by Tkid3

time=`date  +'%Y-%m-%d'`
ipadd=`ip a | grep /24  |awk {'print $2'}|sed 's/\/24//'`
Result=/tmp/${ipadd}_${time}_checkResult.txt
cat <<EOF
*************************************************************************************
*****               
 ___   __   ___  ___  __    __  _  _  ___     __  _  _  ___   __  _ _  
(  ,) (  ) / __)(  _)(  )  (  )( \( )(  _)   / _)( )( )(  _) / _)( ) ) 
 ) ,\ /__\ \__ \ ) _) )(__  )(  )  (  ) _)  ( (_  )__(  ) _)( (_  )  \ 
(___/(_)(_)(___/(___)(____)(__)(_)\_)(___)   \__)(_)(_)(___) \__)(_)\_)

*****               linux基线检查脚本
*****               Author(Tkid3)
*****        
*****               输出结果： ${Result}             
*************************************************************************************
EOF

echo "IP: ${ipadd}" >> ${Result}

user_id=`whoami`
echo "当前扫描用户：${user_id}" >> ${Result}

scanner_time=`date '+%Y-%m-%d %H:%M:%S'`
echo "当前扫描时间：${scanner_time}" >> ${Result}

uname=`uname -a`
echo "系统版本情况${uname}" >> ${Result}

echo "1.账号策略检查中..."
echo "***************************"

#项目：帐号与口令-用户口令设置
#合格：Y;不合格：N


passmax=`cat /etc/login.defs | grep PASS_MAX_DAYS | grep -v ^# | awk '{print $2}'`
passmin=`cat /etc/login.defs | grep PASS_MIN_DAYS | grep -v ^# | awk '{print $2}'`
passlen=`cat /etc/login.defs | grep PASS_MIN_LEN | grep -v ^# | awk '{print $2}'`
passage=`cat /etc/login.defs | grep PASS_WARN_AGE | grep -v ^# | awk '{print $2}'`

echo "1.账号策略检查:" >> ${Result}
if [ $passmax -le 90 -a $passmax -gt 0 ];then
  echo "Y:口令生存周期为${passmax}天，符合要求" >> ${Result}
else
  echo "N:口令生存周期为${passmax}天，不符合要求,建议设置不大于90天" >> ${Result}
fi

if [ $passmin -ge 6 ];then
  echo "Y:口令更改最小时间间隔为${passmin}天，符合要求" >> ${Result}
else
  echo "N:口令更改最小时间间隔为${passmin}天，不符合要求，建议设置大于等于6天" >> ${Result}
fi

if [ $passlen -ge 8 ];then
  echo "Y:口令最小长度为${passlen},符合要求" >> ${Result}
else
  echo "N:口令最小长度为${passlen},不符合要求，建议设置最小长度大于等于8" >> ${Result}
fi

if [ $passage -ge 30 -a $passage -lt $passmax ];then
  echo "Y:口令过期警告时间天数为${passage},符合要求" >> ${Result}
else
  echo "N:口令过期警告时间天数为${passage},不符合要求，建议设置大于等于30并小于口令生存周期" >> ${Result}
fi

echo "2.账号是否会主动注销检查中..."
echo "***************************"
checkTimeout=$(cat /etc/profile | grep TMOUT | awk -F[=] '{print $2}')
if [ $? -ne 0 ];then
  TMOUT=`cat /etc/profile | grep TMOUT | awk -F[=] '{print $2}'`
  if [ $TMOUT -le 600 -a $TMOUT -ge 10 ];then
    echo "Y:账号超时时间${TMOUT}秒,符合要求" >> ${Result}
  else
    echo "N:账号超时时间${TMOUT}秒,不符合要求，建议设置小于600秒" >> ${Result}
  fi
else
  echo "N:账号超时不存在自动注销,不符合要求，建议设置小于600秒" >> ${Result}
fi


#项目：帐号与口令-root用户远程登录限制
#合格：Y;不合格：N


echo "3.ssh配置检查中..."
echo "***************************"

echo "2.ssh配置检查:" >> ${Result}
remoteLogin=$(cat /etc/ssh/sshd_config | grep -v ^# |grep "PermitRootLogin no")
if [ $? -eq 0 ];then
  echo "Y:已经设置远程root不能登陆，符合要求" >> ${Result}
else
  echo "N:已经设置远程root能登陆，不符合要求，建议/etc/ssh/sshd_config添加PermitRootLogin no" >> ${Result}
fi

alivetime=`cat /etc/ssh/sshd_config | grep -v ^# | grep ClientAliveInterval`
if [ $? -eq 0 ];then
  echo "Y:已经设置闲置会话自动断开，符合要求" >> ${Result}
else
  echo "N:未设置客户端闲置会话自动断开，不符合要求，建议/etc/ssh/sshd_config添加ClientAliveInterval 600" >> ${Result}
fi

alivecountMax=`cat /etc/ssh/sshd_config | grep -v ^# | grep ClientAliveCountMax`
if [ $? -eq 0 ];then
  echo "Y:已经设置最大连接数，符合要求" >> ${Result}
else
  echo "N:未设置最大连接数，不符合要求，建议/etc/ssh/sshd_config添加ClientAliveCountMax 3" >> ${Result}
fi

#项目：帐号与口令-检查是否存在除root之外UID为0的用户
#合格：Y;不合格：N

#查找非root账号UID为0的账号

echo "4.是否存在除root之外UID为0的用户..."
echo "***************************"

echo "3.是否存在除root之外UID为0的用户:" >> ${Result}
UIDS=`awk -F[:] 'NR!=1{print $3}' /etc/passwd`
flag=0
for i in $UIDS
do
  if [ $i = 0 ];then
    echo "N:存在非root账号的账号UID为0，不符合要求" >> ${Result}
  else
    flag=1
  fi
done
if [ $flag = 1 ];then
  echo "Y:不存在非root账号的账号UID为0，符合要求" >> ${Result}
fi

#项目：帐号与口令-检查telnet服务是否开启
#合格：Y;不合格：N

#检查telnet是否开启

echo "5.检查telnet服务是否开启..."
echo "***************************"

echo "4.检查telnet服务是否开启:" >> ${Result}
telnetd=`ps -ef|grep telnet|grep -v grep`
if [ $telnetd  ]; then
  echo "N:检测到telnet服务开启，不符合要求，建议关闭telnet" >> ${Result}
else
  echo "Y:检测到telnet服务未开启，符合要求" >> ${Result}
fi

#项目：帐号与口令-root用户环境变量的安全性
#合格：Y;不合格：N

#检查目录权限是否为777

echo "6.root用户环境变量的安全性..."
echo "***************************"

echo "5.root用户环境变量的安全性:" >> ${Result}
dirPri=$(find $(echo $PATH | tr ':' ' ') -type d \( -perm -0777 \) 2> /dev/null)
if [  -z "$dirPri" ] 
then
  echo "Y:目录权限无777的,符合要求" >> ${Result}
else
  echo "N:文件${dirPri}目录权限为777的，不符合要求。" >> ${Result}
fi

#项目：帐号与口令-远程连接的安全性配置
#合格：Y;不合格：N

echo "7.远程连接的安全性配置..."
echo "***************************"

echo "6.远程连接的安全性配置:" >> ${Result}
fileNetrc=`find / -xdev -mount -name .netrc -print 2> /dev/null`
if [  -z "${fileNetrc}" ];then
 echo "Y:不存在.netrc文件，符合要求" >> ${Result}
else
  echo "N:存在.netrc文件，不符合要求" >> ${Result}
fi
 fileRhosts=`find / -xdev -mount -name .rhosts -print 2> /dev/null`
if [ -z "$fileRhosts" ];then
   echo "Y:不存在.rhosts文件，符合要求" >> ${Result}
else
   echo "N:存在.rhosts文件，不符合要求" >> ${Result}
fi

#项目：帐号与口令-用户的umask安全配置
#合格：Y;不合格：N

#检查umask设置

echo "8.用户的umask安全配置..."
echo "***************************"

echo "7.用户的umask安全配置:" >> ${Result}

umask1=`cat /etc/profile | grep umask | grep -v ^# | awk '{print $2}'`
umask2=`cat /etc/csh.cshrc | grep umask | grep -v ^# | awk '{print $2}'`
umask3=`cat /etc/bashrc | grep umask | grep -v ^# | awk 'NR!=1{print $2}'`
flags=0
for i in $umask1
do
  if [ $i != "027" ];then
    echo "N:/etc/profile文件中所所设置的umask为${i},不符合要求，建议设置为027" >> ${Result}
    flags=1
    break
  fi
done
if [ $flags == 0 ];then
  echo "Y:/etc/profile文件中所设置的umask为${i},符合要求" >> ${Result}
fi 
flags=0
for i in $umask2
do
  if [ $i != "027" ];then
    echo "N:/etc/csh.cshrc文件中所所设置的umask为${i},不符合要求，建议设置为027" >> ${Result}
    flags=1
    break
  fi
done  
if [ $flags == 0 ];then
  echo "Y:/etc/csh.cshrc文件中所设置的umask为${i},符合要求" >> ${Result}
fi
flags=0
for i in $umask3
do
  if [ $i != "027" ];then
    echo "N:/etc/bashrc文件中所设置的umask为${i},不符合要求，建议设置为027" >> ${Result}
    flags=1
    break
  fi
done
if [ $flags == 0 ];then
  echo "Y:/etc/bashrc文件中所设置的umask为${i},符合要求" >> ${Result}
fi

#项目：文件系统-重要目录和文件的权限设置
#合格：Y;不合格：N

echo "8.重要目录和文件的权限设置:" >> ${Result}
echo "9.检查重要文件权限中..."
echo "***************************"
file1=`ls -l /etc/passwd | awk '{print $1}'`
file2=`ls -l /etc/shadow | awk '{print $1}'`
file3=`ls -l /etc/group | awk '{print $1}'`
file4=`ls -l /etc/securetty | awk '{print $1}'`
file5=`ls -l /etc/services | awk '{print $1}'`

#检测文件权限为400的文件
if [ $file2 = "-r--------" ];then
  echo "Y:/etc/shadow文件权限为400，符合要求" >> ${Result}
else
  echo "N:/etc/shadow文件权限不为400，不符合要求，建议设置权限为400" >> ${Result}
fi

#检测文件权限为600的文件
if [ $file4 = "-rw-------" ];then
  echo "Y:/etc/security文件权限为600，符合要求" >> ${Result}
else
  echo "N:/etc/security文件权限不为600，不符合要求，建议设置权限为600" >> ${Result}
fi

#检测文件权限为644的文件
if [ $file1 = "-rw-r--r--" ];then
  echo "Y:/etc/passwd文件权限为644，符合要求" >> ${Result}
else
  echo "N:/etc/passwd文件权限不为644，不符合要求，建议设置权限为644" >> ${Result}
fi
if [ $file5 = "-rw-r--r--" ];then
  echo "Y:/etc/services文件权限为644，符合要求" >> ${Result}
else
  echo "N:/etc/services文件权限不为644，不符合要求，建议设置权限为644" >> ${Result}
fi
if [ $file3 = "-rw-r--r--" ];then
  echo "Y:/etc/group文件权限为644，符合要求" >> ${Result}
else
  echo "N:/etc/group文件权限不为644，不符合要求，建议设置权限为644" >> ${Result}
fi

#项目：文件系统-查找未授权的SUID/SGID文件
#合格：Y;不合格：N

echo "10.查找未授权的SUID/SGID文件中..."
echo "***************************"

echo "9.查找未授权的SUID/SGID文件:" >> ${Result}
unauthorizedfile=`find / \( -perm -04000 -o -perm -02000 \) -type f 2>/dev/null`
echo "C:文件${unauthorizedfile}设置了SUID/SGID，请检查是否授权" >> ${Result}

#项目：文件系统-检查任何人都有写权限的目录
#合格：Y;不合格：N;检查：C

echo "11.检查任何人都有写权限的目录中..."
echo "***************************"

echo "10.检查任何人都有写权限的目录:" >> ${Result}
checkWriteDre=$(find / -xdev -mount -type d \( -perm -0002 -a ! -perm -1000 \) 2> /dev/null)
if [  -z "${checkWriteDre}" ];then
  echo "Y:不存在任何人都有写权限的目录，符合要求" >> ${Result}
else
  echo "N:${checkWriteDre}目录任何人都可以写，不符合要求" >> ${Result}
fi
  
#项目：文件系统-检查任何人都有写权限的文件
#合格：Y;不合格：N;检查：C

echo "12.检查任何人都有写权限的文件..."
echo "***************************"

echo "11.检查任何人都有写权限的文件:" >> ${Result}
checkWriteFile=$(find / -xdev -mount -type f \( -perm -0002 -a ! -perm -1000 \) 2> /dev/null)
if [  -z "${checkWriteFile}" ];then
  echo "Y:不存在任何人都有写权限的文件，符合要求" >> ${Result}
else
  echo "N:${checkWriteFile}文件任何人都可以写，不符合要求" >> ${Result}
fi  

#项目：文件系统-检查异常隐含文件
#合格：Y;不合格：N;检查：C

echo "13.检查异常隐含文件中..."
echo "***************************"

echo "12.检查异常隐含文件:" >> ${Result}
hideFile=$(find / -xdev -mount \( -name "..*" -o -name "...*" \) 2> /dev/null)
if [  -z "${hideFile}" ];then
  echo "Y:不存在异常文件，符合要求" >> ${Result}
else
  echo "N:${hideFile}是异常文件，建议审视" >> ${Result}
fi
  
#项目：日志审计-syslog登录事件记录
#合格：Y;不合格：N;检查：C

echo "14.syslog登录事件记录中..."
echo "***************************"

echo "13.syslog登录事件记录:" >> ${Result}
if [  -e /etc/syslog.conf ];then
   logFile=$(cat /etc/syslog.conf | grep -V ^# | grep authpriv.*)
  if [ ! -z "${logFile}" ];then
    echo "Y:存在保存authpirv的日志文件" >> ${Result}
  else
    echo "N:不存在保存authpirv的日志文件" >> ${Result}
  fi
else
  echo "N:不存在/etc/syslog.conf文件，建议对所有登录事件都记录" >> ${Result}
fi
  
#项目：系统文件-检查日志审核功能是否开启
#合格：Y;不合格：N;检查：C

echo "15.检查日志审核功能是否开启中..."
echo "***************************"

echo "14.检查日志审核功能是否开启:" >> ${Result}
auditdStatus=$(service auditd status 2> /dev/null)
if [ $? = 0 ];then
  echo "Y:系统日志审核功能已开启，符合要求" >> ${Result}
fi
if [ $? = 3 ];then
  echo "N:系统日志审核功能已关闭，不符合要求，建议service auditd start开启" >> ${Result}
fi

#项目：系统文件-系统core dump状态
#合格：Y;不合格：N;检查：C

echo "16.检查日志审核功能是否开启中..."
echo "***************************"

echo "15.系统core dump状态:" >> ${Result}
limitsFile=$(cat /etc/security/limits.conf | grep -V ^# | grep core)
if [ $? -eq 0 ];then
  soft=`cat /etc/security/limits.conf | grep -V ^# | grep core | awk {print $2}`
  for i in $soft
  do
    if [ "$i"x = "soft"x ];then
      echo "Y:* soft core 0 已经设置" >> ${Result}
    fi
    if [ "$i"x = "hard"x ];then
      echo "Y:* hard core 0 已经设置" >> ${Result}
    fi
  done
else 
  echo "N:没有设置core，建议在/etc/security/limits.conf中添加* soft core 0和* hard core 0" >> ${Result}
fi

echo "17.检查系统日志读写权限中..."
echo "***************************"
#项目：系统文件-日志文件权限
#合格：Y;不合格：N;检查：C

echo "16.检查系统日志读写权限:" >> ${Result}
if [ -e /var/log/messages ];then
	MESSAGES=`ls -l /var/log/messages | awk '{print $1}'`
	echo "C:/var/log/messages的文件权限为：${MESSAGES:1:9}" >> ${Result}
else
	echo "未找到/var/log/messages的文件" >> ${Result}
fi

if [ -e /var/log/secure ];then
    SECURE=`ls -l /var/log/secure | awk '{print $1}'`
    echo "C:/var/log/secure 的文件权限为：${SECURE:1:9}" >> ${Result}
else
    echo "未找到/var/log/secure的文件" >> ${Result}
fi

if [ -e /var/log/maillog ];then
   MAILLOG=`ls -l /var/log/maillog | awk '{print $1}'`
    echo "C:/var/log/maillog 的文件权限为：${MAILLOG:1:9}" >> ${Result}
else
   echo "未找到/var/log/maillog的文件" >> ${Result}
fi

if [ -e /var/log/cron ];then
   CRON=`ls -l /var/log/cron | awk '{print $1}'`
   echo "C:/var/log/cron 的文件权限为：${CRON:1:9}" >> ${Result} 
else
   echo "未找到/var/log/cron的文件" >> ${Result} 
fi

if [ -e /var/log/spooler ];then
   SPOOLER=`ls -l /var/log/spooler | awk '{print $1}'`
   echo "C:/var/log/spooler 的文件权限为：${SPOOLER:1:9}" >> ${Result} 
else
    echo "未找到/var/log/spooler的文件" >> ${Result} 
fi

if [ -e /var/log/boot/log ];then
  LOG=`ls -l /var/log/boot/log | awk '{print $1}'`
  echo "C:/var/log/boot/log 的文件权限为：${LOG:1:9}" >> ${Result} 
else
   echo "未找到/var/log/boot/log的文件" >> ${Result} 
fi

