% FYP7331
% area_scanning_agent.m
% By Moyang Feng
% The software layer of the MAS that connects and controls the V-REP scene
% This file should be started BEFORE area_scanning_host.m

clear;
close all;
clc;

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
    
    % initiate laser sensor
    [returnCode,detectionState,detectedPoint] = rc.getLaserReading(rovers(2),sim.simx_opmode_streaming);
    
    % get position and orientation of rover
    [returnCode,rovers(2).position] = rc.getRoverPos(rovers(2),sim.simx_opmode_streaming);
    [returnCode,rovers(2).orientation] = rc.getRoverOri(rovers(2),sim.simx_opmode_streaming);
    
    % set the sampling rate in Hz
    samplingRate = 3;
    
    % receive target coordinates from the host and send to V-REP
    for i = 1:roverCount
        fprintf("rover %d receieved:",i);
        msg = rovers(i).readUDP();
        valid = rovers(i).parseMsg(msg);
        if valid
            target = rovers(i).target;
            returnCode = rc.setRoverCoordinate(rovers(i),target(1),target(2),target(3));
        end
    end
    
    % Main loop
    while 1
        % start recording time
        tic;
        
        % read data from rover
        [returnCode,rovers(2).detected,rovers(2).dPoints] = rc.getLaserReading(rovers(2),sim.simx_opmode_buffer);
        [returnCode,rovers(2).position] = rc.getRoverPos(rovers(2),sim.simx_opmode_buffer);
        [returnCode,rovers(2).orientation] = rc.getRoverOri(rovers(2),sim.simx_opmode_buffer);
        
        % send current status to host
        msg = rovers(2).encapData();
        disp(msg);
        
        % check the difference between current position and target
        diff = rovers(2).getTargetDiff();
        if (diff(1) < 0.05) && (diff(2) < 1)
            break;
        end
        
        % pause by sampling rate and elapsed time
        timeElapsed = toc;
        pause(1/samplingRate - timeElapsed);
    end
    
    % clean up rovers
    for i = 1:roverCount
        rc.stop(rovers(i));
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

sim.delete(); % call the destructor 