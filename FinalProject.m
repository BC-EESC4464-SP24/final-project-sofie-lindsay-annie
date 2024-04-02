
addpath("/Users/lgilton/Documents/GitHub/final-project-sofie-lindsay-annie/archive (2)")
data1 = readtable("millerkeith2018data1.csv");
data2 = readtable("millerkeith2018data2.csv");
filename = 'data.nc'
ncdisp(filename);

windu = ncread(filename,'u10');

windv = ncread(filename,'v10');

totalwindspeed = sqrt((windu .* windu) + (windv .* windv));

% data1 = sortrows(data1);
lat = table2array(data1(:,3));
lon = table2array(data1(:,2));
netgen = table2array(data1(:,6));
%https://www.kaggle.com/datasets/mrmorj/wind-plant-data

% surf(lat,lon,totalwindspeed(:,:,1));

% figure(1); clf
% usamap conus
% geoshow('landareas.shp','FaceColor','#77AC30')
% plotm(lat,lon,'m.','MarkerSize',15)
% scatterm(lat,lon,netgen)

% % geoplot(data1,"Latitude","Longitude")
% % hold off
% % contourfm(lat, lon);
% % colorbar