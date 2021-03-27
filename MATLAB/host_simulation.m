hostudp=host(4012,5010);        

figure;
    hold on;
    grid on;
    xlim([-5 5]);
    ylim([-5 5]);
    title('2-D Area Scan')
    xlabel('x');
    ylabel('y');
    
    %a loop with function to send command to host
    %and function to get feedback msg and coordinates
    while 1
        command=input("please enter command: ","s");
        if strcmp(command,'quit')
            %send command to stop the car
            break;
        end
        if strcmp(command,'msg')
           roverID=input("please enter the roverID: ");
           msg=input("please enter the message: ","s");
           hostudp.hostsent(roverID,msg);
        end
        
        %face chanllenge in how to run the input module and monitor the
        %host receiver concurrently
        state=hostudp.hostread();
    end
    
    hostudp.delete();