% Flood attack between the host and an agent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%echoudp('off');

%echoudp('on',4012);
%get the IP we are attacking
ip = '127.0.0.1';

%get thep port we direct to attack
port = 4012;

%Creates a udp object
u = udp(ip,'RemotePort',port,'LocalPort',4013);

u.EnablePortSharing = 'on';

fopen(u);

%Use infinitely loops to send lots of packets to the port till the program
%is exited
i=1;
while 1
   packet = randi(10000,1,100);
   fwrite(u,packet);
   disp(i);
   i = i+1;
   %disp(packet);
end

fclose(u);
echoudp('off');