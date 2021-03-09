% FYP 7331
% host.m
% By Liuxin Shen
% This class defines a host class with its properties and methods

% Update 2021.3.9
% By Zhiang Chen
% Complete method hostsent, feedback and resend.

% This class is used to represent a host in the MAS control
classdef host
    properties 
        u; %host udp varaible
        counter; %the unique ID of this host
        history; %stores the historial message sent from the host
    end
    methods
        
        % Constuctor takes the locaport and remote port as input
        function obj= host(localport,remoteport)
        obj.u = udp('127.0.0.1','RemotePort',remoteport,'LocalPort',localport);
        fopen (obj.u);
        obj.counter=0;
        obj.history=[];
        end
        
        % Change remote port of the host
        function state= setRemotePort(obj,new_remoteport)
        state=1;
        obj.u.Remoteport=new_remoteport;
        end

        % Sent a msg(input) to the remote_port after encoding it
        function state=hostsent(obj,remote_port,input)%change remote_port to rover iD
        %add a counter to input
        msg=[obj.counter input];
        obj.counter=obj.counter+1;
        %store the msg in msg history
        obj.history=[obj.history;msg];
        %send msg to agent, and report if successful
        state=fwrite(remote_port,msg); %use udp write function instead of fwrite
        end
        
        %read from the local port and delete the relate history msg
        function state=feedback(msgcounter)
            state=1;
            %delete the related msg stored in history
            [m,~]=size(obj.history);
            for i=1:m
                if (obj.history(i,1)==msgcounter)
                obj.history(i,:)=[];
                %print some information here
                break;
                end
            end
        %maybe add some default case here
        end
        
        %accept a reset order, update the new 
        function state=resent(obj,msgID,agent_port)
        %based on input msgcounter,find the relate msg in history
            for i=1:m
                if (obj.history(i,4)==msgID)
                    msg=obj.history(i,:);
                    break;
                end
            end
            %send the msg to the new agent_port
            state=fwrite(agent_port,msg);
        end
        
        function state=writeUDP(obj,targetport,msg)
            state=1;
            obj.setRemotePort(targetport);
            fwrite(obj.u,msg);
        end
        
        %This function is used to receive msg from the agents
%         function state=readUDP(obj,roverID)
%             state=1;
%             %read udp msg from relate roverID ports
%             
%             
%             %decide wether it is a feedback msg or a reset msg
%             
%             %call the relate function 
%         end

        function delete(obj)
            fclose(obj.u);
            delete(obj.u);
        end
    end
end