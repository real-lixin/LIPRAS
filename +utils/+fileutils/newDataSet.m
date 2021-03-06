% Imports new data.
function [data, filename, datapath] = newDataSet(datapath, filename)
%   DATAPATH is the folder to initially open.
try
%     PrefFile=fopen('Preference File.txt','r');
%     data_path=fscanf(PrefFile,'%c');
%     data_path(end)=[]; % method above adds a white space at the last character that messes with import
%     fclose(PrefFile);
catch
%     data_path=cd;
end

% allowedFiles = {'*.csv; *.txt; *.xy; *.fxye; *.dat; *.xrdml; *.chi; *.spr'}; % underdevelopment
if ispc
allowedFiles = {'*.xy; *.xye; *.xrdml; *.asc; *.ras; *.chi; *.fxye;  *.csv; *.xls; *.xlsx'};
elseif ismac
    allowedFiles = {'*.xy; *.xye; *.xrdml; *.asc; *.ras; *.chi; *.fxye; *.xls; *.xlsx'};
else % Defaults to Windows
allowedFiles = {'*.xy; *.xye; *.xrdml; *.asc; *.ras; *.chi; *.fxye;  *.csv; *.xls; *.xlsx'};

end

title = 'Select Diffraction Pattern to Fit';
if nargin < 1    
    filterspec = allowedFiles;
else
    filterspec = fullfile(datapath,allowedFiles{1});
end

if nargin < 2
    [filename, datapath] = uigetfile(filterspec, title, 'MultiSelect', 'on');
end

if ~isequal(filename, 0)
    data = readNewDataFile(filename, datapath);
    
else
    data = [];
end
end


function data = readNewDataFile(filename, path)
% DATA - First row is the 2theta, second row and above are the intensities
if isa(filename,'char')
    filename = {filename};
end

% preallocate the structure array 
[~,~,ext] = fileparts(filename{1});
data = struct('two_theta',[],'data_fit',[],'KAlpha1',[],'KAlpha2',[],...
    'kBeta',[],'RKa1Ka2',[],'Temperature',[],'Wavelength',[],'ext',ext);

% iterate through all files
for i=1:length(filename)
    [~,~,ext] = fileparts(filename{i});

    fullFileName = strcat(path, filename{i});
    fid = fopen(fullFileName, 'r');
    
    if strcmpi(ext, '.csv')|| strcmpi(ext, '.xls')||strcmpi(ext, '.xlsx') % For MAC, .csv should not be selected
        datatemp = readSpreadsheet(fullFileName);
    elseif strcmpi(ext, '.txt')

        datatemp = readTXT(i,fullFileName);
    elseif strcmpi(ext, '.xy')||strcmpi(ext, '.xye')
        datatemp = readFile(fid, ext);
    elseif strcmpi(ext, '.fxye')
        datatemp = readFXYE(i,fullFileName);
        try
        data.Temperature=datatemp.temperature;
        data.Wavelength=datatemp.wave;
        catch
        end
    elseif strcmpi(ext, '.chi')
        datatemp = readFile(fid, ext);
        datatemp.error=sqrt(datatemp.data_fit);

    elseif strcmpi(ext, '.dat')
        datatemp = readFile(fid, ext);
    elseif strcmpi(ext, '.xrdml')
        datatemp = parseXRDML(fullFileName);
    elseif strcmpi(ext,'.ras')
                datatemp = utils.fileutils.Rigaku_Read(fullFileName, ext);
    elseif strcmpi(ext,'.asc')
                datatemp = utils.fileutils.Rigaku_Read(fullFileName, ext);
    end
    
    if strcmpi(ext, '.xrdml')
        if size(datatemp.two_theta,1)~=1 % this means xrdml contains multiple scans
        data.two_theta = datatemp.two_theta;
        data.two_theta = mat2cell(data.two_theta,ones(size(data.two_theta,1),1));
        data.data_fit=datatemp.data_fit;
        data.temperature(i,:)=25; % needs work, 2-26-2017
        data.KAlpha1(i,:)=datatemp.KAlpha1;
        data.KAlpha2(i,:)=datatemp.KAlpha2;
        data.RKa1Ka2(i,:)=datatemp.RKa1Ka2;
        data.ext = ext;
        data.error=sqrt(datatemp.data_fit);
        data.error= mat2cell(data.error,ones(size(data.error,1),1));
        data.data_fit= mat2cell(data.data_fit,ones(size(data.data_fit,1),1));
        data.scanType{i}=datatemp.scanType; % for when XRDML contains multiple scans in one file all get same scanType
        if length(data.two_theta)~=length(data.scanType)
            tCell=cell(1,length(data.two_theta));tCell(:)=data.scanType;
            data.scanType=tCell;
        end
   
        else % for XRDML that are single scans
        data.two_theta{i} = datatemp.two_theta;
        data.data_fit{i}=datatemp.data_fit;
        data.temperature(i,:)=datatemp.Temperature;
        data.KAlpha1(i,:)=datatemp.KAlpha1;
        data.KAlpha2(i,:)=datatemp.KAlpha2;
        data.RKa1Ka2(i,:)=datatemp.RKa1Ka2;
        data.ext = ext;
        data.error{i}=sqrt(datatemp.data_fit);
        data.scanType{i}=datatemp.scanType;
        end
    elseif strcmpi(ext,'.asc')||strcmpi(ext,'.ras')
        data.two_theta{i} = datatemp.two_theta;
        data.data_fit{i} = datatemp.data_fit;
        data.KAlpha1(i,:)=datatemp.KAlpha1;
        data.KAlpha2(i,:)=datatemp.KAlpha2;
        data.error{i}=sqrt(datatemp.data_fit);
        data.scanType{i}=datatemp.scanType;
        data.ext = ext;

    else
        data.two_theta{i} = datatemp.two_theta;
        data.data_fit{i} = datatemp.data_fit;
        try
        data.error{i}=datatemp.error;
        catch % in cases where error is not specified upon read
        data.error{i}=sqrt(data.data_fit{i});
        end

    end    
    
    fclose(fid);
