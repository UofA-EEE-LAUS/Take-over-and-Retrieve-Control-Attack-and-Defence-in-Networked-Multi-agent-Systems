% FYP7331
% rover.m
% By Moyang Feng
% This class defines a rover object and its useful methods

classdef rover
    
    properties
        % basic properties
        roverID;
        availability;
        leadership;
        
        % handles
        roverHandle;
        motorHandles;
        laserHandle;
        gyroHandle;
        accelHandle;
        
        % UDP host and received data
        u;
        port;
        received;
    end
    
    methods
        
        % constructor
        
        function obj = rover(roverID,roverHandle,motorHandles,laserHandle,gyroHandle,accelHandle)
            obj.roverID = roverID;
            obj.availability = true;
            obj.leadership = false;
            obj.roverHandle = roverHandle;
            obj.motorHandles = motorHandles;
            obj.laserHandle = laserHandle;
            obj.gyroHandle = gyroHandle;
            obj.accelHandle = accelHandle;
            
            obj.port = 5010 + roverID;
            obj.u = udp('127.0.0.1','RemotePort',4012,'LocalPort',obj.port);
            obj.u.EnablePortSharing = 'on';
            fopen(obj.u);
        end
        
        % destructor - IMPORTANT: Clean up UDP ports
        
        function delete(obj)
            fclose(obj.u);
            delete(obj.u);
        end
        
        % methods
        
        % write rover properties to another rover
        function writeUDP(obj,rover)
            data = [obj.roverID obj.availability obj.leadership];
            fwrite(rover.u,data);
        end
        
        % read received data from another rover
        function received = readUDP(obj)
            received = fread(obj.u,3);
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

