% FYP7331
% area_scanning_host.m
% By Moyang Feng
% The host that retrieves data from the simulation by UDP and
% process the data to perform area scanning
% This file should be started AFTER area_scanning_agent.m

clear;
close all;
clc;

% create host object
host = host(4012,5010);

% Start UDP host on port 4012
% host = udp('127.0.0.1','RemotePort',5012,'LocalHost','127.0.0.1','LocalPort',4012);
% fopen(host);

% message buffer
buffer_size = 10;
msg_buffer = strings(1,buffer_size);
msg_counter = 1;

% set the sampling rate in Hz
samplingRate = 3;

% graph parameters
figure;
hold on;
grid on;
xlim([-5 5]);
ylim([-5 5]);
title('2-D Area Scan')
xlabel('x');
ylabel('y');

% set target for rovers
% [x1 y1 angle1 
%  x2 y2 angle2 
%  x3 y3 angle3]
roverTargets = [-0.25 0.75 -30 
                -2.25 0.75 330 
                 1.75 0.75 -30];
msgs = host.encapTargets(roverTargets);
disp(msgs);

% wait for agent to reply
pause(3);

while 1
    % receive data from agent
    msg = host.readUDP();
    valid = false;
    
	% store into buffer
    msg_buffer(msg_counter) = char(msg');
    msg_counter = msg_counter + 1;
    if msg_counter > buffer_size
        msg_counter = 1;
    end
    
    % parse message into a matrix of data pairs
    [valid,roverID,msgID,detected,pos,ori,tar,det] = host.parseMsg(msg);   
    
    if valid
        plot(pos(1),pos(2),'b-o');
        if detected
            scannedPoint = host.laser2World(det,pos,ori);
            plot(scannedPoint(1),scannedPoint(2),'r-o');
        end
    end
end

host.delete();