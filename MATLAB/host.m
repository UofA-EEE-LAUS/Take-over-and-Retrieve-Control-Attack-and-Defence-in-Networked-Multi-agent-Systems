% FYP 7331
% host.m
% By Liuxin Shen
% This class defines a host class with its properties and methods

% Update 2021.3.9
% By Zhiang Cheng
% Complete method hostsent, feedback and resend.
% Complete method hostread 
% This class is used to represent a host in the MAS control

% Update 2021.3.17
% By Zhiang Cheng
% Complete method mirrorSend.
% Update the function of hostsent.

% Update 2021.3.18
% By Liuxin Shen
% Fix bug on function feedback, function resend
% Use counter array to store different msgID for different rover
% Update consturctor, function sent, based on this change
% Still need to update hostread function.

% Update 2021.3.19
% By Zhiang Cheng
% Update the function of hostread, feedback and resend.
% Fix nugs on feedback and resend.

% Update 2021.4.7
% By Moyang Feng
% Moved area scanning from roverControl to here
% Added UDP message parsing methods
% Optimised code structure

classdef host <handle
    properties 
        u; %host udp varaible
        counter; %the unique ID of this host
        history; %stores the historial message sent from the host
        target_ports; %Store the id of each rover and their corresponding port number
    end
    
    methods
        
        % Constuctor takes the locaport and remote port as input
        function obj = host(localport,remoteport)
            obj.u = udp('127.0.0.1','RemotePort',remoteport,'LocalHost','127.0.0.1','LocalPort',localport);
            fopen(obj.u);
            
            obj.counter=[0 0 0];
            obj.history=[];
            obj.target_ports=[remoteport+1 localport 1;remoteport+2 localport 2;remoteport+3 localport 3];
        end
        
        % Destructor
        function delete(obj)
            fclose(obj.u);
            delete(obj.u);
        end
        
        % Change remote port of the host
        function state=setRemotePort(obj,port)
            state=1;
            obj.u.RemotePort=port;
        end
 
        function state=mirrorSend(obj,agentPort,msg)
            %the native port and msg for input
            state=1;
            obj.writeUDP(agentPort,msg);       %mirror1
            obj.writeUDP(agentPort+100,msg);   %mirror2
            obj.writeUDP(agentPort+200,msg);   %mirror3
        end
        
        function state=hostSend(obj,rover_id,input)
            %add a counter to input
            state=1;
            msg_c=num2str(obj.counter(rover_id)+rover_id*10);
            msg=char(msg_c+input);
            obj.counter(rover_id)=obj.counter(rover_id)+1;
            %store the msg in msg history
            obj.history=[obj.history;msg];
            %send msg to agent, and report if successful
            disp('Message sent');
            agent_port=obj.target_ports(rover_id,1);        
            mirrorSend(obj,agent_port,msg); %use mirrorSend function instead of udpwrite
        end
        
        function state=feedback(obj,msgcounter)
            state=1;
            %delete the related msg stored in history
            [m,~]=size(obj.history);
            ID=fix(msgcounter/10);
            for i=1:m
                if (str2num(obj.history(i,1:2))==msgcounter)
                obj.history(i,:)=[];
                %print some information here
                fprintf("message %d Successfully deleted",ID);
                break;
                elseif i==m
                    disp('Information not included');
                end
            end
        end
        
        %accept a reset order, update the new target_ports
        function state=resend(obj,roverID,msgID)
            state=1;
            %based on input msgcounter,find the relate msg in history
            [m,~]=size(obj.history);
            msg=[];
            target_port=obj.target_ports(roverID,1);
            for i=1:m
                if (str2num(obj.history(i,1:2))==msgID)
                    msg=obj.history(i,:);
                    disp(msg);
                    break;
                end
            end
            %send the msg to the new agent_port
            obj.mirrorSend(target_port,msg);
        end
        
        function state=writeUDP(obj,targetport,msg)
            state=1;
            obj.setRemotePort(targetport);
            fwrite(obj.u,msg);
        end
        
        function state=hostread(obj)
            msg=fread(obj.u);
            if msg
                state=1;
                disp(msg);
                %feedback detection(demo)
                if ~isequal(msg(1),'-')
                %call feedback
                obj.feedback(msg);
                else 
                    disp ('resend');
                    msg=char(msg)';
                    %hostudp.reset(msg);
                    roverid=str2num(msg(2));
                    new_targetport=str2num(msg(3:6));
                    msgID=str2num(msg(7:8));

                    if 0<roverid<4
                        obj.target_ports(roverid,1)=new_targetport;
                        if (obj.resend(roverid,msgID)==1)
                            disp('resend successful');
                        else 
                            disp('resend failed');
                        end
                    else 
                        disp('error,out of boundary');
                    end
                end
            else
                state=0;
            end
        end
        
        % read received data from agent
        function received = readUDP(obj)
            received = fread(obj.u,1);
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
        
        %%%%%%%%%% Message Parsing %%%%%%%%%%
        
        % parse data received from the host
        % store into a matrix of data pairs
        function valid = parseMsg(~,received)
            msg = char(received');
            valid = true;
            
            % try to parse the received message
            try
                msg = split(split(msg,";"),":");
                disp(msg)
            catch
                % report a warning and return if incorrect format
                warning('INCORRECT MESSAGE FORMAT');
                valid = false;
                return
            end
            
            % process data
            for i = 1:size(msg,1)
                
            end
        end
        
        % encapsulate target coordinates into strings of data pairs
        % and send to rovers in the format "xt:%.2f;yt:%.2f;at:%.2f";
        function msgs = encapTargets(obj,roverTargets)
            roverCount = size(roverTargets,1);
            msgs = strings(roverCount,1);
            
            % send formatted coordinates to each rover
            for i = 1:roverCount
                msg = "xt:%.2f;yt:%.2f;at:%.2f";
                msgs(i) = sprintf(msg,roverTargets(i,1),roverTargets(i,2),roverTargets(i,3));
                obj.mirrorSend(obj.target_ports(i,1),msgs(i));
            end
        end

    end
end