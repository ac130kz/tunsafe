#!/bin/bash

function blue(){
    echo -e "\033[34m\033[01m $1 \033[0m"
}
function green(){
    echo -e "\033[32m\033[01m $1 \033[0m"
}
function red(){
    echo -e "\033[31m\033[01m $1 \033[0m"
}
function yellow(){
    echo -e "\033[33m\033[01m $1 \033[0m"
}
function bred(){
    echo -e "\033[31m\033[01m\033[05m $1 \033[0m"
}
function byellow(){
    echo -e "\033[33m\033[01m\033[05m $1 \033[0m"
}

rand(){
    min=$1
    max=$(($2-$min+1))
    num=$(cat /dev/urandom | head -n 10 | cksum | awk -F ' ' '{print $1}')
    echo $(($num%$max+$min))
}

tunsafe_install(){
    version=$(cat /etc/os-release | awk -F '[".]' '$1=="VERSION="{print $2}')
    apt update -y
    apt install -y git curl make clang-8
    git clone https://github.com/ac130kz/TunSafeClang8.git
    cd TunSafeClang8
    make && make install
    
    echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
    sysctl -p
    echo "1"> /proc/sys/net/ipv4/ip_forward
    
    mkdir /etc/tunsafe
    cd /etc/tunsafe
    tunsafe genkey | tee sprivatekey | tunsafe pubkey > spublickey
    tunsafe genkey | tee cprivatekey | tunsafe pubkey > cpublickey
    s1=$(cat sprivatekey)
    s2=$(cat spublickey)
    c1=$(cat cprivatekey)
    c2=$(cat cpublickey)
    serverip=$(curl ipv4.icanhazip.com)
    port=443
    eth=$(ls /sys/class/net | awk '/^e/{print}')
    obfsstr=$(cat /dev/urandom | head -1 | md5sum | head -c 4)
    green "1) UDP + obfuscation (fastest)"
    green "2) TCP + obfuscation"
    green "3) custom TCP + 1.1.1.1 + wireguard's max mtu = 1420"
    green "4) TCP + obfuscation + HTTPS masquerade mode"
	green "5) custom TCP + 1.1.1.1 + wireguard's max mtu = 1420 + obfuscation"
    read choose
    if [ $choose == 1 ]
    then
        
cat > /etc/tunsafe/TunSafe.conf <<-EOF
[Interface]
PrivateKey = $s1
Address = 10.0.0.1/24
ObfuscateKey = $obfsstr
PostUp   = iptables -A FORWARD -i tun0 -j ACCEPT; iptables -A FORWARD -o tun0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $eth -j MASQUERADE
PostDown = iptables -D FORWARD -i tun0 -j ACCEPT; iptables -D FORWARD -o tun0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $eth -j MASQUERADE
ListenPort = $port
DNS = 8.8.8.8
MTU = 1380

[Peer]
PublicKey = $c2
AllowedIPs = 10.0.0.2/32
EOF
        
        
cat > /etc/tunsafe/client.conf <<-EOF
[Interface]
PrivateKey = $c1
Address = 10.0.0.2/24
ObfuscateKey = $obfsstr
DNS = 8.8.8.8
MTU = 1380

[Peer]
PublicKey = $s2
Endpoint = $serverip:$port
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
        
    fi
    if [ $choose == 2 ]
    then
cat > /etc/tunsafe/TunSafe.conf <<-EOF
[Interface]
PrivateKey = $s1
Address = 10.0.0.1/24
ObfuscateKey = $obfsstr
ListenPortTCP = $port
PostUp   = iptables -A FORWARD -i tun0 -j ACCEPT; iptables -A FORWARD -o tun0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $eth -j MASQUERADE
PostDown = iptables -D FORWARD -i tun0 -j ACCEPT; iptables -D FORWARD -o tun0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $eth -j MASQUERADE
DNS = 8.8.8.8
MTU = 1380

[Peer]
PublicKey = $c2
AllowedIPs = 10.0.0.2/32
EOF
        
        
cat > /etc/tunsafe/client.conf <<-EOF
[Interface]
PrivateKey = $c1
Address = 10.0.0.2/24
ObfuscateKey = $obfsstr
DNS = 8.8.8.8
MTU = 1380

[Peer]
PublicKey = $s2
Endpoint = tcp://$serverip:$port
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
        
    fi
    if [ $choose == 3 ]
    then
cat > /etc/tunsafe/TunSafe.conf <<-EOF
[Interface]
PrivateKey = $s1
Address = 10.0.0.1/24
ListenPortTCP = $port
PostUp   = iptables -A FORWARD -i tun0 -j ACCEPT; iptables -A FORWARD -o tun0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $eth -j MASQUERADE
PostDown = iptables -D FORWARD -i tun0 -j ACCEPT; iptables -D FORWARD -o tun0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $eth -j MASQUERADE
DNS = 1.1.1.1
MTU = 1420

[Peer]
PublicKey = $c2
AllowedIPs = 10.0.0.2/32
EOF
        
        
cat > /etc/tunsafe/client.conf <<-EOF
[Interface]
PrivateKey = $c1
Address = 10.0.0.2/24
DNS = 1.1.1.1
MTU = 1420

[Peer]
PublicKey = $s2
Endpoint = tcp://$serverip:$port
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
        
    fi
    if [ $choose == 4 ]
    then
cat > /etc/tunsafe/TunSafe.conf <<-EOF
[Interface]
PrivateKey = $s1
Address = 10.0.0.1/24
ObfuscateKey = $obfsstr
ListenPortTCP = 443
ObfuscateTCP=tls-chrome
PostUp   = iptables -A FORWARD -i tun0 -j ACCEPT; iptables -A FORWARD -o tun0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $eth -j MASQUERADE
PostDown = iptables -D FORWARD -i tun0 -j ACCEPT; iptables -D FORWARD -o tun0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $eth -j MASQUERADE
ListenPort = $port
DNS = 8.8.8.8
MTU = 1380

[Peer]
PublicKey = $c2
AllowedIPs = 10.0.0.2/32
EOF
        
        
cat > /etc/tunsafe/client.conf <<-EOF
[Interface]
PrivateKey = $c1
Address = 10.0.0.2/24
ObfuscateKey = $obfsstr
ObfuscateTCP=tls-chrome
DNS = 8.8.8.8
MTU = 1380

[Peer]
PublicKey = $s2
Endpoint = tcp://$serverip:443
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
        
    fi
	if [ $choose == 5 ]
    then
cat > /etc/tunsafe/TunSafe.conf <<-EOF
[Interface]
PrivateKey = $s1
Address = 10.0.0.1/24
ObfuscateKey = $obfsstr
ListenPortTCP = 443
ObfuscateTCP=tls-chrome
PostUp   = iptables -A FORWARD -i tun0 -j ACCEPT; iptables -A FORWARD -o tun0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $eth -j MASQUERADE
PostDown = iptables -D FORWARD -i tun0 -j ACCEPT; iptables -D FORWARD -o tun0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $eth -j MASQUERADE
DNS = 1.1.1.1
MTU = 1420

[Peer]
PublicKey = $c2
AllowedIPs = 10.0.0.2/32
EOF
        
        
cat > /etc/tunsafe/client.conf <<-EOF
[Interface]
PrivateKey = $c1
Address = 10.0.0.2/24
ObfuscateKey = $obfsstr
ObfuscateTCP=tls-chrome
DNS = 1.1.1.1
MTU = 1420

[Peer]
PublicKey = $s2
Endpoint = tcp://$serverip:$port
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
        
    fi
    
cat > /etc/init.d/tunstart <<-EOF
#! /bin/bash
### BEGIN INIT INFO
# Provides:		tunstart
# Required-Start:	$remote_fs $syslog
# Required-Stop:    $remote_fs $syslog
# Default-Start:	2 3 4 5
# Default-Stop:		0 1 6
# Short-Description:	tunstart
### END INIT INFO
cd /etc/tunsafe/
tunsafe start -d TunSafe.conf
EOF
    
    chmod +x /etc/init.d/tunstart
    cd /etc/init.d
    update-rc.d tunstart defaults
    cd /etc/tunsafe
    tunsafe start -d TunSafe.conf
    
    content=$(cat /etc/tunsafe/client.conf)
    green "Now download /etc/tunsafe/client.conf"
}

