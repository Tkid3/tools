# #baseline-check
 基于centos7的基线检查脚本

    当前包含的检查项：
    - 账号策略检查
    - 账号超时策略检查
    - ssh配置检查
    - 除root之外UID为0的用户检查
    - 检查telnet服务是否开启
    - root用户环境变量的安全性检查
    - 远程连接的安全性配置
    - 用户的umask安全配置
    - 重要目录和文件的权限设置检查
    - 查找未授权的SUID/SGID文件
    - 检查任何人都有写权限的目录
    - 检查任何人都有写权限的文件
    - 检查异常隐含文件
    - 检查syslog登录事件记录是否开启
    - 检查日志审核功能
    - 检查系统core dump状态
    - 检查系统日志读写权限
    
  吐槽:  1. 还有很多项的规则没加  
       ~~2. 多个find会大幅消耗cpu~~
           
#  #awvs-docker
[awvs by docker](https://github.com/Tkid3/tools/blob/master/Awvs_Docker.md)           