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

% message buffer
buffer_size = 10;
msg_buffer = strings(1,buffer_size);
buffer_ptr = 1;

% graph parameters
figure;
hold on;
grid on;
xlim([-10 10]);
ylim([-10 10]);
title('2-D Area Scan')
xlabel('x');
ylabel('y');

% set target for rovers in the format
% [x1 y1 angle1 
%  x2 y2 angle2 
%  x3 y3 angle3]
roverTargets = [-0.25 1.5 -330 
                -5.25 1.5 330 
                 4.75 1.5 -330];
host.encapTargets(roverTargets);

% wait for agent to reply
pause(1);

% receive data from agent
msg = '';
try
    msg = host.readUDP();
catch
    error(">> Read UDP timeout! <<");
end

% main loop, stops when udp read timeouts after 10s
while ~isempty(msg)
    
	% store into buffer
    msg_buffer(buffer_ptr) = char(msg');
    buffer_ptr = mod(buffer_ptr + 1,buffer_size) + 1;
    
    % parse message into a matrix of data pairs
    [valid,roverID,msgID,detected,pos,ori,tar,det] = host.parseMsg(msg);   
    
    % plot graph
    if valid
        plot(pos(1),pos(2),'b-o');
        if detected
            scannedPoint = host.laser2World(det,pos,ori);
            plot(scannedPoint(1),scannedPoint(2),'r-o');
        end
    end
    
    % receive data from agent
    msg = '';
    try
        msg = host.readUDP();
    catch
        error(">> Read UDP timeout! <<");
    end
end

% clean up
host.delete();