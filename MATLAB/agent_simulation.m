 % initialisation
sim=remApi('remoteApi');
sim.simxFinish(-1); % close all opened connections
clientID=sim.simxStart('127.0.0.1',19997,true,true,5000,5);  

rc = roverControl(sim,clientID);
disp('Connected to client.');
% start simulation
sim.simxStartSimulation(clientID,sim.simx_opmode_oneshot);
% set the number of rovers in the simulation
roverCount = 3;

% initiate rovers
rovers = rc.initRovers(roverCount);
[returnCode,detectionState,detectedPoint] = rc.getLaserReading(rovers(2),sim.simx_opmode_streaming);
%create a loop to accept command from host
while 1
    msg=char(rovers(1).readUDP()');
    if msg==0
        break;
    end
%sent msg, like coordinate back to host (more than feedback and reset) 

%implement a stop command from the host to turn off the system
end

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