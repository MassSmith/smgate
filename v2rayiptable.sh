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