add_user(){
    green "Give a new unique username"
    read -p "Enter username：" newname
    cd /etc/tunsafe/
    cp client.conf $newname.conf
    tunsafe genkey | tee temprikey | tunsafe pubkey > tempubkey
    ipnum=$(grep Allowed /etc/tunsafe/TunSafe.conf | tail -1 | awk -F '[ ./]' '{print $6}')
    newnum=$((10#${ipnum}+1))
    sed -i 's%^PrivateKey.*$%'"PrivateKey = $(cat temprikey)"'%' $newname.conf
    sed -i 's%^Address.*$%'"Address = 10.0.0.$newnum\/24"'%' $newname.conf
    
cat >> /etc/tunsafe/TunSafe.conf <<-EOF
[Peer]
PublicKey = $(cat tempubkey)
AllowedIPs = 10.0.0.$newnum/32
EOF
    tunsafe set tun0 peer $(cat tempubkey) allowed-ips 10.0.0.$newnum/32
    green "Saved the new configuration to：/etc/tunsafe/$newname.conf"
    rm -f temprikey tempubkey
}

start_menu(){
    clear
    green " ===================================="
    green " TunSafe one-click setup                "
    green " Requires：Ubuntu >= 18.04 + root access               "
    green " Creator：atrandys                      "
    green " ===================================="
    echo
    green " 1. TunSafe installation"
    green " 2. Echo client configuration"
    green " 3. Create a new user"
    yellow " 0. Exit"
    echo
    read -p "Please enter the number:" num
    case "$num" in
        1)
            tunsafe_install
        ;;
        2)
            content=$(cat /etc/tunsafe/client.conf)
            green "This is only for the first client"
            echo "${content}"
        ;;
        3)
            add_user
        ;;
        0)
            exit 1
        ;;
        *)
            clear
            red "Incorrect number"
            sleep 2s
            start_menu
        ;;
    esac
}

start_menu
