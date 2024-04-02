data1 = readtable("millerkeith2018data1.csv");
data2 = readtable("millerkeith2018data2.csv");
data1 = sortrows(data1);
lat = data1(:,3)
lon = data1(:,2)

%https://www.kaggle.com/datasets/mrmorj/wind-plant-data

figure(1); clf
worldmap USA
contourfm(lat,lon, data1(:,6)','linecolor','none');
colorbar
geoshow('landareas.shp','FaceColor','black')
title("Net Energy Generation")