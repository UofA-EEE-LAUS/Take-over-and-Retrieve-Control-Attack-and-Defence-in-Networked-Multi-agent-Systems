hostudp=host(4012,5010);

% initialisation
sim=remApi('remoteApi');
sim.simxFinish(-1); % close all opened connections
clientID=sim.simxStart('127.0.0.1',19997,true,true,5000,5);


% connection successful
if (clientID>-1)
    % create rover controller object with 3 rovers
    rc = roverControl(sim,clientID);
    disp('Connected to client.');
    % start simulation
    sim.simxStartSimulation(clientID,sim.simx_opmode_oneshot);
    disp('Simulation Started. Type "help" for available commands. Type "quit" to stop simulation.');
    sim.simxAddStatusbarMessage(clientID,'Hello CoppeliaSim!',sim.simx_opmode_oneshot);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % set the number of rovers in the simulation
    roverCount = 3;

    % initiate rovers
    rovers = rc.initRovers(roverCount);
    
    data1="returnCode = rc.setRoverCoordinate(rovers(1),-0.25,-2.25,150);";
    data2="returnCode = rc.setRoverCoordinate(rovers(2),+1.25,-1.25,150);";
    data3="returnCode = rc.setRoverCoordinate(rovers(3),-1.75,-1.25,150);";

    %send msg from host to rovers
%     hostudp.setRemotePort(5011);
    hostudp.hostsent(1,data1);
%     fwrite(hostudp.u,'01'+data1);
    
%     hostudp.setRemotePort(5012);
    hostudp.hostsent(2,data2);
%     fwrite(hostudp.u,'02'+data2);
    
%     hostudp.setRemotePort(5013);
    hostudp.hostsent(3,data3);
%     fwrite(hostudp.u,'03'+data3);
   
    
    msg=char(rovers(1).readUDP()');
    if msg
        disp(msg);
        eval(msg(3:end));
    else 
        disp('system under attack');
    end
    
    msg=char(rovers(2).readUDP()');
    if msg
       disp(msg);
       eval(msg(3:end));
    else
        disp('system under attack');
    end
    
    msg=char(rovers(3).readUDP()');
    if msg
        disp(msg);
        eval(msg(3:end));
    else 
        disp('system under attack');
    end
   
    
    while 1
    state=hostudp.hostread();
    if ~state
        break;
    end
% msg=fread(hostudp.u);
%     if msg
%     disp(msg);
%         %feedback detection(demo)
%         if ~isequal(msg(1),'-')
%             %call feedback
%         hostudp.feedback(msg);
%         else 
%             disp ('resent');
%             msg=char(msg)';
% %             hostudp.reset(msg);
%         roverid=str2num(msg(2));
%                new_targetport=str2num(msg(3:6));
%                msgID=str2num(msg(7:8));
%                if 0<roverid<4
%                    hostudp.target_ports(roverid,1)=new_targetport;
%                    if (hostudp.resent(roverid,msgID)==1)
%                        disp('resent successful');
%                    else 
%                        disp('resent failed');
%                    end
%                else 
%                    disp('error,out of boundary');
%                end
%         end
%     else
%         break;
%     end
    end
    
    msg=char(rovers(1).readUDP()');
    if msg
        disp(msg);
        eval(msg(3:end));
    else 
        disp('system under attack');
    end
    
    msg=char(rovers(2).readUDP()');
    if msg
       disp(msg);
       eval(msg(3:end));
    else
        disp('system under attack');
    end
    
    msg=char(rovers(3).readUDP()');
    if msg
        disp(msg);
        eval(msg(3:end));
    else 
        disp('system under attack');
    end
    
    while 1
        command=input('FYP7331 >> ','s');
        if strcmp(command,'quit')
            break;
        elseif strcmp(command,'help')
            disp('quit - Stop simulation');
        else
            disp('Invalid command!');
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    hostudp.delete();
    % clean up rovers
    for i = 1:roverCount
        rc.stop(rovers(i));
        fprintf("rover %d delete\n",i);
        rovers(i).delete();
    end

    % stop simulation
    sim.simxStopSimulation(clientID,sim.simx_opmode_blocking);
    disp('Simulation Stopped.');
    % close the connection to CoppeliaSim
    sim.simxFinish(clientID);
else
    disp('Connection failed.');
end