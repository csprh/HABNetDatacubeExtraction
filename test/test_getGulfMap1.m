clear all;
addpath('..');
thisOutput = '/Users/csprh/Dlaptop/MATLAB/MYCODE/HAB/WORK/HAB/CNNIms/florida/test/';
worldmap([23 30.42],[47.69 58])
%worldmap([-90 90],[-180 180])
land = shaperead('landareas.shp', 'UseGeoCoords', true);
%load coast
%plotm(lat,long)


geoshow(land, 'FaceColor', [0.15 0.5 0.15]);
[latitude, longitude] =  test_getLatLonArray(1, 0.5);

%plotm(latitude,longitude,'w+');

probTxtName = [thisOutput 'classesProbs.txt'];
latLonName = [thisOutput 'latLonList.txt'];
format long g

PfileID = fopen(probTxtName,'r');
LLfileID = fopen(latLonName,'r');
theseProbs = fscanf(PfileID,'Index = %d, Class = 0, Probability = %f ', [2,inf]);
theseLatLons = fscanf(LLfileID,'%f %f %f ', [3,inf]);

lenProbs = size(theseProbs,2);

for ii = 1: lenProbs
    thisInd = theseProbs(1,ii);
    thisProbs(ii) = theseProbs(2,ii);
    positionInd = find(theseLatLons(1,:)==thisInd, 1, 'first');
    thisLat(ii) = theseLatLons(2,positionInd);
    thisLon(ii) = theseLatLons(3,positionInd);
end


thisProbs = (thisProbs.^0.2);
[dummy ID]=sort(thisProbs);
colors=colormap(jet);
thisProbsM = max(thisProbs);

lcolors = size(colors,1);
thisProbsQ = 1-(((thisProbs./thisProbsM)));
%for i=1:length(thisProbs)
%    plotm(thisLat(i),thisLon(i),'+','Color',[1 thisProbsQ(i) thisProbsQ(i)] );
%end

[x, y] =  test_getLatLonArray(1, 0.2, 0);
z  = griddata(thisLat,thisLon,thisProbsQ, x, y,'v4');
%[zg,xg,yg] = gridfit(thisLat,thisLon,thisProbs,x,y,'tilesize',120,'overlap',0.25);

%plotm(thisLat,thisLon,'g+');
thisProbsQ = z;
thisProbsQ(thisProbsQ>1)=1;
thisProbsQ(thisProbsQ<0)=0;
for i=1:length(thisProbsQ);    
    plotm(x(i),y(i),'+','Color',[1 thisProbsQ(i) thisProbsQ(i)] ); 
end
geoshow(land, 'FaceColor', [0.15 0.5 0.15]);






