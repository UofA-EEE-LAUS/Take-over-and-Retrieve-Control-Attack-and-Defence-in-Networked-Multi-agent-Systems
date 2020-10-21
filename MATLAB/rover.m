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
        received;
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
        end
        
        % destructor - IMPORTANT: Clean up UDP ports
        
        function delete(obj)
            fclose(obj.u);
            delete(obj.u);
        end
        
        % methods
        
        % feedback rover status to the host
        function writeUDP(obj,host)
            data = [obj.roverID obj.availability obj.leadership];
            fwrite(host,data);
        end
        
        % read received data from host
        function received = readUDP(obj,n)
            received = fread(obj.u,n);
        end
        
        % get the distance and angle from current position to target
        function diff = getTargetDiff(obj)
            distance = norm(obj.target(1:2) - obj.position(1:2));
            angle = abs((obj.target(3) - rad2deg(obj.orientation(3)) - 150));
            diff = [distance angle];
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

