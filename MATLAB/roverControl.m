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
            gyroHandles = initGyroHandles(obj);
            accelHandles = initAccelHandles(obj);
            for i = 1:obj.roverCount
                rovers(i) = rover(i,roverHandles(i),motorHandles(i,:),laserHandles(i),gyroHandles(i),accelHandles(i));
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
            coordinates = [x y a];
            packedData=obj.sim.simxPackFloats(coordinates);
            [rtn]=obj.sim.simxWriteStringStream(obj.clientID,stringname,packedData,obj.sim.simx_opmode_oneshot);
        end
        
        %%%%%%%%%% Motion Control (OLD, No Longer Required) %%%%%%%%%%
        
        function moveSpin(obj,rover,x,y)
            
            %get position
            [returnCode,position] = getRoverPos(obj,rover,obj.sim.simx_opmode_blocking);
            [returnCode] = getRoverOri(obj,rover,obj.sim.simx_opmode_streaming);
            [returnCode, orientations] = getRoverOri(obj,rover,obj.sim.simx_opmode_buffer);
            position_x=position(:,1);
            position_y=position(:,2);

            if (orientations(1) >= 0)
                theta_sample = orientations(3);
            else
                if(orientations(1) < 0)
                    theta_sample = pi-orientations(3);
                elseif(orientations(3) < 0)
                    theta_sample = -orientations(3);
                end
            end

            orien_0 = theta_sample;

            rover_radius = 15;
            wheel_radius = 5.22;
            dphi = 0/ 180 * pi;
            phi = orien_0;
            % dphi = phi;
            dist_x = zeros(500);
            dist_y = zeros(500);
            dist_x(1:500) = x-position_x;
            dist_y(1:500) = y-position_y;
            i = 1;
            elapsedTime = 1;
            threshold = 0.1;

            %control
            while abs(position_x-x) >= threshold || abs(position_y-y) >= threshold

                tic;
                %get object position for derivative
                [returnCode, position_d] = getRoverPos(obj,rover,obj.sim.simx_opmode_blocking);
                [returnCode, orientations] = getRoverOri(obj,rover,obj.sim.simx_opmode_buffer);
                position_dx=position_d(:,1);
                position_dy=position_d(:,2);

                const_speed = 10;
                Kp = 0.75;
                Kd = 2.25;

                dx = (x - position_x);
                dy = (y - position_y);

                if (orientations(1) >= 0)
                    theta_sample = orientations(3);
                else
                    if(orientations(1) < 0)
                        theta_sample = pi-orientations(3);
                    elseif(orientations(2) < 0)
                        theta_sample = -orientations(3);
                    end
                end

                phi = theta_sample + (pi + 1.5);
                disp(phi);
                dphi = 2 / 180 * pi;
                theta = abs(atan(dy/dx));

                v_xs = (position_dx - position_x) / elapsedTime;
                v_ys = (position_dy - position_y) / elapsedTime;

                v_x = Kp * (const_speed * (dx/abs(dx)) * abs(cos(theta)) - v_xs) + Kd * (const_speed * (dx/abs(dx)) * abs(cos(theta)) - v_xs) / elapsedTime;
                v_y = Kp * (const_speed * (dy/abs(dy)) * abs(sin(theta)) - v_ys) + Kd * (const_speed * (dy/abs(dy)) * abs(sin(theta)) - v_ys) / elapsedTime;
                w = dphi;

                v   = ( v_x * cos(phi) + v_y * sin(phi) ) / 7.5;
                v_n = (-v_x * sin(phi) + v_y * cos(phi) ) / 7.5;

                v0 = -v * sin(pi/3) + v_n * cos(pi/3) + w * rover_radius;
                v1 =                - v_n             + w * rover_radius;
                v2 =  v * sin(pi/3) + v_n * cos(pi/3) + w * rover_radius;

                %setting motor speeds for straight line
                [returnCode]=obj.sim.simxSetJointTargetVelocity(obj.clientID,rover.motorHandles(1),v0,obj.sim.simx_opmode_blocking);
                [returnCode]=obj.sim.simxSetJointTargetVelocity(obj.clientID,rover.motorHandles(2),v1,obj.sim.simx_opmode_blocking);
                [returnCode]=obj.sim.simxSetJointTargetVelocity(obj.clientID,rover.motorHandles(3),v2,obj.sim.simx_opmode_blocking);

                %get object position
                [returnCode,position] = getRoverPos(obj,rover,obj.sim.simx_opmode_blocking);
                position_x=position(:,1);
                position_y=position(:,2);

                %record position
                dist_x(i) = dist_x(i) - (x - position_x);
                dist_y(i) = dist_y(i) - (y - position_y);
                i = i + 1;

                elapsedTime = toc;

            end

            % shut down motors
            stop(obj,rover);
            
        end
        
        % let a rover go forward
        function goForward(obj,rover,velocity)
            motorVelocities = [0,0,1];
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
        
        %%%%%%%%%% Obstacle Detection %%%%%%%%%%
        
        
        
        %%%%%%%%%% Formation Control %%%%%%%%%%
        
        
        
    end
end

