% FYP7331
% roverControl.m
% By Moyang Feng
% This class provides helper functions to access the rovers in V-REP

% Naming conventions
% rover1, rover2...
% motorxy - x is the rover number, y is the motor number in rover x

classdef roverControl
    
    properties
        % class variables
        sim;                    % remApi object
        clientID;               % client ID
        roverCount;             % number of rovers in the simulation
    end
    
    methods
        
        % constructor
        
        function obj = roverControl(sim,clientID)
            obj.sim = sim;
            obj.clientID = clientID;
            obj.roverCount = 0;
        end
        
        %%%%%%%%%% Basic Methods %%%%%%%%%%
        
        % read handles and create rover objects
        function rovers = initRovers(obj,roverCount)
            rovers = rover.empty(1,obj.roverCount);
            obj.roverCount = roverCount;
            roverHandles = initRoverHandles(obj);
            motorHandles = initMotorHandles(obj);
            laserHandles = initLaserHandles(obj);
            cameraHandles = initCameraHandles(obj);
            gyroHandles = initGyroHandles(obj);
            accelHandles = initAccelHandles(obj);
            for i = 1:obj.roverCount
                rovers(i) = rover(i,roverHandles(i),motorHandles(i,:),laserHandles(i),cameraHandles(i),gyroHandles(i),accelHandles(i));
            end
        end
        
        % get rover handles and store in an array
        function roverHandles = initRoverHandles(obj)
            roverHandles = zeros(1,obj.roverCount);
            for i = 1:obj.roverCount
                [~,roverHandles(i)] = obj.sim.simxGetObjectHandle(obj.clientID,strcat('rover',num2str(i)),obj.sim.simx_opmode_blocking);
            end
        end
        
        % get motor handles and store in a matrix
        function motorHandles = initMotorHandles(obj)
            motorHandles = zeros(obj.roverCount,3);
            for i = 1:obj.roverCount
                str = strcat('motor',num2str(i));
                for j = 1:3
                    [~,motorHandles(i,j)] = obj.sim.simxGetObjectHandle(obj.clientID,strcat(str,num2str(j)),obj.sim.simx_opmode_blocking);
                end
            end
        end
        
        % get laser sensor handles and store in an array
        function laserHandles = initLaserHandles(obj)
            laserHandles = zeros(1,obj.roverCount);
            for i = 1:obj.roverCount
                [~,laserHandles(i)] = obj.sim.simxGetObjectHandle(obj.clientID,strcat('laser_sensor',num2str(i)),obj.sim.simx_opmode_blocking);
            end
        end
        
        % get camera handles and store in an array
        function cameraHandles = initCameraHandles(obj)
            cameraHandles = zeros(1,obj.roverCount);
            for i = 1:obj.roverCount
                [~,cameraHandles(i)] = obj.sim.simxGetObjectHandle(obj.clientID,strcat('camera',num2str(i)),obj.sim.simx_opmode_blocking);
            end
        end
        
        % get gyroscope handles and store in an array
        function gyroHandles = initGyroHandles(obj)
            gyroHandles = zeros(1,obj.roverCount);
            for i = 1:obj.roverCount
                [~,gyroHandles(i)] = obj.sim.simxGetObjectHandle(obj.clientID,strcat('GyroSensor',num2str(i)),obj.sim.simx_opmode_blocking);
            end
        end
        
        % get accelerometer handles and store in an array
        function accelHandles = initAccelHandles(obj)
            accelHandles = zeros(1,obj.roverCount);
            for i = 1:obj.roverCount
                [~,accelHandles(i)] = obj.sim.simxGetObjectHandle(obj.clientID,strcat('Accelerometer',num2str(i)),obj.sim.simx_opmode_blocking);
            end
        end
        
        % set the motor velocities of a rover
        function setRoverMotorVelocities(obj,rover,motorVelocities)
            for i = 1:3
                obj.sim.simxSetJointTargetVelocity(obj.clientID,rover.motorHandles(i),motorVelocities(i),obj.sim.simx_opmode_oneshot);
            end
        end
        
        % read the laser sensor reading from a rover
        function [rtn,detectionState,detectedPoint] = getLaserReading(obj,rover,opmode)
            [rtn,detectionState,detectedPoint,~,~] = obj.sim.simxReadProximitySensor(obj.clientID,rover.laserHandle,opmode);
        end
        
        % read the camera image from a rover
        % mode = 0 for grayscale, otherwise RGB
        function [rtn,res,im] = getCameraImage(obj,rover,option,opmode)
            [rtn,res,im] = obj.sim.simxGetVisionSensorImage2(obj.clientID,rover.cameraHandle,option,opmode);
        end
        
        % get the coordinate of a rover in earth frame
        function [rtn,roverPos] = getRoverPos(obj,rover,opmode)
            [rtn,roverPos] = obj.sim.simxGetObjectPosition(obj.clientID,rover.roverHandle,-1,opmode);
        end
        
        % get the orientation of a rover wrt the earth frame (rad)
        function [rtn,roverPos] = getRoverOri(obj,rover,opmode)
            [rtn,roverPos] = obj.sim.simxGetObjectOrientation(obj.clientID,rover.roverHandle,-1,opmode);
        end
        
        %%%%%%%%%% Motion Control (New) %%%%%%%%%%
        
        % set the target coordinates and orientation of a rover
        function [rtn] = setRoverCoordinate(obj,rover,x,y,a)
            stringname = strcat('roverCoor',num2str(rover.roverID));
            rover.target = [x y a];
            packedData = obj.sim.simxPackFloats(rover.target);
            rtn = obj.sim.simxWriteStringStream(obj.clientID,stringname,packedData,obj.sim.simx_opmode_oneshot);
        end
        
        % set the target coordinates for all rovers
        function [rtn] = setRoverTargets(obj,rovers,targets)
            coordinates = double.empty;
            for i = 1:size(targets,1)
                rovers(i).target = targets(i,:);
                coordinates = [coordinates targets(i,:)];
            end
            packedData = obj.sim.simxPackFloats(coordinates);
            rtn = obj.sim.simxWriteStringStream(obj.clientID,'roverCoordinates',packedData,obj.sim.simx_opmode_oneshot);
        end
        
        %%%%%%%%%% Motion Control (OLD, No Longer Required) %%%%%%%%%%
        
        % let a rover go forward
        function goForward(obj,rover,velocity)
            motorVelocities = [-1,0,1];
            setRoverMotorVelocities(obj,rover,velocity * motorVelocities);
        end
        
        % let a rover go backward
        function goBackward(obj,rover,velocity)
            motorVelocities = [1,0,-1];
            setRoverMotorVelocities(obj,rover,velocity * motorVelocities);
        end
        
        % let a rover turn left
        function turnLeft(obj,rover,velocity)
            motorVelocities = [-2,0,1];
            setRoverMotorVelocities(obj,rover,velocity * motorVelocities);
        end
        
        % let a rover turn right
        function turnRight(obj,rover,velocity)
            motorVelocities = [-1,0,2];
            setRoverMotorVelocities(obj,rover,velocity * motorVelocities);
        end
        
        % let a rover rotate left
        function rotateLeft(obj,rover,velocity)
            motorVelocities = [-1,-1,-1];
            setRoverMotorVelocities(obj,rover,velocity * motorVelocities);
        end
        
        % let a rover rotate right
        function rotateRight(obj,rover,velocity)
            motorVelocities = [1,1,1];
            setRoverMotorVelocities(obj,rover,velocity * motorVelocities);
        end
        
        % let a rover stop
        function stop(obj,rover)
            motorVelocities = [0,0,0];
            setRoverMotorVelocities(obj,rover,motorVelocities);
        end
        
        %%%%%%%%%% Area Scanning %%%%%%%%%%
        
        % transform laser readings into world frame coordinates
        function scannedPoint = laser2World(~,detectedPoint,roverPos,roverOri)
            % the point scanned in 2D on x-y coordinates
            scannedPoint = detectedPoint';
            
            % laser sensor orientation
            %ori = atan(detectedPoint(1)/detectedPoint(3));
            
            roll = pi/2;
            yaw = roverOri(3);
            
            % rotation matrices
            Ryaw = [cos(yaw) -sin(yaw) 0
                    sin(yaw)  cos(yaw) 0
                       0         0     1];
            
            Rroll = [1      0        0
                     0 cos(roll) -sin(roll)
                     0 sin(roll)  cos(roll)];
                 
            scannedPoint = Rroll * scannedPoint;
            scannedPoint = Ryaw * scannedPoint;
            scannedPoint = scannedPoint + roverPos;
            scannedPoint(2) = scannedPoint(2) + 2;
        end
        
    end
end