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

% v0.5 update 2021.3.18
% By Liuxin Shen
% Fix bugs on readUDP(msg comparing)

% v0.6 update 2021.4.7
% By Moyang Feng
% added message parsing and encapsulating
% optimised code structure
% updated feedback to include a status code

classdef rover <handle
    
    properties
        % basic properties
        roverID;
        position;       % [x y z]
        orientation;    % [roll pitch yaw]
        target;         % [x y angle] in world coordinate
        detected;       % 1 - detected, 0 - not detected
        dPoints;        % [x y z] in laser coordinate
        
        % handles
        roverHandle;
        motorHandles;
        laserHandle;
        cameraHandle;
        gyroHandle;
        accelHandle;
        
        % UDP hosts and ports
        u1;
        u2;
        u3;
        ports;
        
        % updated after each connection with host
        msgID;
        
        % records system failure
        reset;
    end
    
    methods
        
        % constructor
        
        function obj = rover(roverID,roverHandle,motorHandles,laserHandle,cameraHandle,gyroHandle,accelHandle)
            obj.roverID = roverID;
            obj.position = zeros(1,3);
            obj.orientation = zeros(1,3);
            obj.target = zeros(1,3);
            obj.detected = 0;
            obj.dPoints = zeros(1,3);
            
            obj.roverHandle = roverHandle;
            obj.motorHandles = motorHandles;
            obj.laserHandle = laserHandle;
            obj.cameraHandle = cameraHandle;
            obj.gyroHandle = gyroHandle;
            obj.accelHandle = accelHandle;
            
            % each rover have three UDP ports
            obj.ports = [5010 + obj.roverID,5010 + obj.roverID + 100, 5010 + obj.roverID + 200];
            obj.setupUDP();
            
            obj.reset = 0;
            obj.msgID = 10 * roverID;
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
        
        function setupUDP(obj)
            obj.u1 = udp('127.0.0.1','RemotePort',4012,'LocalHost','127.0.0.1','LocalPort',obj.ports(1));
            fopen(obj.u1);
            
            obj.u2 = udp('127.0.0.1','RemotePort',4012,'LocalHost','127.0.0.1','LocalPort',obj.ports(2));
            fopen(obj.u2);
            
            obj.u3 = udp('127.0.0.1','RemotePort',4012,'LocalHost','127.0.0.1','LocalPort',obj.ports(3));
            fopen(obj.u3);
        end
        
        % feedback rover status to the host
        function rtn = feedback(obj,status)
            rtn = 1;
            msg = "id:%d;msgid:%d;status:%d";
            msg = sprintf(msg,obj.roverID,obj.msgID,status);
            obj.writeUDP(msg);
        end
        
        % send message to the host
        function writeUDP(obj,msg)
            fwrite(obj.u1,msg);
        end
        
        % encapsulate data into a string and send to the host
        % {x1:val1;x2:val2;...xn:valn}
        function msg = encapData(obj)
            % rover & message ID
            id = "id:%d;msgid:%d;";
            id = sprintf(id,obj.roverID,obj.msgID);
            
            % position (x, y, z)
            pos = "x:%.2f;y:%.2f;z:%.2f;";
            pos = sprintf(pos,obj.position(1),obj.position(2),obj.position(3));
            
            % orientation (roll, pitch, yaw)
            ori = "roll:%.2f;pitch:%.2f;yaw:%.2f;";
            ori = sprintf(ori,obj.orientation(1),obj.orientation(2),obj.orientation(3));
            
            % target (xt, yt, at)
            tar = "xt:%.2f;yt:%.2f;at:%.2f;";
            tar = sprintf(tar,obj.target(1),obj.target(2),obj.target(3));
            
            % detected points (d) (xd, yd, zd)
            if obj.detected == 1
                % send detection state and detected points
                det = "d:%d;xd:%.2f;yd:%.2f;zd:%.2f";
                det = sprintf(det,obj.detected,obj.dPoints(1),obj.dPoints(2),obj.dPoints(3));
            else
                % send the detection state only
                det = "d:%d";
                det = sprintf(det,obj.detected);
            end
                
            msg = id + pos + ori + tar + det;
            writeUDP(obj,msg);
        end
        
        % parse data received from the host and store into a matrix of data pairs
        function valid = parseMsg(obj,received)
            msg = char(received');
            valid = true;
            
            % try to parse the received message
            try
                msg = split(split(msg,";"),":");
                disp(msg);
            catch
                % report a warning and return if incorrect format
                warning('INCORRECT MESSAGE FORMAT');
                valid = false;
                return
            end
            
            % check for targets
            for i = 1:size(msg,1)
                if msg(i,1) == "xt"
                    obj.target(1) = str2double(msg(i,2));
                elseif msg(i,1) == "yt"
                    obj.target(2) = str2double(msg(i,2));
                elseif msg(i,1) == "at"
                    obj.target(3) = str2double(msg(i,2));
                end
            end
        end
        
        % read received data from host
        function received = readUDP(obj)
            received = fread(obj.u1,1);
        end
        
        % read received data from host
        function received = mirrorRead(obj)
            received = "";
            
            % mirror attack detection update
            msg1 = fread(obj.u1,1);
%             disp('msg1');
%             disp(msg1);
%             disp(size(msg1));
            msg2 = fread(obj.u2);
%             disp('msg2');
%             disp(msg2);
%             disp(size(msg2));
            msg3 = fread(obj.u3);
%             disp('msg3');
%             disp(msg3);
%             disp(size(msg3));

            %simple detection
            if isequal(msg1,msg2)
                received = parseMsg(msg1);
            elseif isequal(msg1,msg3)
                received = parseMsg(msg1);
            elseif isequal(msg3,msg2)
                received = parseMsg(msg2);
            else 
               obj.reset = 1;
            end
            
            %write feedback msg to the host,depends on reset flag value
            if obj.reset ~= 1
                fprintf("rover %d received",obj.roverID);
                obj.feedback(1);
                obj.msgID = obj.msgID + 1;
            else 
                fprintf("rover %d reset",obj.roverID);
                obj.feedback(0);
                obj.resetPorts();
            end
        end
        
        % get the distance and angle from current position to target
        function diff = getTargetDiff(obj)
            distance = norm(obj.target(1:2) - obj.position(1:2));
            angle = abs((obj.target(3) - rad2deg(obj.orientation(3)) - 150));
            diff = [distance angle];
        end
        
        % reset the ports of the rover
        function rtn = resetPorts(obj)
            rtn = 1;
            obj.reset = 0;
            
            % reset UDP
            fclose(obj.u1);
            delete(obj.u1);
            fclose(obj.u2);
            delete(obj.u2);
            fclose(obj.u3);
            delete(obj.u3);
            
            % update ports
            obj.ports = obj.ports + 10;
            setupUDP();
            
            disp('Reset successfully');
        end
        
        % print basic info of the rover
        function printInfo(obj)
            diff = getTargetDiff();
            fprintf('\n');
            fprintf('RoverID:%d\n',obj.roverID);
            fprintf('Reset:%d\n',mat2str(obj.reset));
            fprintf('Message ID:%d\n',mat2str(obj.msgID));
            fprintf('UDP Ports:127.0.0.1:%d/%d/%d\n',obj.ports(1),obj.ports(2),obj.ports(3));
            fprintf('Distance to target:%.2fm %.2fdegrees\n',diff(1),diff(2));
            fprintf('\n');
        end
        
    end
end

