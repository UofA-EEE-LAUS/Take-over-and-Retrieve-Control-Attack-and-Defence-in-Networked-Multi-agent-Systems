function state=hostsent(hostport,input)%Ô­À´½Ðsent
%add a counter to input


%store the msg in a variable called history


%send msg to agent, and report if successful
state=fwrite(hostport,msg);


end

function state=feedback(msgcounter)
%delete the related msg stored in history

end
function state=resent(msgID,agent_port)
%based on input msgcounter,find the relate msg in history


%send the msg to the new agent_port
end

function state=udpwrite(targetport,msg)
%used to write a msg to a target udp port
fwrite(targetport,msg);
disp('message sent successful');
state=1;
end