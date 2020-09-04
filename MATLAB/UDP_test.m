% FYP7331
% UDP_test.m
% By Moyang Feng
% An example of multiple UDP hosts on different ports

echoudp('off');
echoudp('on',4012);

u1 = udp('127.0.0.1','RemotePort',4012,'LocalPort',5011);
u2 = udp('127.0.0.1','RemotePort',4012,'LocalPort',5012);
u1.EnablePortSharing = 'on';
u2.EnablePortSharing = 'on';

fopen(u1);
fopen(u2);

fwrite(u1,65:74);
A = fread(u1,10);

fwrite(u2,65:74);
B = fread(u2,10);

pause (10); 

echoudp('off');

fclose(u1);
fclose(u2);
delete(u1);
delete(u2);