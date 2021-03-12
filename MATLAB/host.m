% FYP 7331
% host.m
% By Liuxin Shen
% This class defines a host class with its properties and methods

% Update 2021.3.9
% By Zhiang Chen
% Complete method hostsent, feedback and resend.
% Complete method hostread 
% This class is used to represent a host in the MAS control
classdef host <handle
    properties 
        u; %host udp varaible
        counter; %the unique ID of this host
        history; %stores the historial message sent from the host
        target_ports; %Store the id of each rover and their corresponding port number
    end
    methods
        
        % Constuctor takes the locaport and remote port as input
        function obj= host(localport,remoteport)
        obj.u = udp('127.0.0.1','RemotePort',remoteport,'LocalPort',localport);
        fopen (obj.u);
        obj.counter=0;
        obj.history=[];
        obj.target_ports=[remoteport+1 localport 1;remoteport+2 localport 2;remoteport+3 localport 3];
        end
        
        % Change remote port of the host
        function state= setRemotePort(obj,new_remoteport)
        state=1;
        obj.u.Remoteport=new_remoteport;
        end

 
        function state=hostsent(obj,rover_id,input)%change remote_port to rover iD
        %add a counter to input
        state=1;
        msg_c=num2str(obj.counter+rover_id*10);
        msg=char(msg_c+input);
        obj.counter=obj.counter+1;
        %store the msg in msg history
        obj.history=[obj.history;msg];
        %send msg to agent, and report if successful
        disp('Message sent');
        agent_port=obj.target_ports(rover_id,1);        
        writeUDP(obj,agent_port,msg); %use udp write function instead of fwrite
        end
        
        %read from the local port and delete the relate history msg
        function state=feedback(obj,msgcounter)
            state=1;
            %delete the related msg stored in history
            [m,~]=size(obj.history);
            disp(m);
            ID=str2num(msgcounter);
            for i=1:m
                if (obj.history(i,1)==msgcounter)
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
        function state=resent(obj,roverID)
            state=1;
        %based on input msgcounter,find the relate msg in history
        [m,~]=size(obj.history);
        msg=[];
        target_port=obj.target_ports(roverID,1);
            for i=1:m
                if (str2num(obj.history(i,1))==roverID)
                    msg=obj.history(i,:);
                    break;
                end
            end
            %send the msg to the new agent_port
            obj.writeUDP(target_port,msg);
        end
        
        function state=writeUDP(obj,targetport,msg)
            state=1;
            obj.setRemotePort(targetport);
            fwrite(obj.u,msg);
        end
        
        
        function state=hostread(obj)
           state=1;
           msg = fread(obj.u);
           if(msg(1)~='-')
               feedback(obj,msg);
           else
               %update the new port number to the host
               roverid=str2num(msg(2));
               new_targetport=str2num(msg(3:6));
               msgID=str2num(msg(7:8));
               if 0<roverid<4
                   obj.targetports(roverid,1)=new_targetport;
                   if (resent(obj,roverid)==1)
                       disp('resent successful');
                   else 
                       disp('resent failed');
                   end
               else 
                   disp('error,out of boundary');
               end
           end
        end

        function delete(obj)
            fclose(obj.u);
            delete(obj.u);
        end
    end
end