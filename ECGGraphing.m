data = readtable('ECG A.csv');
% data = readtable('ECG B.csv');
% data = readtable('ECG C.csv');
% data = readtable('ECG D.csv');

data = table2array(data).';
time = data(1,:);
ECG = data(2,:);

plot(time,ECG)