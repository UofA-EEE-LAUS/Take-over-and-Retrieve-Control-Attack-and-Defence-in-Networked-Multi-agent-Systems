function output= decoder(array, ra)
[n m]=size(array);
if  m<1
    output = -1;
    return 
end
s = '';
for i=1:m
    num = (array(i)-ra)/ra;
    s=[s,char(num)];
end
    output = string(s);
end