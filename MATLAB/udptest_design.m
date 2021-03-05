%initialize port number
host=4012;
agent=5011;
%initialize udp channel
u1 = udp('127.0.0.1','RemotePort',host,'LocalHost','127.0.0.1','LocalPort',agent);
u2 = udp('127.0.0.1','RemotePort',agent,'LocalHost','127.0.0.1','LocalPort',host);

fopen(u1);
fopen(u2);

u3 = udp('127.0.0.1','RemotePort',host+1,'LocalHost','127.0.0.1','LocalPort',agent+1);
u4 = udp('127.0.0.1','RemotePort',agent+1,'LocalHost','127.0.0.1','LocalPort',host+1);

fopen(u3);
fopen(u4);

u5 = udp('127.0.0.1','RemotePort',host+2,'LocalHost','127.0.0.1','LocalPort',agent+2);
u6 = udp('127.0.0.1','RemotePort',agent+2,'LocalHost','127.0.0.1','LocalPort',host+2);

fopen(u5);
fopen(u6);

%regular send msg
msg=[1 2 3];
%host sent a msg with ID 001
% if (sent(msg))
%     disp('msg sent');
% end
fwrite(u1,msg);
fwrite(u3,msg);
fwrite(u5,msg);


%agent side receive the msg
% A=receive(agent);
A=fread(u2);
A1=fread(u4);
A2=fread(u6);
%feedback the msg counter to the host
fwrite(u2,A(1:3));
disp(A');

B=fread(u1);
disp(B');

c=isequal(A,A1);
%this only consider 1 port failure, which assume only one port is attacked
%at once
if c
   disp('transmit successful');
   receive_msg=A;
elseif iseuqal(A2,A) 
    disp('port u3 is under attack, transimit successful');
    reset(u3,u4);
    receive_msg=A;
elseif isequal(A2,A1)
    disp('port u1 is under attack, transimit successsful');
    reset(u1,u2);
    receive_msg=A1;
else 
    %reset all port
end

%host side receive the feedback msg
% while (ture)
%     if feedback_msg==fread(u1)
%         feedback(feedback_msg);
%     else 
%         break;
%     end
% end
    

fclose(u1);
fclose(u2);
delete(u1);
delete(u2);

fclose(u3);
fclose(u4);
delete(u3);
delete(u4);