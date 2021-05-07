
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

% Update 2021.4.7
% By Moyang Feng
% Enhanced error handling when parsing data
% Fixed syntax errors

classdef host <handle
    properties
        u; %host udp varaible
        counter; %the unique ID of this host
        history1; %stores the historial message sent from the host
        history2; %stores the historial message sent from the host
        history3; %stores the historial message sent from the host
        target_ports; %Store the id of each rover and their corresponding port number
        ra;
    end
    
    methods
        
        % Constuctor takes the locaport and remote port as input
        function obj = host(localport,remoteport)
            obj.u = udp('127.0.0.1','RemotePort',remoteport,'LocalHost','127.0.0.1','LocalPort',localport);
            fopen(obj.u);
            
            obj.counter=[0 0 0];
            obj.history1=[];
            obj.history2=[];
            obj.history3=[];
            obj.target_ports=[remoteport+1 localport 1;remoteport+2 localport 2;remoteport+3 localport 3];
            obj.ra = 2;
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
            fprintf('Sending message: %s\n', msg);
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
        
        % function update the new agent port to the target ports
        function state = set_port(obj, roverID, newport)
            state = 1;
            obj.target_ports(roverID,1) = newport;
        end
        
        
        %accept a reset order, update the new target_ports
        function state=resend(obj,roverID)
            state=1;
            %based on input msgcounter,find the relate msg in history
            %[m,~]=size(obj.history);
            
            switch roverID
                case 1
                    msg=obj.history1;
                case 2
                    msg=obj.history2;
                case 3
                    msg=obj.history3;     
            end
            target_port=obj.target_ports(roverID,1);
            
            %             for i=1:m
            %                 if (str2num(obj.history(i,1:2))==msgID)
            %                     msg=obj.history(i,:);
            %                     disp(msg);
            %                     break;
            %                 end
            %             end
            
            %send the msg to the new agent_port
            disp("Resending message: ");
            disp(msg);
            obj.mirrorSend(target_port,msg);
        end
        
        function state = agent_reset(obj, roverID, newport)
            state = 1;
            obj.set_port(roverID, newport);
            
            obj.resend(roverID);
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
                    disp('Resend');
                    msg=char(msg)';
                    %hostudp.reset(msg);
                    roverid=str2num(msg(2));
                    new_targetport=str2num(msg(3:6));
                    msgID=str2num(msg(7:8));
                    
                    if 0<roverid && roverid<4
                        obj.target_ports(roverid,1)=new_targetport;
                        if (obj.resend(roverid,msgID)==1)
                            disp('Resend successful');
                        else
                            disp('Resend failed');
                        end
                    else
                        disp('Error,out of boundary');
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
            
            % rotation angles
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
        function [valid,roverID,msgID,detected,pos,ori,tar,det] = parseMsg(obj,received)
            msg = char(received');
            valid = true;
            
            fprintf('Received message: %s\n', msg);
            
            % required variables
            roverID = 0;
            msgID = 0;
            detected = 0;
            pos = zeros(1,3);
            ori = zeros(1,3);
            tar = zeros(1,3);
            det = zeros(1,3);
            newport = 0;
            reset = 0;
            
            % try to parse the received message
            try
                msg = split(split(msg,";"),":");
            catch
                % report a warning and return if incorrect format
                warning('>> Incorrect Message Format Detected, Message Ignored <<');
                valid = false;
                return
            end
            
            % process data
            for i = 1:size(msg,1)
                
                % try to convert data into double
                tmp = str2double(msg(i,2));
                if isnan(tmp)
                    % report a warning and return
                    warning('>> Message Corrupted <<');
                    valid = false;
                    return
                end
                
                if msg(i,1) == "id"
                    roverID = tmp;
                elseif msg(i,1) == "msgid"
                    msgID = tmp;
                elseif msg(i,1) == "x"
                    pos(1) = tmp;
                elseif msg(i,1) == "y"
                    pos(2) = tmp;
                elseif msg(i,1) == "z"
                    pos(3) = tmp;
                elseif msg(i,1) == "roll"
                    ori(1) = tmp;
                elseif msg(i,1) == "pitch"
                    ori(2) = tmp;
                elseif msg(i,1) == "yaw"
                    ori(3) = tmp;
                elseif msg(i,1) == "xt"
                    tar(1) = tmp;
                elseif msg(i,1) == "yt"
                    tar(2) = tmp;
                elseif msg(i,1) == "at"
                    tar(3) = tmp;
                elseif msg(i,1) == "d"
                    detected = tmp;
                elseif msg(i,1) == "xd"
                    det(1) = tmp;
                elseif msg(i,1) == "yd"
                    det(2) = tmp;
                elseif msg(i,1) == "zd"
                    det(3) = tmp;
                elseif msg(i,1) == "status"
                    reset = tmp;
                elseif msg(i,1) == "port"
                    newport = tmp;
                end
                
            end
            
            if reset == 1
                obj.agent_reset(roverID, newport);
            end
        end
        
        function test(obj)
            disp("Test Success");
        end
        
        % encapsulate target coordinates into strings of data pairs
        % and send to rovers in the format "xt:%.2f;yt:%.2f;at:%.2f";
        function msg = encapTargets(obj,roverTargets)
            roverCount = size(roverTargets,1);
            
            % send formatted coordinates to each rover
            for i = 1:roverCount
                msg = "xt:%.2f;yt:%.2f;at:%.2f";
                
                tmp = sprintf(msg,roverTargets(i,1),roverTargets(i,2),roverTargets(i,3));
                %msgs(i) = encoder(tmp, obj.ra);
                tmp = encoder(tmp, obj.ra);
                %obj.mirrorSend(obj.target_ports(i,1),msgs(i));
                
                switch i
                    case 1
                        obj.history1= tmp;
                    case 2
                        obj.history2= tmp;
                    case 3
                        obj.history3= tmp;
                end
                
                obj.mirrorSend(obj.target_ports(i,1),tmp);
                
            end
        end
        
        function msg = encapTargets_o(obj,roverTargets)
            roverCount = size(roverTargets,1);
            
            % send formatted coordinates to each rover
            for i = 1:roverCount
                msg = "xt:%.2f;yt:%.2f;at:%.2f";
                
                tmp = sprintf(msg,roverTargets(i,1),roverTargets(i,2),roverTargets(i,3));
                %msgs(i) = encoder(tmp, obj.ra); 
                %obj.mirrorSend(obj.target_ports(i,1),msgs(i));
                
                switch i
                    case 1
                        obj.history1= tmp;
                    case 2
                        obj.history2= tmp;
                    case 3
                        obj.history3= tmp;
                end
                
                obj.writeUDP(obj.target_ports(i,1),tmp);
                fprintf("Sending Message: %s\n", tmp);
            end
        end
        
    end
end