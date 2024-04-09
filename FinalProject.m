%% Read in Data
addpath("/Users/sofiautoft/earth science/final-project-sofie-lindsay-annie/archive (2)")
addpath('/Users/sofiautoft/earth science/final-project-sofie-lindsay-annie/adaptor.mars.internal-1712091086.6350465-17961-1-b757f363-512e-4861-a1c6-ff13d691e2c8')
%reading in data on power plants
plant_data = readtable("millerkeith2018data1.csv");
%reading in data to match the individual wind turbines to the power plants
turbine_data = readtable("millerkeith2018data2.csv");
%reading in wind speed data
filename = 'data.nc'
ncdisp(filename);

%DATA1
%Plant Code: used to link to electricity generation
%InstCapMWi: installed capacity (MW) from EIA Power Plants
%AreaKM2: total area of the wind plant
%NetGENe_2016_MWe:net electricity generation

%DATA2
%Plant Code: spatially matched wind power plant from data1

%read in wind components
windu = ncread(filename,'u10');
windv = ncread(filename,'v10');
%% Calculate wind speed
%lon x lat x day
windspeed = sqrt((windu .* windu) + (windv .* windv));
windLat = double(ncread(filename,'latitude'));
windLon = double(ncread(filename,'longitude'));

%need to switch lat/lon
totalWindSpeed = permute(windspeed, [2 1 3]);

%% Extract lat & lon
plantLat = table2array(plant_data(:,3));
plantLon = table2array(plant_data(:,2));
netgen = table2array(plant_data(:,6));

%% Create maps
figure(1); clf
usamap conus
geoshow('landareas.shp','FaceColor','#77AC30')
%plot windspeed as background
step = 20;
contourfm(windLat(1:step:end), windLon(1:step:end),totalWindSpeed(1:step:end,1:step:end,1),25)

%plot locations
%plotm(lat,lon,'m.','MarkerSize',15)

%plot net generation at each location by size
%scatterm(lat,lon,netgen,'filled')

%plot markers in different colors according to generation
