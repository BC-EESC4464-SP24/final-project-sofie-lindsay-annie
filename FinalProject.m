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

%read in wind components
windu = ncread(filename,'u10');
windv = ncread(filename,'v10');
%% Calculate wind speed
%lon x lat x day
windComponents = sqrt((windu .* windu) + (windv .* windv));
windLat = double(ncread(filename,'latitude'));
windLon = double(ncread(filename,'longitude'));

%need to switch lat/lon
totalWindSpeed = permute(windComponents, [2 1 3]);

%% Extract lat, lon, netgen, & capacity
plantLat = table2array(plant_data(:,3));
plantLon = table2array(plant_data(:,2));
netgen = table2array(plant_data(:,6));
capacity = table2array(plant_data(:,4));

%% Create maps
figure(1); clf
usamap conus
geoshow('landareas.shp')
%plot windspeed as background
step = 50;
bar = colorbar;
title(bar, "Wind Speed (m/s)")
contourfm(windLat(1:step:end), windLon(1:step:end),totalWindSpeed(1:step:end,1:step:end,1), 10)
hold on
plotm(plantLat,plantLon,'y.','MarkerSize',10)
hold on
plotm(idxLat,idxLon,'r.','MarkerSize',15)
title("Plant Locations and Wind Speed (10m)")
%% plot net generation at each location by size
figure(2); clf
usamap conus
geoshow('landareas.shp','FaceColor','#77AC30')
scatterm(plantLat,plantLon,netgen,'filled')

%or plot markers in different colors according to generation

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

%% Mechanics

mechanics_rd = table2array(mechanics_data(:, 16));
mechanics_hh = table2array(mechanics_data(:, 17));
mechanics_rsa = table2array(mechanics_data(:, 18));
mechanics_codes = table2array(mechanics_data(:, 5));
plantCodes = table2array(plant_data(:, 1));

mech_rd = NaN(length(plantCodes),1);
mech_hh = NaN(length(plantCodes),1);

for i = 1:length(plantCodes)
    index = find(plantCodes(i) == mechanics_codes);
    mech_rd(i) = nanmean(mechanics_rd(index));
    mech_hh(i) = nanmean(mechanics_hh(index));
    mech_rsa(i) = nanmean(mechanics_rsa(index));
end

%% meanWS correction
correctMeanWS = meanWS .* (mech_hh/10).^0.143;

figure(6); clf
scatter(meanWS, correctMeanWS)
hold on
plot(meanWS, meanWS)
xlabel("Actual meanWS");
ylabel("correctMeanWS");

%% Linear Regression for TurbGen & WS
%single Turbine
turbgen = dataTable(:, 3)./ dataTable(:, 17);
modelInfo = [dataTable(:, 16) turbgen];
modelTable = array2table(modelInfo);
modelTable2 = rmmissing(modelTable);
MWS = table2array(modelTable2(:, 1));
Powergen = table2array(modelTable2(:, 2));
model = fitrsvm(MWS, Powergen)
yPred = predict(model, MWS);

%% Plot relationship between TurbGen & WS
figure(4); clf
plot(MWS, Powergen, 'o', MWS, yPred, "x");
xlabel("Annual Mean Wind Speed");
ylabel("Power Generation for Individual Turbines");
legend();
%% Linear Regression for NetGen & Capacity
model = fitlm(capacity, netgen, "Intercept", false)
yPred = predict(model, capacity);

%% Plot relationship between NetGen & Capacity
figure(4); clf
plot(capacity, netgen, 'o', capacity, yPred, '--');
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

%% Regression
variables = [correctMeanWS, mech_rd, mech_hh netgen];
table = rmmissing(variables);
predictors = table(:, 1:3);
y = table(:, 4);
NN = fitrnet(predictors, y, 'Standardize',true, "Activations", 'relu',  'InitialStepSize','auto', 'LayerSizes',[115 100 75 50 25], 'Lambda',1e-4)
yPred = predict(NN, predictors);

%% Plot relationship
figure(7); clf
scatter(y, yPred)
hold on
plot(y,y)
xlabel("Actual");
ylabel("Prediction");

%% Theoretical Power (Equation)
%standard density of air = 1.225
meanWScubed = meanWS.^3;
theoretical_power = (1/2 * 1.225 * mech_rsa') .* meanWScubed;
figure(8); clf
scatter(netgen, theoretical_power)
xlabel("Actual");
ylabel("Prediction");