end
end


function data = readSpreadsheet(filename)
if contains(filename,'csv')
    temp=table2array(readtable(filename));
else
    temp = xlsread(filename);
end
% Method for reading of data that does not start with numerial
% twotheta and intensity
cc=isnan(temp(:,1)); % checks if any NaN were read in

% Sums the results of cc if after summing 5 rows and the sum is 0, then it
%   re-shapes the data read in with xlsread
for i=1:length(cc)
    s= sum(cc(i:i+5),1);
    if s==0
        p=i;
        break
    end
end

% reshapes based on for loop results
temp = temp(p:end,:);

% now takes the first three columns of intesity and 2-theta and transpose
try
temp = temp(:,1:3)';
catch
    temp = temp(:,1:2)';
end

data.two_theta = temp(1,:);
data.data_fit = temp(2,:);
try
data.error=temp(3,:);
catch
end
end


function data = readFile(fid, ext) 
data = struct('two_theta',[],'data_fit',[],'KAlpha1',[],'KAlpha2',[],...
    'kBeta',[],'RKa1Ka2',[],'Temperature',[], 'ext',ext);
if strcmp(ext, '.xy')
    temp = fscanf(fid,'%f',[2 ,inf]);
elseif strcmp(ext,'.xye')
    temp = fscanf(fid,'%f',[3 inf]);
    data.error=temp(3,:);
elseif strcmp( ext, '.fxye')
    temp = fscanf(fid,'%f',[3 ,inf]);
    temp(1,:) = temp(1,:) ./ 100;
elseif strcmp( ext, '.chi')
    fgetl(fid);fgetl(fid);fgetl(fid);fgetl(fid);
    temp = fscanf(fid,'%f',[2 ,inf]);
else
    temp = fscanf(fid,'%f',[2 ,inf]);
end
data.two_theta = temp(1,:);
data.data_fit = temp(2,:);
end


function data=readFXYE(fileIndex,inFile)
fid = fopen(inFile,'r');
index = 0;
done = 0;

while done == 0
    line = fgetl(fid);
    a = strsplit(line, ' ');
    try
        if strcmp(a(2),'Temp')
            temp = sprintf('%s*', cell2mat(a(5)));
            Temperature(fileIndex) = sscanf(temp, '%f*');
        
        elseif strcmp(a(3),'wavelength')
            wave = sprintf('%s*', cell2mat(a(5)));
            Wavelength(fileIndex) = sscanf(wave, '%f*');
        end
        if strcmp(a(1), '')
            S = sprintf('%s*', cell2mat(a(2)));
        else
            S = sprintf('%s*', cell2mat(a(1)));
        end
        N = sscanf(S, '%f*');
        if isempty(N)
            
        elseif isa(N, 'double')
            done = 1;
        end
    catch
        
    end
    
    index = index + 1;
end

dline=str2num(line);
temp1=transpose(fscanf(fid,'%f',[3 inf]));%opens the file listed above and obtains data in all 5 columns
temp1=[dline;temp1];
data.two_theta = temp1(:,1)'./100; % divides by 100 since units in fxye are in centi-degrees
data.data_fit = temp1(:,2)';
data.error=temp1(:,3)'; % will become weights for fit for diffraction patterns

