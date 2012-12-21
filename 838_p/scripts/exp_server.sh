#!/usr/bin/env bash

server_pidfile="server.pid"
client_pidfile="client.pid"
user=`whoami`

if [ "$1" == "" ]; then
        echo "usage: exp_{client|server}.sh interface"
        exit 1
fi

if [ -f $server_pidfile ]; then
	pid=`cat $server_pidfile`
	if [ -e "/proc/${pid}" ]; then
		echo "Already running a server!"
		exit 1
	fi
	#pid file found, but does not appear to be running anymore, so delete it
	rm -f $server_pidfile
fi

echo $$ > $server_pidfile

exp_number=`cat exp_num`

if [ -f "${exp_number}_server.cpu" ] || [ -f "${exp_number}_server.iperf" ] || [ -f "${exp_number}_client.pcap" ]; then
	echo "File exists! Exiting..."
	exit 1
fi

echo "${exp_number}"

sudo ethtool -k $1 > "${exp_number}_server.ethtool"

sudo tcpdump -Z $user -s 96 -i $1 port 5001 -w "${exp_number}_server.pcap" &
tcpdump_pid=$!


#iperf -u -s -i 10 > "${exp_number}_server.iperf" &
iperf -s -i 10 > "${exp_number}_server.iperf" &
iperf_pid=$!

pidstat -p $iperf_pid 1 > "${exp_number}_server.cpu" &
pidstat_pid=$!
#top -b -p $iperf_pid &
#top_pid=$!

#Give us a 30 second window to start the client
sleep 30

while [ -f "$client_pidfile" ]; do
	#echo "Waiting..."
	sleep 1
done
echo "Done waiting"
#kill all processes here
kill -SIGINT $iperf_pid
kill -SIGINT $pidstat_pid
sudo kill -SIGINT $tcpdump_pid
echo "Killed processes"

#chown `whoami` ${exp_number}_server.pcap

echo $(($exp_number + 1)) > exp_num
rm -f $server_pidfile
