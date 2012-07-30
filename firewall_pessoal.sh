#!/bin/bash
# Firewall pessoal Linux by Zucco - 30/07/2012

# chkconfig: 35 30 70
# description: Firewall pessoal Linux
#
### BEGIN INIT INFO
# Provides: firewall_pessoal.sh
# Required-Start: $network
# Required-Stop:  
# Default-Start:  2 3 4 5
# Default-Stop:   0 1 6
# Short-Description: Firewall pessoal Linux
### END INIT INFO

# variaveis

IPTABLES="/sbin/iptables"
IP6TABLES="/sbin/ip6tables"
SYSCTL="/sbin/sysctl"
IFEXT="eth0"


case $1 in
        stop)
            ${IPTABLES} -P OUTPUT ACCEPT
            ${IPTABLES} -P INPUT ACCEPT
            ${IPTABLES} -P FORWARD ACCEPT
            ${IPTABLES} -F
            ${IPTABLES} -X
            ${IPTABLES} -Z
            ${IPTABLES} -t nat -F
            ${IPTABLES} -t nat -X
            ${IPTABLES} -t mangle -F
            ${IPTABLES} -t mangle -X

	    # ipv6
            ${IP6TABLES} -P OUTPUT ACCEPT
            ${IP6TABLES} -P INPUT ACCEPT
            ${IP6TABLES} -P FORWARD ACCEPT
            ${IP6TABLES} -F
            ${IP6TABLES} -X
            ${IP6TABLES} -Z
            ${IP6TABLES} -t mangle -F
            ${IP6TABLES} -t mangle -X
		    
        ;;
        *)
	    echo "Starting iptables firewall... "
            ${IPTABLES} -P OUTPUT ACCEPT
            ${IPTABLES} -P INPUT DROP 
            ${IPTABLES} -P FORWARD DROP
            ${IPTABLES} -F
            ${IPTABLES} -X
            ${IPTABLES} -Z 
            ${IPTABLES} -t nat -F
            ${IPTABLES} -t nat -X  
            ${IPTABLES} -t mangle -F
            ${IPTABLES} -t mangle -X

	    # ipv6
            ${IP6TABLES} -P OUTPUT DROP
            ${IP6TABLES} -P INPUT DROP
            ${IP6TABLES} -P FORWARD DROP
            ${IP6TABLES} -F
            ${IP6TABLES} -X
            ${IP6TABLES} -Z
            ${IP6TABLES} -t mangle -F
            ${IP6TABLES} -t mangle -X


	    # Sysctl Controls:	

            #activate the syncookies
	    ${SYSCTL} net.ipv4.tcp_syncookies=1
	    #block source routing
	    ${SYSCTL} net.ipv4.conf.all.accept_source_route=0
	    #disable redirects in the machine
	    ${SYSCTL} net.ipv4.conf.all.accept_redirects=0
            #filter ipspoofing
	    ${SYSCTL} net.ipv4.conf.all.rp_filter=2
            #stop responding to broadcast pings
	    ${SYSCTL} net.ipv4.icmp_echo_ignore_broadcasts=1
	    #enable bad error message protection
	    ${SYSCTL} net.ipv4.icmp_ignore_bogus_error_responses=1
	    #log packets with strange addresses
	    ${SYSCTL} net.ipv4.conf.all.log_martians=1
	    ${SYSCTL} net.ipv4.ip_local_port_range="1024 65000"
	    #kill timestamps
	    ${SYSCTL} net.ipv4.tcp_timestamps=0
	    #block dynamic ip addresses
	    ${SYSCTL} net.ipv4.ip_dynaddr=0

	    # disable ipv6
	    ${SYSCTL} net.ipv6.conf.all.disable_ipv6=1

	    # Seguranca
	    ${SYSCTL} kernel.randomize_va_space=2
	    # only in RHEL like:
	    #${SYSCTL} kernel.exec-shield=1



	    # Apesar de a política padrão ser DROP, bloqueia algumas coisas para evitar "barulho" nos logs:
            # Ignora Broadcasts
            ${IPTABLES} -A INPUT -d 255.255.255.255 -j DROP 
            #BCAST=$(ifconfig | grep Bcast | awk '{ print $4 }' | cut -d\: -f2)
            BCAST=$(/sbin/ip a | grep ${IFEXT} | grep brd | awk '{ print $4 }')
            ${IPTABLES} -A INPUT -d ${BCAST} -j DROP
            # Bad incoming source ip address 224.0.0.0/3 - Multicast
            ${IPTABLES} -A INPUT -s 224.0.0.0/3 -j DROP
            ${IPTABLES} -A INPUT -d 224.0.0.0/3 -j DROP
            # Block Fragments
            ${IPTABLES} -A INPUT -i ${IFEXT} -f  -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fragments Packets"
            ${IPTABLES} -A INPUT -i ${IFEXT} -f -j DROP


            # Block bad stuff
            ${IPTABLES} -A INPUT -m state --state INVALID -j DROP                   
	    ${IPTABLES} -A OUTPUT -m state --state INVALID -j DROP                  
	    ${IPTABLES} -A FORWARD -m state --state INVALID -j DROP 
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags ALL ALL -j DROP
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags ALL NONE -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "NULL Packets "
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags ALL NONE -j DROP # NULL packets
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags SYN,FIN SYN,FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "XMAS Packets "
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP #XMAS
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags FIN,ACK FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "Fin Packets Scan "
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags FIN,ACK FIN -j DROP # FIN packet scans
            ${IPTABLES} -A INPUT -i ${IFEXT} -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP


	    # Inicio das regras
            ${IPTABLES} -A INPUT -i lo -j ACCEPT
            ${IPTABLES} -A INPUT -i ${IFEXT} -m state --state ESTABLISHED,RELATED -j ACCEPT

	    # LOG
	    ${IPTABLES} -A INPUT -i ${IFEXT} -j LOG --log-level 4 --log-prefix "Firewall: "

	    echo 
	    echo "Iptables Firewall started!"

        ;;
esac

