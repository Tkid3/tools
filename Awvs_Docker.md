## linux安装：

官方默认不支持centos，所以需要ubuntu的系统。

1.Ubuntu安装依赖包：

```bash
apt-get install libxdamage1 libgtk-3-0 libasound2 libnss3 libxss1 libx11-xcb-dev
```

2.官网下载demo，安装，登陆后台。(地址填服务器ip)
3.下载破解补丁patch_awvs，放到/home/acunetix/.acunetix_trial/v_190409112/scanner/。执行patch_awvs

```bash
sudo chmod -R 777   /home/acunetix/.acunetix_trial/v_190703137/scanner/
```

## 卸载：

```bash
userdel -r acunetix /home/acunetix/.acunetix_trial/uninstall.sh
```

*参考链接：*

http://caidaome.com/?post=134

## 容器化：

(解决docker安装问题)最近看到两位大佬写的awvs by docker，发现自己好菜呀，只要echo -e 就可以解决的。

https://github.com/Leezj9671/SecDevices_docker/blob/master/AWVS12/Dockerfile

https://github.com/l3m0n/awvs_190703137

通过RUN sh -c '/bin/echo -e "\nyes\nubuntu\nadmin@test.com\nAa123456\nAa123456\n"| ./acunetix_trial.sh'来进行输入，echo -e "\nyes\nubuntu\n"

```dockerfile
FROM ubuntu:latest
RUN mkdir /data 
WORKDIR /data 

RUN apt-get update && apt-get upgrade -y && apt-get install -y sudo apt-utils net-tools && rm -rf /var/lib/apt/lists/* 
RUN apt-get update && sudo apt-get install libxdamage1 libgtk-3-0 libasound2 libnss3 libxss1 libx11-xcb1 -y 

COPY ./acunetix_trial.sh . RUN chmod u+x acunetix_trial.sh 
#自行修改邮箱、密码 RUN sh -c '/bin/echo -e "\nyes\nubuntu\nadmin@test.com\nAa123456\nAa123456\n"| ./acunetix_trial.sh' #wvs版本发生变化的话，请修改下方的版本号。版本号在 acunetix_trail.sh 中有 
WORKDIR /home/acunetix/.acunetix_trial/v_190515149/scanner 
COPY ./patch_awvs . 

USER root 
RUN chmod u+x ./patch_awvs 
CMD chmod u+x /home/acunetix/.acunetix_trial/start.sh 

USER acunetix 
CMD /home/acunetix/.acunetix_trial/start.sh 
```

```
docker build -t awvs ./
docker run -d -p 13443:13443 --name awvs awvs
docker exec -it -u root awvs /bin/bash
./patch_awvs
```
访问https://ip:13443/

*注：构建镜像的时候，进入awvs阶段会出现systemctl: command not found。可以不用理会，扫描依然可以正常运行。

##	自己做过的尝试

**v1.0**

因脚本是交互式的，所以尝试写死一些参数。脚本后半部分是数据，改shell脚本导致数据异常。改好shell然后再用docker安装就安装脚本异常了，好像是脚本做了偏移获取数据内容。(在line 5有这个data_offset=1857)

[root@Tkid3 ~]# cat Dockerfile

```dockerfile
FROM ubuntu:14.04

COPY ./acunetix_trial.sh /opt

RUN apt-get update &&  echo |apt-get install libxdamage1 libgtk-3-0 libasound2 libnss3 libxss1 libx11-xcb-dev

RUN bash /opt/acunetix_trial.sh
```

![awvs](https://github.com/Tkid3/tools/blob/master/img/awvs-shell.png)

**v2.0**

1.尝试自己写自动输入的，就发现了expect这个东西。

写了shell脚本通过expect自动化输入交互内容。

expect脚本运行./acunetix_expect.sh

[root@Tkid3 acunetix]# cat acunetix_expect.sh

```shell
#!/usr/bin/expect
set username "awvs@qq.com"
set password "123456Abc."
set ip "0.0.0.0"
spawn sudo bash acunetix_trial.sh
expect {
        ">>>" { send "\r"}
}
#set timeout 3
send "q\r"
expect {
        ">>>" { send "yes\r"}
}
expect {
        "Hostname*" { send "$ip\r"}
}
expect {
        "Email*" { send "$username\r" }
}
expect {
        "Password:" { send "$password\r" }
}

expect {
        "Password again:" { send "$password\r" }
}
set timeout 3000
#expect { "#" { send "\r"}}
expect eof
#send "\r"
spawn echo "over!!!"

interact
```

expect需要安装

```bash
apt install expect 
```

ubuntu默认没有sudo

```bash
apt install sudo 
```

[root@Tkid3 acunetix]# cat Dockerfile 

```dockerfile
FROM ubuntu:18.04  

WORKDIR /opt 

COPY ./ /opt  

RUN apt-get update &&  echo |apt-get install libxdamage1 libgtk-3-0 libasound2 libnss3 libxss1 libx11-xcb-dev expect sudo 

RUN chmod +x acunetix_expect.sh &&  ./acunetix_expect.sh 
```

