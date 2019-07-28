使用方法，路由器局域网ip设置为192.168.99.1，关闭路由器LAN口的dhcp功能。将设置好的树莓派用网线连接路由器上去。即可。

特别注意：连接到此路由器的设备网络连接属性设置必须为自动获取DNS，网关，和IP地址

使用效果，树莓派与路由器组成透明翻墙网关，只要是连接到这个路由中的设备，自动翻墙，无需再安装设置翻墙软件。本例所配置的json为白名单。
使用v2ray自带的国内IP列表与国内常用网站domain列表。列表中的网站与IP直连。不在列表中的走代理网络。

---------------------安装步骤--------------------------------
准备一个路由器，价格性能不做要求，只要能正常使用就行。
先进入到路由器设置界面，把路由器的LAN口地址IP设置为192.168.99.1。并且使用路由器正常联网。

用树莓派3B做网关代理设备。如果家用100M以上宽带请更换为3B+或树莓派4。树莓派系统为Debian 8，系统镜像为：2017-07-05-raspbian-jessie-lite.img，下载地址：https://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2017-07-05/2017-07-05-raspbian-jessie-lite.zip

下载镜像后，用USB Image Tool或Win32DiskImager、树莓派官方推荐使用Etcher等工具，写入到TF卡中。

如果TF卡以前装过树莓派系统，最好是先用SD Formatter格式化遍，用擦除模式。再写入系统，如果是新卡，可直接写。

TF卡写好系统后，一般会变成两个分区，其中一个名称为boot,在这个分区中建立一个名字为SSH的文件，无后缀，windows系统中可以用写字板新建文件，改名为SSH，注意不带后缀。

TF卡插入树莓派，启动系统，用putty登录进系统。默认用户名：pi  密码：raspberry。
树莓派的IP可以进到路由器中查找。
修改root账户密码：

sudo passwd root

输入两次密码。

开启root登录

sudo nano /etc/ssh/sshd_config

找到 PermitRootLogin without-password
修改为：
PermitRootLogin yes

保存退出，重启ssh服务。

sudo /etc/init.d/ssh restart

重新使用root账户登录系统。

停用本机的时间同步

update-rc.d -f ntpd remove
update-rc.d -f ntp remove

安装ntpdate
apt install  ntpdate -y

设置自动每5分钟同步一次。因为v2ray对时间有严格要求。

sudo crontab -e

编辑工具选择nano，
最后添加一行：

*/5 * * * * /usr/sbin/ntpdate 114.118.7.163

树莓派开启 IP 转发。
执行命令：nano /etc/sysctl.conf
文件最后添加：
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding = 1

执行命令生效：
sysctl -p

树莓派设置静态 IP（192.168.99.2），与路由器 LAN 口同一个网段，默认网关为路由器的IP（192.168.99.1）

nano /etc/dhcpcd.conf
# 使用 nano编辑文件，增加下列配置项

# 指定接口 eth0
interface eth0
# 指定静态IP，/24表示子网掩码为 255.255.255.0
static ip_address=192.168.99.2/24
# 路由器/网关IP地址
static routers=192.168.99.1
# 手动自定义DNS服务器
static domain_name_servers=114.114.114.114
重启树莓派。
reboot

使用ip:192.168.99.2重新连接

更换国内源
nano /etc/apt/sources.list

deb http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ jessie main non-free contrib
#deb-src http://mirrors.tuna.tsinghua.edu.cn/raspbian/raspbian/ jessie main non-free contrib

注释原来的源

