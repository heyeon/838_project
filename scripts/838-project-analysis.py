"""This script parses and analyzes data from set of `6 experiments ran on 8th Dec, 2012.
These experiments look at enabling and disabling TSO/GRO/GSO with TCP and UDP

Author: Zainab Ghadiyali (zainab@cs.wisc.edu)
"""
import os
import sys
import logging
from prettytable import PrettyTable
from collections import defaultdict

def parse_ping(ping_file):
	file = open(ping_file, mode='r')
	latency_measurements = []
	for line in file:
		if 'rtt' in line:
			parts = line.split()
			values = parts[3].split('/')
			for v in values:
				latency_measurements.append(v)
	return latency_measurements
			
def parse_cpu(cpu_file):
	file = open(cpu_file, mode='r').readlines()
	cpu_util_measurements = defaultdict(float)
	cpu_util = 0 
	num_transfers = 0
	for line in file:
		parts=line.split()
		if 'PID' in parts or 'Linux' in parts or not parts:	
			continue
		cpu_util += float(parts[6])
		num_transfers += 1
	return round(cpu_util/num_transfers, 2)

def parse_bandwidth(iperf_file):
	file = open(iperf_file, mode='r').readlines()
	num_entries = 0
	bandwidth = 0
	for line in file:
		if 'Mbits/sec' in line:
			parts = line.split()
			num_entries += 1
			try:
				bandwidth += int(parts[6])
			except:
				continue
	return bandwidth/num_entries
 		
def process_print_results():
	table = PrettyTable(['Experiment #', 'Min_latency', 'Avg_latency', 'Max_Latency', 'Stdev_latency', 'Avg_CPU_Util %', 'Avg_Bandwidth (Mbits/sec)'])
	table.border = False
	for x in range(0,int(sys.argv[1])):
		components = ['client', 'server']
		for c in components:
				exp_name = str(x) + '_' + c
				res = []
				res.append(exp_name)
				#temp hack for dealing with no ping results for server
				if c =='client':
					for v in parse_ping('/users/griepent/838-project/' + exp_name + '.ping'):
						res.append(v)
				else:	
					for v in [0,0,0,0]:
						res.append(v)
				res.append(parse_cpu('/users/griepent/838-project/' + exp_name + '.cpu'))
				res.append(parse_bandwidth('/users/griepent/838-project/' + exp_name + '.iperf'))
				table.add_row(res)
	print table
	
def main():
	process_print_results()

# Standard boilerplate to call the main() function to begin
# the program.
if __name__ == '__main__':
    main()

