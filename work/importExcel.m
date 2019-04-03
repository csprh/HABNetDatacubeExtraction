[n,t] = xlsread('AlgalBloomRecords2002-18.xlsx');

data.latitude = n(:,5);
data.longitude = n(:,6);
data.area = n(:,7);
data.count2 = n(:,8);
data.salinity = str2double(t(:,9));
data.temperature = str2double(t(:,10));
date = t(2:end,2);

data.sample_date = datenum(datetime(date,'InputFormat','dd/MM/yyyy'));
data.proof_date= data.sample_date;

save('AbuDhabi_2002-2018-50k.mat', '-struct', 'data');

clear all