安装v2ray
apt update
apt install -y curl
bash <(curl -L -s https://install.direct/go.sh)
因为防火墙的原因，安装可能会比较慢，请耐心等待，如果不成功，请安下面的方法：
加上代理：
下载：https://install.direct/go.sh
去https://github.com/v2ray/v2ray-core/releases这里下载相对应的文件。v2ray-linux-arm.zip
将go.sh与v2ray-linux-arm.zip复制到树莓派中，在同一个目录下。
运行命令:
./go.sh --local v2ray-linux-arm.zip
安装成功后，配置参数。
mv /etc/v2ray/config.json /etc/v2ray/config.json.bak

nano /etc/v2ray/config.json

内容如下：

{
	"inbounds": [
		{
			"port": 12345,
			"protocol": "dokodemo-door",
			"settings": {
				"network": "tcp,udp",
				"followRedirect": true
			}
		},
		{
			"tag": "dns-in",
			"protocol": "dokodemo-door",
			"port": 53,
			"settings": {
				"address": "8.8.8.8",
				"port": 53,
				"network": "udp",
				"followRedirect": false
			}
		}
	],
	"outbounds": [
		{
			"tag": "proxy",
			"protocol": "vmess",
			"settings": {
				"vnext": [
					{
						"address": "xxxxxxxxxxx",
						"port": xxxx,
						"users": [
							{
								"id": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
								"alterId": 64,
								"security": "auto"
							}
						]
					}
				]
			},
			"streamSettings": {
			"network": "tcp",
				"sockopt": {
					"mark": 255
				}
			},
			"mux": {
				"enabled": true
			}
		},
		{
			"tag": "direct",
			"protocol": "freedom",
			"settings": {},
			"streamSettings": {
				"sockopt": {
					"mark": 255
				}
			}
		},
		{
			"protocol": "dns",
			"tag": "dns-out"
		}
	],
	"dns": {
		"servers": [
			"8.8.8.8",
			{
				"address": "114.114.114.114",
				"port": 53,
				"domains": [
					"geosite:cn",
					"geosite:speedtest"
				]
			}
		]
	},
	"routing": {
		"domainStrategy": "IPIfNonMatch",
		"rules": [
			{
				"type": "field",
				"inboundTag": [
					"dns-in"
				],
				"outboundTag": "dns-out"
			},
			{
				"type": "field",
				"outboundTag": "direct",
				"ip": [
					"geoip:private"
				]
			},
			{
				"type": "field",
				"outboundTag": "direct",
				"ip": [
					"geoip:cn"
				]
			},
			{
				"type": "field",
				"outboundTag": "direct",
				"domain": [
					"geosite:cn",
					"geosite:speedtest"
				]
			}
		]
	}
}

以上配置文件中：
"address": "xxxxxxxxxxx",换成自己v2ray节点的ip或域名。
"port": xxxx,换成自己v2ray节点的端口。
"id": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",换成自己v2ray节点的UUID

/usr/bin/v2ray/v2ray -test -config=/etc/v2ray/config.json
测试配置文件是否正确。
用以下命令控制。
systemctl start v2ray
systemctl restart v2ray
systemctl stop v2ray

安装配置Dasmasq
apt update
apt install dnsmasq  -y
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.bak
nano /etc/dnsmasq.conf
添加内容如下：

port=0
no-resolv
no-poll
no-hosts
no-negcache
cache-size=81920
local=192.168.99.2
interface=eth0
bind-interfaces
dhcp-range=192.168.99.50,192.168.99.150,255.255.255.0,12h
dhcp-option=3,192.168.99.2
dhcp-option=6,192.168.99.2
log-dhcp
log-facility=/var/log/dnsmasq.log

重启dnsmasq

systemctl start dnsmasq
systemctl restart dnsmasq
systemctl stop dnsmasq

配置iptable转发规则

nano /etc/v2ray/v2rayiptable

内容如下：

#!/bin/bash

iptables -t nat -N V2RAY

iptables -t nat -A V2RAY -d 0.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY -d 10.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY -d 127.0.0.0/8 -j RETURN
iptables -t nat -A V2RAY -d 169.254.0.0/16 -j RETURN
iptables -t nat -A V2RAY -d 172.16.0.0/12 -j RETURN
iptables -t nat -A V2RAY -d 192.168.0.0/16 -j RETURN
iptables -t nat -A V2RAY -d 224.0.0.0/4 -j RETURN
iptables -t nat -A V2RAY -d 240.0.0.0/4 -j RETURN
iptables -t nat -A V2RAY -d 114.118.7.163 -j RETURN

iptables -t nat -A V2RAY -p tcp -j RETURN -m mark --mark 0xff
iptables -t nat -A V2RAY -p tcp -j REDIRECT --to-ports 12345

iptables -t nat -A PREROUTING -p tcp -j V2RAY
iptables -t nat -A OUTPUT -p tcp -j V2RAY

ip rule add fwmark 1 table 100
ip route add local 0.0.0.0/0 dev lo table 100
iptables -t mangle -N V2RAY_MASK
iptables -t mangle -A V2RAY_MASK -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 10.0.0.0/8 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 127.0.0.0/8 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 169.254.0.0/16 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 172.16.0.0/12 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 192.168.0.0/16 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 240.0.0.0/4 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 114.118.7.163 -j RETURN
iptables -t mangle -A V2RAY_MASK -p udp -j TPROXY --on-port 12345 --tproxy-mark 1
iptables -t mangle -A PREROUTING -p udp -j V2RAY_MASK

保存退出
chmod +x /etc/v2ray/v2rayiptable


添加开机启动

nano /etc/rc.local
在exit 0前面添加如下内容

sudo bash /etc/v2ray/v2rayiptable
保存退出
systemctl daemon-reload
至此设置结束。
进入到路由器设置界面，将LAN口的DHCP功能关闭。重启路由器与树莓派。

注意，如果刚设置好，但是无法正确使用，windows下可以在CMD下运行：
ipconfig /release
再运行：
Ipconfig /renew
然后再重新连接翻墙网关路由器。
