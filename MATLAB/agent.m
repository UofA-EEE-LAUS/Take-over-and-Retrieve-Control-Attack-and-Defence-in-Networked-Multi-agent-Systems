global receive_list %used to store the received msgID
function msg=receive(agent_port)
global receive_list;
%read msg from agent_port
msg=fread(agent_port);


%get the msg ID(msgcounter) from the msg
msgID=bin2dec(msg(1:3));
%check the msgID is expected.
if (find(msgID,receive_list))
    disp('already received before');
    %go check if this is a replay attack
else
    receive_list=[receive_list msgID];
%feedback the msgID to the agent
    feedbackID=[65 msgID];
    udpwrite(agent_port,feedbackID);
end
end
function state=reset_port(agent_port)
%reset the port
fclose(agent_port);
delete(agent_port);
agent=agent+1;
u2= udp('127.0.0.1','RemotePort',agent,'LocalHost','127.0.0.1','LocalPort',host);
fopen(u2);
%sent the reset ID to the agent 
end

