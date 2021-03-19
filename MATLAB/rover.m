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

% v0.4 update 2021.3.17
% By Liuxin Shen
% Update rover read with mirror attack dection system
% Add varibale u1, u2, u3 for mirror udp port, add reset flag
% Update constructor and delete function based on the above update

% v0.4 update 2021.3.18
% By Liuxin Shen
% Fix bugs on readUDP(msg comparing)
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
        u1;
        u2;
        u3;
        port;
        msgID;
        reset; %used for system failure
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
            obj.u1 = udp('127.0.0.1','RemotePort',4012,'LocalPort',obj.port);
            obj.u1.EnablePortSharing = 'on';
            fopen(obj.u1);
            obj.u2 = udp('127.0.0.1','RemotePort',4012,'LocalPort',obj.port+100);
            obj.u2.EnablePortSharing = 'on';
            fopen(obj.u2);
            obj.u3 = udp('127.0.0.1','RemotePort',4012,'LocalPort',obj.port+200);
            obj.u3.EnablePortSharing = 'on';
            fopen(obj.u3);
            obj.reset=0;
            obj.msgID=10*roverID;
        end
        
        % destructor - IMPORTANT: Clean up UDP ports
        
        function delete(obj)
            fclose(obj.u1);
            delete(obj.u1);
            fclose(obj.u2);
            delete(obj.u2);
            fclose(obj.u3);
            delete(obj.u3);
        end
        
        % methods
        % feedback rover status to the host
        function state=feedback(obj,msgID)
            state=1;
            obj.writeUDP(msgID);
        end
        
        % write msg to host
        function writeUDP(obj,msg)
            
            fwrite(obj.u1,msg);
        end
        
        % read received data from host
        function received = readUDP(obj)
            received = [];
            %mirror attack detection update:
            msg1=fread(obj.u1);
%             disp('msg1');
%             disp(msg1);
%             disp(size(msg1));
            msg2=fread(obj.u2);
%             disp('msg2');
%             disp(msg2);
%             disp(size(msg2));
            msg3=fread(obj.u3);
%             disp('msg3');
%             disp(msg3);
%             disp(size(msg3));
            %simple version of detect:
            if  isequal(msg1,msg2)
                received=msg1;
            elseif isequal(msg1,msg3)
                received=msg1;
            elseif isequal(msg3,msg2)
                received=msg2;
            else 
               obj.reset=1;
            end 
            %write feedback msg to the host,depends on reset flag value
            if obj.reset~=1
                fprintf("rover %d receive",obj.roverID);
                obj.feedback(obj.msgID);
                disp(obj.msgID);
                obj.msgID=obj.msgID+1;
            else 
                fprintf("rover %d reset",obj.roverID);
                obj.reset_port();
            end
%          received = fread(obj.u1);
        end
        
        % get the distance and angle from current position to target
        function diff = getTargetDiff(obj)
            distance = norm(obj.target(1:2) - obj.position(1:2));
            angle = abs((obj.target(3) - rad2deg(obj.orientation(3)) - 150));
            diff = [distance angle];
        end
        
        function state=reset_port(obj)
            state=1;
            obj.reset=0;
            %reset the port
            fclose(obj.u1);
            delete(obj.u1);
            fclose(obj.u2);
            delete(obj.u2);
            fclose(obj.u3);
            delete(obj.u3);
            obj.port = obj.port+10;
            disp(obj.port);
            obj.u1 = udp('127.0.0.1','RemotePort',4012,'LocalPort',obj.port);
            fopen(obj.u1);
            obj.u2 = udp('127.0.0.1','RemotePort',4012,'LocalPort',obj.port+100);
            fopen(obj.u2);
            obj.u3 = udp('127.0.0.1','RemotePort',4012,'LocalPort',obj.port+200);
            fopen(obj.u3);
            %sent the reset ID to the agent 
            reset_msg=['-' int2str(obj.roverID) int2str(obj.port) int2str(obj.msgID)];
            obj.writeUDP(reset_msg);
            disp(reset_msg);
            disp('Reset successfully');
            
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

