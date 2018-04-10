# OpenWrt版小蝴蝶拨号认证插件

特别声明：本插件仅供研究学习使用，不得用于获取商业利益。

## 说明

本客户端是一个非常热爱编程并且非常讨厌学校垃圾赛尔网的一枚毕业生写的！从上大学以来，饱受小蝴蝶折磨，不让接路由，不让换电脑，不能开Wifi，不能用虚拟机，一人一电脑一网线！什么鬼！最重要的是网速才TMD 2兆！２兆！２兆！够干嘛吃的，还死贵死贵！饱受折磨呀。。。

目前主流的openwrt系统的路由器，后台Web系统都是用Luci开发的！而Luci又是基于Lua的，也就是说，只要你的路由器后台是Luci开发的，按理说都是能够支持本客户端的！

那么，openwrt本身就有lua库，lua是基于c++的，通过lua来实现，既简单，又便于移植，还不用拖带python、java那样庞大的库！仅程序代码，小巧又方便！

好了，经过几个星期的研究学习，终于实现了lua的小蝴蝶拨号客户端，有了这个客户端，妈妈再也不用担心我的学习！

## 更新说明
-------- 2017-11-7 --------

1. 可通过修改bin/conf.lua文件，配置host_ip，service

2. 修复城建学院的赛尔网搜索服务返回空值，导致无法获取service，拨号失败的问题，增加了默认service="int"，如有不同，也可以通过第1项自行配置。

3. 无法获取service时，增加警告提示，使用默认service

-------- 2017-9-23 --------

1. 增加log指令，可通过`/etc/init.d/supplicant log`来查看拨号日志

2. 优化日志记录逻辑

3. 增加自动启动拨号，可通过`/etc/init.d/supplicant enable/disable`来启用自动拨号或关闭

4. 状态信息修改为显示程序运行情况和拨号情况

## 支持院校

### 测试通过

1. 烟台大学赛尔网

2. 广州大学华软软件学院

3. 安徽师范大学

4. 广州城建学院

5. 华南农业大学珠江学院

## 运行环境

安装有openwrt的路由器，包括但不限于 `Pandora Box` `Busy Box` 等。

## 重要提示

`仅支持` 外网认证（BAS认证）
`不支持` PPPOE、Web认证

内网认证请使用 mentohust

## 安装说明

1. 确认你能够使用ssh连接到openwrt路由器。

```
ssh -p 1022 root@192.168.1.1
```

2. 将源码中的supplicant目录打包supplicant.tar.gz并上传到路由器/root目录。命令如下：

```
scp -P 1022 supplicant.tar.gz root@192.168.1.1:/root
```

-P 后面是路由器ssh端口号,一般是1022或者22, root@后面是你的路由器ip地址。如果你的路由器地址和端口和上面命令不同，请修改成你自己的。

3. ssh连接到路由器，解压，执行：

```
tar -zxvf supplicant.tar.gz
cd supplicant
ls
```

可以看到 install.sh ,这个就是安装脚本,停！先别着急进行安装！在执行安装之前还有些注意事项，总有些傻瓜不知道，我还是强调一下吧：

首先，你要把校园网的网线插在路由器的Wan口！！！

首先，你要把校园网的网线插在路由器的Wan口！！！

首先，你要把校园网的网线插在路由器的Wan口！！！

重要的事情说三遍，嘻嘻！

其次，登录你的路由器后台（什么？怎么登录路由器后台地址还要我教？），进入系统后台后修改路由器　Wan口　Mac地址（也就是克隆Mac地址），把你用小蝴蝶拨号的那台电脑上的Mac地址复制过来粘贴上！Mac地址在小蝴蝶拨号客户端里面能找到。

接着，如果你学校的赛尔网支持DHCP（ip自动获取），那么修改上网方式为自动上网（有的路由器不叫自动上网，反正不能是PPPOE拨号）；如果不支持DHCP，请修改上网方式为静态IP方式上网，按照开通赛尔网时给你的IP地址，子网掩码，默认网关，DNS等通通填好。

接下来执行安装：

```
sh install.sh
```

按照提示输入用户名（Username）、密码（Password），对了，还有可能让你输入Mac地址（Mac Addr），你会疑惑了，为甚么上面我克隆了Mac地址，怎么还让我输入Mac Addr？哦，好吧，我来告诉你：

程序本身是会自动获取你克隆的Mac地址的！

程序本身是会自动获取你克隆的Mac地址的！

