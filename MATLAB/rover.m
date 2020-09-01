% FYP7331
% roverControl.m
% By Moyang Feng
% This class defines a rover object and its control methods

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
        end
        
        % methods
        
        % print basic info of the rover
        function printInfo(obj)
            fprintf('\n');
            fprintf('RoverID:%d\n',obj.roverID);
            fprintf('Availability:%s\n',mat2str(obj.availability));
            fprintf('Leadership:%s\n',mat2str(obj.leadership));
            fprintf('\n');
        end
        
    end
end

