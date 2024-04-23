%% Read in Data
%Sofie's paths
addpath("/Users/sofiautoft/earth science/final-project-sofie-lindsay-annie/archive (2)")
addpath('/Users/sofiautoft/earth science/final-project-sofie-lindsay-annie/adaptor.mars.internal-1712091086.6350465-17961-1-b757f363-512e-4861-a1c6-ff13d691e2c8')

%reading in data on power plants
plant_data = readtable("millerkeith2018data1.csv");
%reading in data to match the individual wind turbines to the power plants
turbine_data = readtable("millerkeith2018data2.csv");
%reading in wind speed data
filename = 'wind2018.nc'
ncdisp(filename);
%reading in mechanics data
mechanics_data = readtable("uswtdb.csv");

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
windComponents = sqrt((windu .* windu) + (windv .* windv));
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

%% Compare Wind to Generation

%extract wind speed at each plant location
windSpeed = NaN(430, 12);
for i = 1:430
    diff_lat = abs(plantLat(i) - windLat);
    diff_lon = abs(plantLon(i) - windLon);
    min_lon = min(diff_lon);
    min_lat = min(diff_lat);
    indlon = find(diff_lon == min_lon);
    indlat = find(diff_lat == min_lat);
    indlon = indlon(1);
    indlat = indlat(1);
    windSpeed(i,:) = totalWindSpeed(indlat, indlon,:);
end

%find mean wind speed
meanWS = mean(windSpeed, 2);
windSpeed = [windSpeed meanWS];

%find number of turbines
numTurbines = NaN(430, 1);
for i = 1:430
    plantCode = table2array(plant_data(i, 1));
    turbineCodes = table2array(turbine_data(:, 4));
    numTurbines(i) = length(find(turbineCodes == plantCode));
end

dataTable = [plantLat plantLon netgen windSpeed numTurbines];
%colnames = {"Latitude", "Longitude", "NetGen", "WS JAN", "WS FEB", "WS MAR", "WS APR", "WS MAY", "WS JUN", "WS JUL", "WS AUG", "WS SEPT", "WS OCT", "WS NOV", "WS DEC", "meanWS", "numTurbines"};
%c = array2table(dataTable);
%c.Properties.VariableNames = colnames;

%single Turbine
turbgen = dataTable(:, 3)./ dataTable(:, 17);
modelInfo = [dataTable(:, 16) turbgen];
%% Linear Regression for TurbGen & WS
modelTable = array2table(modelInfo);
modelTable2 = rmmissing(modelTable);
X = table2array(modelTable2(:, 1));
y = table2array(modelTable2(:, 2));
model = fitrsvm(X, y)
yPred = predict(model, X);

%% Plot relationship between TurbGen & WS
figure(4); clf
plot(X, y, 'o', X, yPred, "x");
xlabel("Annual Mean Wind Speed");
ylabel("Power Generation for Individual Turbines");
legend();
%% Linear Regression for NetGen & Capacity
% modelTable = array2table(modelInfo);
% modelTable2 = rmmissing(modelTable);
% X = table2array(modelTable2(:, 1));
% y = table2array(modelTable2(:, 2));
X = capacity;
y = netgen;
model = fitlm(X, y, "Intercept", false)
yPred = predict(model, X);

%% Plot relationship between NetGen & Capacity
figure(4); clf
plot(X, y, 'o', X, yPred, '--');
xlabel("Installed Capacity");
ylabel("Net Generation");
legend();
%% Find Max Wind Speed
maxWS = max(dataTable(:,16));
row = find(dataTable(:, 16) == maxWS);
indices = dataTable(row, 1:2);
idxLat = indices(1);
idxLon = indices(2);

%% Plot Max Wind Speed Location
figure(5); clf
usamap conus
geoshow('landareas.shp','FaceColor','#77AC30')
plotm(idxLat,idxLon,'m.','MarkerSize',15)

%% Mechanics

mechanics_rd = table2array(mechanics_data(:, 16));
mechanics_hh = table2array(mechanics_data(:, 17));
mechanics_codes = table2array(mechanics_data(:, 5));
plantCodes = table2array(plant_data(:, 1));

mech_rd = NaN(length(plantCodes),1);
mech_hh = NaN(length(plantCodes),1);

for i = 1:length(plantCodes)
    index = find(plantCodes(i) == mechanics_codes);
    mech_rd(i) = nanmean(mechanics_rd(index));
    mech_hh(i) = nanmean(mechanics_hh(index));
end

finalTable = [plantLat plantLon netgen windSpeed numTurbines mech_rd mech_hh];

%% Regression
X = [meanWS, mech_rd, mech_hh];
model = fitrsvm(X, netgen)
yPred = predict(model, netgen);

%% Plot relationship
figure(6); clf
scatter(mech_rd, meanWS);