程序本身是会自动获取你克隆的Mac地址的！

但这好像也并不能排除获取出错导致没获取到Mac地址的情况？发生错误啦！好吧，那你就按照提示输入Mac地址呗！除了让你输入我还能怎么办（你来告诉我，我保证不打死你）？

4.　输入完成后终于提示 Install Success!　那么恭喜你了！接下来就是最鸡冻人心的时刻了：

```
root@Hiwifi:~# /etc/init.d/supplicant
Syntax: /etc/init.d/supplicant [command]

Available commands:
        start   Start the service
        stop    Stop the service
        restart Restart the service
        reload  Reload configuration files (or restart if that fails)
        enable  Enable service autostart
        disable Disable service autostart
        status  Display the service's status
        log 	Show supplicant's log
```
看到了吧？　执行 /etc/init.d/supplicant 就可以看到支持的命令咯！翻译一下：
-   start:	启动拨号上网
-    stop:	停止拨号上网（这不是有病嘛？我拿来不就是上网的，干嘛要停止？）
- restart:	重启拨号
-  reload:	重新加载配置文件，会重新让你输入用户名、密码，当然还有可能让你输入Mac地址
-  enable:	允许小蝴蝶自动启动
- disable:	不允许小蝴蝶自动启动
-  status:	查看程序拨号状态信息
- log:	查看拨号日志, 拨号失败了来这里查看状态日志，找找原因！

那么开始上网吧！

## 配置说明
关于conf.lua的配置说明如下（当且仅当程序拨号获取不到配置或者获取错误时可修改，命令 /etc/init.d/supplicant reload 会更新此配置）：

```
dhcp='0'                                #是否支持dhcp，0--不支持，1--支持，默认为0，可无需改动
version='3.8.2'   			#小蝴蝶认证版本（默认3.8.2），如出现版本号不对导致无法拨号的情况，请修改为学校小蝴蝶的版本号
service='int'     			#internet服务（自动获取）,一般是int/internet
host_ip='219.218.154.250'               #服务器ip地址（自动获取）
ip='180.201.54.232'			#本地ip地址（自动获取）
mac_addr='00:90:F5:F7:39:B0'		#网卡的mac地址（自动获取）
```

authc.lua配置说明（此文件是在安装时根据输入的用户名和密码生成，可无需改动，如果要重新配置，请使用命令 /etc/init.d/supplicant reload ）：

```
username='201358501113'                 #用户名
password='8888'				#密码
```

## 彩蛋
如果你安装本客户端后却不能够成功拨号上网，请查看状态日志，找一下原因，如果是配置信息不正确导致的，可以直接到程序目录修改配置文件的哦！程序安装目录在/usr/share/supplicant，bin目录是主程序及配置文件所在，authc.lua存储了你的用户名和密码，conf.lua存储了一些配置信息，包括Mac地址，版本号，dhcp配置等，如果你发现这些信息有可能是不正确的，那么你可以直接修改这些信息。
如果是ip地址不正确（一般不会出现），ip地址不包含在配置文件中，是程序运行中自动获取的，因此你应该去修改Wan口网卡的ip地址。

如果安装不成功，提示缺少md5.lua，在本项目目录，你可以发现一个luamd5.tar.gz的压缩包，这是从我自己极路由1s上提取出来的，你可以尝试一下将其上传到路由器，解压到/usr/lib/lua目录下，再次执行安装，如果依然不能成功，提示md5不能正确识别或不能加载，那可能是这个md5不适合你的系统，请去百度下载安装符合你系统的md5模块，或者自行编译？

## Bug Report
Email: shawn_hou@163.com

## 特别感谢
感谢 [xingrz](https://github.com/xingrz/swiftz-protocal "xingrz/swiftz-protocal") 提供的协议。
感谢 [HinsYang](https://github.com/HinsYang "HinsYang's GitHub") 提交的bug。
感谢各位帮助测试的童鞋！

## 特别支持
如果你成功使用本软件客户端拨号了，那么首先要恭喜你！记得回来点击页面右上角的 `star` 按钮，给我点亮一颗小星星吧！另外呢，如果你不嫌弃的话，可以给我打赏哟！一块不嫌少，一百块不嫌多，赚点打赏费，更新维护才更有动力嘛！支持微信和支付宝！

![支付宝](https://github.com/shawn-hou/lua_supplicant/raw/master/img/alipay.png)
![微信](https://github.com/shawn-hou/lua_supplicant/raw/master/img/wechatpay.png)
