% FYP7331
% rover.m
% By Moyang Feng
% This class defines a rover object and its useful methods

%v0.2 update 2021.3.8 
%By Liuxin Shen
%Improve the UDPwrite function to transfer feedback to the host
%add variable msgID in UDP receive data to the current class.
%update writeUDP function

% v0.3 update 2021.3.11
% By Liuxin Shen 
% Update rover feedback function
% Update feedback and receive function
classdef rover <handle
    
    properties
        % basic properties
        roverID;
        availability;
        leadership;
        position;       % [x y z]
        orientation;    % [roll pitch yaw]
        target;         % [x y angle]
        
        % handles
        roverHandle;
        motorHandles;
        laserHandle;
        cameraHandle;
        gyroHandle;
        accelHandle;
        
        % UDP host and received data
        u;
        port;
        msgID;
        flag;
    end
    
    methods
        
        % constructor
        
        function obj = rover(roverID,roverHandle,motorHandles,laserHandle,cameraHandle,gyroHandle,accelHandle)
            obj.roverID = roverID;
            obj.availability = true;
            obj.leadership = false;
            obj.position = zeros(1,3);
            obj.orientation = zeros(1,3);
            obj.target = zeros(1,3);
            
            obj.roverHandle = roverHandle;
            obj.motorHandles = motorHandles;
            obj.laserHandle = laserHandle;
            obj.cameraHandle = cameraHandle;
            obj.gyroHandle = gyroHandle;
            obj.accelHandle = accelHandle;
            
            obj.port = 5010 + roverID;
            obj.u = udp('127.0.0.1','RemotePort',4012,'LocalPort',obj.port);
            obj.u.EnablePortSharing = 'on';
            fopen(obj.u);
            obj.flag=0;
            obj.msgID=10*roverID;
        end
        
        % destructor - IMPORTANT: Clean up UDP ports
        
        function delete(obj)
            fclose(obj.u);
            delete(obj.u);
        end
        
        % methods
        function state=feedback(obj,msgID)
            state=1;
            obj.writeUDP(msgID);
        end
        % feedback rover status to the host
        function writeUDP(obj,msg)
            
            fwrite(obj.u,msg);
        end
        
        % read received data from host
        function received = readUDP(obj)
            %detection update later
            received = fread(obj.u);
%             obj.receivelist= [obj.receivelist received(1:2);
        end
        
        % get the distance and angle from current position to target
        function diff = getTargetDiff(obj)
            distance = norm(obj.target(1:2) - obj.position(1:2));
            angle = abs((obj.target(3) - rad2deg(obj.orientation(3)) - 150));
            diff = [distance angle];
        end
        
        function state=reset_port(obj)
            state=1;
%             obj.flag=6;
            %reset the port
            fclose(obj.u);
            delete(obj.u);
            obj.port = obj.port+10;
            disp(obj.port);
            obj.u = udp('127.0.0.1','RemotePort',4012,'LocalPort',obj.port);
            fopen(obj.u);
            %sent the reset ID to the agent 
            reset_msg=['-' int2str(obj.roverID) int2str(obj.port) int2str(obj.msgID)];
            obj.writeUDP(reset_msg);
            
        end
        
        % print basic info of the rover
        function printInfo(obj)
            fprintf('\n');
            fprintf('RoverID:%d\n',obj.roverID);
            fprintf('Availability:%s\n',mat2str(obj.availability));
            fprintf('Leadership:%s\n',mat2str(obj.leadership));
            fprintf('UDP:127.0.0.1:%d\n',obj.port);
            fprintf('\n');
        end
        
    end
end

