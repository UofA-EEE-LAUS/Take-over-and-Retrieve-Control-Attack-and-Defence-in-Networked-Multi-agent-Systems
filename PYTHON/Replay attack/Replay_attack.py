"""
Before running this code:
1. download exteranl python library scapy by following the instruction described in
https://scapy.readthedocs.io/en/latest/installation.html
2. download RawCap.exe from https://www.netresec.com/index.ashx?page=RawCap
3. download Wireshark from https://www.wireshark.org/download.html (this step is not necessary)
"""
from scapy.all import *

"""
sniff test pcap
sniff() function doesn't work for packet capture between localhost and localhost
thus, RawCap, as a third party tool is used to sniff packets and save as offline
.pcap
"""
# save test pcap 
# wrpcap("udp_pkt.pcap", packet)


# import all packets saved in the test pcap
packet = sniff(offline="dumpfile.pcap")
print(packet)
# pkt=rdpcap('test.pcap')
# print(packet[3])
# print(packet[0].show())

len1=len(packet)
print(len1)

# check and print all packets saved in the test pcap
'''
for i in range(len1):
    #if 'TCP' in packet[i]:
    infor = repr(packet[i])
    print(infor)
        # print(packet[i]['UDP'].sport)
        # print(packet[i].show())
        # break
'''

# filter packets with targeted ports and udp protocol 
ports = [5011]
filtered = (pkt for pkt in packet if
    UDP in pkt and
    (pkt[UDP].sport in ports))
wrpcap('filtered.pcap', filtered)
pkts = sniff(offline="filtered.pcap")
len2=len(pkts)
print(len2)
for data in pkts:
    a = repr(data)
    print(a)
    print (type(data))
    #print(data.show())
    #print (data.load)

# replay udp packets to attacked port
for k in filtered:
    sendp(k) #layer 2
    # send(k)
