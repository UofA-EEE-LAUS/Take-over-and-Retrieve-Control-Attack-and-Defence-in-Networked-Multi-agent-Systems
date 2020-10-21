% FYP7331
% UDP_test.m
% By Moyang Feng
% An example of multiple UDP hosts on different ports

% echoudp('off');
% echoudp('on',4012);

u1 = udp('127.0.0.1','RemotePort',4012,'LocalHost','127.0.0.1','LocalPort',5011);
u2 = udp('127.0.0.1','RemotePort',5011,'LocalHost','127.0.0.1','LocalPort',4012);
% u1.EnablePortSharing = 'on';
% u2.EnablePortSharing = 'on';

fopen(u1);
fopen(u2);

fwrite(u1,65:74);
A = fread(u2,10);
disp(A);

fwrite(u2,75:84);
B = fread(u1,10);
disp(B);

pause(5);

% echoudp('off');

fclose(u1);
fclose(u2);
delete(u1);
delete(u2);