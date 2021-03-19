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
    tmp_list = data.decode("utf-8").split(';')

    num_list = []
    str_list = []

    for tmp in tmp_list:
        if isNum(tmp):
            num_list.append(float(tmp))
        else:
            str_list.append(tmp)

    return str_list,num_list

# encapsulate string lists to bytes
def encapData(attrs,vals):
    tmp = ''

    if len(attrs) == len(vals):
        for i in range(len(attrs)):
            tmp = tmp + attrs[i] + ';' + str(vals[i]) + ';'

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
    pkts = rdpcap('1.pcap')

    counter = 1

    for pkt in pkts:
        # extract message from captured packet
        str_list,num_list = parseData(pkt.load)
        sip = pkt.src
        dip = pkt.dst
        sport = pkt.sport
        dport = pkt.dport
        chksum = pkt[UDP].chksum

        # print info of captured packets
        print('\n=== Packet %d ===' %counter)
        print('Source: %s:%s' %(sip, sport))
        print('Destination: %s:%s' %(dip, dport))
        print('Checksum: %s' %chksum)
        print('Content: ', str_list, num_list)
        
        # replay packet to original destination
        try: 
            msg = bytes(encapData(str_list,num_list),'utf-8')
            writeUDP(msg,sport,dip,dport,8 + len(msg),chksum)
            print('\nSuccessfully replayed packet %d to %s:%s\n' %(counter,dip,dport))
        except:
            print('Error: did not replay packet')
        
        counter += 1
        time.sleep(5)