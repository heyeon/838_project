#!/usr/bin/env bash

server_pidfile="server.pid"
client_pidfile="client.pid"
user=`whoami`

if [ "$1" == "" ]; then
	echo "usage: exp_{client|server}.sh interface"
	exit 1  
fi

if [ -f $client_pidfile ]; then
        pid=`cat $client_pidfile`
        if [ -e "/proc/${pid}" ]; then
                echo "Already running a client!"
                exit 1
        fi
        #pid file found, but does not appear to be running anymore, so delete it
        rm -f $client_pidfile
fi

echo $$ > $client_pidfile

exp_number=`cat exp_num`

if [ -f "${exp_number}_client.cpu" ] || [ -f "${exp_number}_client.iperf" ] || [ -f "${exp_number}_client.ping" ] || [ -f "${exp_number}_client.pcap" ]; then
        echo "File exists! Exiting..."
        exit 1
fi

sudo ethtool -k $1 > "${exp_number}_client.ethtool"

sudo tcpdump -Z $user -s 96 -i $1 port 5001 -w "${exp_number}_client.pcap" &
tcpdump_pid=$!

echo "iperf"
iperf -u -c 172.16.1.1 -i 10 -t 60 -b 500M > "${exp_number}_client.iperf" &
#iperf -u -c isengard -i 10 -t 60 -b 500M > "${exp_number}_client.iperf" &
#iperf -c isengard -i 10 -t 60 > "${exp_number}_client.iperf" &
iperf -c 172.16.1.1 -i 10 -t 60 > "${exp_number}_client.iperf" &
iperf_pid=$!

echo "pidstat"
pidstat -p $iperf_pid 1 > "${exp_number}_client.cpu" &
pidstat_pid=$!

echo "ping"
#ping isengard -i .2 > "${exp_number}_client.ping" &
ping 172.16.1.1 -i .2 > "${exp_number}_client.ping" &
ping_pid=$!

echo "waiting for iperf to finish..."
wait $iperf_pid

#while [ -e "/proc/${iperf_pid}" ]; do
#	sleep 1
#done

echo "Done waiting for iperf..."

#kill all processes here
kill -SIGINT $pidstat_pid
kill -SIGINT $ping_pid
sudo kill -SIGINT $tcpdump_pid
echo "Killed processes"
#update the experiment number after the client is finished

#chown `whoami` ${exp_number}_client.pcap

rm -f $client_pidfile