try
data.temperature=Temperature;
data.wave=Wavelength;
catch
end

fclose(fid);

end

function data=readTXT(fileIndex,inFile)
% Not finished 2-26-2017
fid = fopen(inFile,'r');
index = 0;
done = 0;
n=1;

if fileIndex==1;
dat=textscan(fid,'%s');
fclose(fid);


for j=1:size(dat{1},1)
    data=str2double(cell2mat(dat{:}(j)));
test(j)=isnan(data);


end


for i=1:length(test)
    s= sum(test(i:i+5),1);
    if s==0
        p=i;
        break
    end
end


temp1=data(1,p:end);


else 
    
    for oo=1:p
        v=fgetl(fid);
    end
    
    temp1=transpose(fscanf(fid,'%f',[3 inf]));%opens the file listed above and obtains data in all 5 columns
    fclose(fid);
    
    
end






data.two_theta = temp1(:,1)./100; % divides by 100 since units in fxye are in centi-degrees
data.data_fit = temp1(:,2);
data.temperature=Temperature;
data.wave=Wavelength;


fclose(fid)

end


function data = parseXRDML(filename)
%PARSEXRDML reads an xml file with the extension .xrdml. If there are multiple scans in one file,
%this function assumes that the 2theta range is the same for all scans.



dom = xmlread(filename);

intensityElements = dom.getElementsByTagName('intensities');
ilen = textscan(char(intensityElements.item(0).getTextContent),'%f');
ilen = length(ilen{1});
intensity = zeros(intensityElements.getLength, ilen);
temperature = zeros(1,intensityElements.getLength);

for i=1:intensityElements.getLength 
    % Get the intensity values for each scan
    item = intensityElements.item(i-1);
    intensVal = textscan(char(item.getTextContent), '%f');
    intensity(i,:) = intensVal{1}';
    
    % Get the average temperature for each scan
    tempItem = dom.getElementsByTagName('nonAmbientPoints').item(0);
    if isempty(tempItem)
        temperature(i) = 25;
    else 
        temp = textscan(char(tempItem.getTextContent),'%f');
        temperature(i) = mean(temp{1}) - 273.15;
    end
end

% Get the two theta values for each intensity
listPosElement = dom.getElementsByTagName('listPositions').item(0);
if isempty(listPosElement)
    % Assuming the first item under the element 'positions' has the attribute '2Theta'
    scanType=dom.getElementsByTagName('scan').item(0).getAttribute('scanAxis');
    if  strcmp(scanType, 'Gonio') || strcmp(scanType, '2Theta') 
        pos2thetaElement = dom.getElementsByTagName('positions').item(0);
    elseif scanType=='2Theta-Omega' 
        pos2thetaElement = dom.getElementsByTagName('positions').item(0);
    elseif scanType=='Phi' 
        pos2thetaElement = dom.getElementsByTagName('positions').item(2);
    elseif scanType=='Chi' 
        pos2thetaElement = dom.getElementsByTagName('positions').item(3);
    else
        pos2thetaElement = dom.getElementsByTagName('positions').item(1);
    end
    startPosElement = pos2thetaElement.getElementsByTagName('startPosition').item(0);
    startPosValue = str2double(startPosElement.getTextContent);
    endPosElement = pos2thetaElement.getElementsByTagName('endPosition').item(0);
    endPosValue = str2double(endPosElement.getTextContent);
    step = (endPosValue - startPosValue) / (ilen-1);
    listPosValue = (startPosValue:step:endPosValue);
else
    listPosValue = textscan(char(listPosElement.getTextContent), '%f');
    listPosValue = listPosValue{1}';
end

twotheta = zeros(intensityElements.getLength,ilen);
for i=1:intensityElements.getLength
    twotheta(i,:) = listPosValue;
end
    
% Get KAlpha1, KAlpha2, kBeta, and RKa1Ka2
ka1 = str2double(dom.getElementsByTagName('kAlpha1').item(0).getTextContent);
ka2 = str2double(dom.getElementsByTagName('kAlpha2').item(0).getTextContent);
kbeta = str2double(dom.getElementsByTagName('kBeta').item(0).getTextContent);
ratio = str2double(dom.getElementsByTagName('ratioKAlpha2KAlpha1').item(0).getTextContent);

try 
    scanType; 
catch
    scanType=java.lang.String('Gonio');
end
% Save values into a struct
data = struct('KAlpha1',ka1,'KAlpha2',ka2,'kBeta',kbeta,'RKa1Ka2',ratio,'two_theta',twotheta,...
    'data_fit',intensity,'Temperature',temperature,'ext','','scanType',scanType);
end