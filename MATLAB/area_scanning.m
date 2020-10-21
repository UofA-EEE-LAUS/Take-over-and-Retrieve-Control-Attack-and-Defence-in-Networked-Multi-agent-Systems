% FYP7331
% agent_test.m
% By Moyang Feng
% Example of roverControl APIs with connection to VREP

clear all;
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
    [returnCode,detectionState,detectedPoint] = rc.getLaserReading(rovers(1),sim.simx_opmode_streaming);
    
    % get position and orientation of rover
    [returnCode,rovers(1).position] = rc.getRoverPos(rovers(1),sim.simx_opmode_streaming);
    [returnCode,rovers(1).orientation] = rc.getRoverOri(rovers(1),sim.simx_opmode_streaming);
    
    % set target for rovers
    % [x1 y1 angle1 
    %  x2 y2 angle2 
    %  x3 y3 angle3]
    roverTargets = [-0.25 0.75 150 
                    -2.25 0.75 150 
                     1.75 0.75 150];
    for i = 1:roverCount
        rovers(i).target = roverTargets(i,:);
    end
    returnCode = rc.setRoverTargets(rovers,roverTargets);
    
    % set the sampling rate in Hz
    samplingRate = 3;
    
    figure;
    hold on;
    grid on;
    xlim([-5 5]);
    ylim([-5 5]);
    title('2-D Area Scan')
    xlabel('x');
    ylabel('y');
    
    % Main loop
    while 1
        % start recording time
        tic;
        
        % read data from rover
        [returnCode,detectionState,detectedPoint] = rc.getLaserReading(rovers(1),sim.simx_opmode_buffer);
        [returnCode,rovers(1).position] = rc.getRoverPos(rovers(1),sim.simx_opmode_buffer);
        [returnCode,rovers(1).orientation] = rc.getRoverOri(rovers(1),sim.simx_opmode_buffer);
        
        plot(rovers(1).position(1),rovers(1).position(2),'b-o');
        if detectionState
            scannedPoint = rc.laser2World(detectedPoint,rovers(1).position,rovers(1).orientation);
            plot(scannedPoint(1),scannedPoint(2),'r-o');
        end
        
        % check the difference between current position and target
        diff = rovers(1).getTargetDiff();
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