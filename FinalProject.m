%% Read in Data
%Sofie's paths
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

%% Extract lat, lon, netgen, & capacity
plantLat = table2array(plant_data(:,3));
plantLon = table2array(plant_data(:,2));
netgen = table2array(plant_data(:,6));
capacity = table2array(plant_data(:,4));

%% Create maps
figure(1); clf
usamap conus
geoshow('landareas.shp','FaceColor','#77AC30')
%plot windspeed as background
step = 50;
colorbar;
contourfm(windLat(1:step:end), windLon(1:step:end),totalWindSpeed(1:step:end,1:step:end,1), 25)

%% plot locations
figure(2); clf
usamap conus
geoshow('landareas.shp','FaceColor','#77AC30')
plotm(plantLat,plantLon,'m.','MarkerSize',15)

% plot max wind speed point in a different color (?)

%plot net generation at each location by size
%scatterm(plantLat,plantLon,netgen,'filled')

%plot markers in different colors according to generation

%% Ratio of Capacity and Generation
ratio = netgen ./ capacity;
idxMaxRatio = find(ratio == max(ratio));
ratioTable = [plantLat plantLon ratio];
maxLocation = ratioTable(215, :);

%% Plot Ratio
figure(3); clf
scatter3(plantLat, plantLon, ratio)
xlabel("Latitude")
ylabel("Longitude")
zlabel("Ratio")

%% Max Wind Speed
meanWS = mean(totalWindSpeed, 3);
actualMaxWS = max(meanWS, [], "all");
MaxWS = meanWS == actualMaxWS;
[row, col] = find(MaxWS);
idxLat = windLat(row);
idxLon = windLon(col);
months = totalWindSpeed(row, col, :);

%% Plot Max Wind Speed Location
figure(4); clf
usamap conus
geoshow('landareas.shp','FaceColor','#77AC30')
plotm(idxLat,idxLon,'m.','MarkerSize',15)

%% Compare Wind to Generation

%extract wind speed at each plant location
windSpeed = NaN(430, 1);
for i = 1:430
    diff_lat = abs(plantLat(i) - windLat);
    diff_lon = abs(plantLon(i) - windLon);
    min_lon = min(diff_lon);
    min_lat = min(diff_lat);
    indlon = find(diff_lon == min_lon);
    indlat = find(diff_lat == min_lat);
    indlon = indlon(1);
    indlat = indlat(1);
    windSpeed(i) = totalWindSpeed(indlat, indlon);
end

%find number of turbines
numTurbines = NaN(430, 1);
for i = 1:430
    plantCode = table2array(plant_data(i, 1));
    turbineCodes = table2array(turbine_data(:, 4));
    numTurbines(i) = length(find(turbineCodes == plantCode));
end

dataTable = [plantLat plantLon netgen windSpeed numTurbines];
