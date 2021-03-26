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

# send UDP packet to destination
def writeUDP(data,sport,dip,dport,length,chksum):
    s = socket(AF_INET, SOCK_RAW, IPPROTO_UDP)
    #chksum = in4_chksum(socket.IPPROTO_UDP, packet[IP], udp_raw)
    udp_header = struct.pack('!HHHH', sport, dport, length, chksum)
    s.sendto(udp_header + data, (dip, dport))

# main function
if __name__ == '__main__':

    # read captured packets
    pkts = rdpcap('1.pcap')

    counter = 1

    for pkt in pkts:
        # extract message from captured packet
        #str_list,num_list = parseData(pkt.load)
        msg = pkt.load
        sip = pkt.src
        #print(sip)
        dip = pkt.dst
        sport = pkt.sport
        dport = pkt.dport
        chksum = pkt[UDP].chksum

        #chksum = checksum(pseudo_header + udp_header + payload)

        # print info of captured packets
        print('\n=== Packet %d ===' %counter)
        print('Source: %s:%s' %(sip, sport))
        print('Destination: %s:%s' %(dip, dport))
        print('Checksum: %s' %chksum)
        print('Content: ', msg)
        
        # replay packet to original destination
        try: 
            #msg = bytes(encapData(str_list,num_list),'utf-8')
            #print(msg)
            writeUDP(msg,sport,dip,dport,8 + len(msg),chksum)
            print('\nSuccessfully replayed packet %d to %s:%s\n' %(counter,dip,dport))
        except:
            print('Error: did not replay packet')
        
        counter += 1
        time.sleep(3)