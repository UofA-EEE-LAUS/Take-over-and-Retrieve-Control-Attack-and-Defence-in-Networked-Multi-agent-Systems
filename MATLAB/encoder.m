function array= encoder(string, ra)
l = strlength(string);
array = zeros(1,l);
s = char(string);
for i = 1:l
    array(i) = abs(s(i))*ra + ra;
end
end