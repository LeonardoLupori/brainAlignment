clearvars, clc

% -------------------------------------------------------------------------
defaultFolder = 'D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET';
outputFolder = 'D:\PizzorussoLAB\proj_PNN-highFatDiet\RESULTS';
channel = 2;
pixelSize = 0.645;       % in micrometers
% -------------------------------------------------------------------------

%% Load all slices from a single XML info file (a mouse)

filter = [defaultFolder filesep '.xml'];
tit = 'Select an INFO XML file';
[file,path] = uigetfile(filter,tit);

if file ~= 0
    xml = [path filesep file];
    sliceArray = allSlicesFromXml(xml);
end

%% Diffuse fluorescence analysis

% Load the annotation volume
if ~exist('annotationVolume','var')
    load('annotationVolume.mat');
end

% Initialize variables for the global fluorescence of each slice
sliceName = cell(length(sliceArray),1);
sliceFluo = zeros(length(sliceArray),1);

% Analyzi the first slice in the array
[T, totFluo]  = sliceArray(1).quantifyDiffuse(annotationVolume,channel);
sliceName{1} = sliceArray(1).name;
sliceFluo(1) = totFluo;

% Analyze all the other slices
for i = 2:length(sliceArray)

    sliceName{i} = sliceArray(i).name;

    if sliceArray(i).valid == 0
        fprintf('Slice: "%s" flagged as not valid. Skipped quantification\n',sliceArray(i).name)
        continue
    end

    [T_toAdd, totFluo] = sliceArray(i).quantifyDiffuse(annotationVolume,channel);

    sliceFluo(i) = totFluo;

    temp = outerjoin(T,T_toAdd,'Keys','regionID','MergeKeys',true);
    areaIdx = contains(temp.Properties.VariableNames, 'areaPx');
    fluoIdx = contains(temp.Properties.VariableNames, 'diffFluo');

    area = sum(temp{:,areaIdx}, 2, 'omitnan');
    fluo = sum(temp{:,fluoIdx}, 2, 'omitnan');

    T = temp(:,"regionID");
    T.areaPx = area;
    T.diffFluo = fluo;
end

% Convert pixels in mm
pizelSizeMm = pixelSize/1000;
areaMm2 = T.areaPx * (pizelSizeMm^2);
T.areaMm2 = areaMm2;

% Add the Avg Intensity
T.avgPxIntensity = T.diffFluo ./ T.areaPx;
T = T(:,{'regionID','areaPx','areaMm2','diffFluo','avgPxIntensity'});

% Create a secondary table with the average intensity for each slice
Tslice = table(sliceName,sliceFluo,'VariableNames',{'sliceName','avgFluo'});

% Print a happy end message
beep
fprintf(['\n' repmat('*',1,28)])
fprintf('\n***  END OF ANALYSIS  :D ***\n')
fprintf([repmat('*',1,28) '\n'])


%% Save the result of the analysis
 
tit = 'Save the analysis results';
filt = [defaultFolder filesep];

fname = [sliceArray(1).mouseID '_diffFluo_' sliceArray(1).channelNames{channel} datestr(now,'_yyyymmdd-HHMMSS') '.csv'];
fnameSlice = [sliceArray(1).mouseID '_sliceFluo_' sliceArray(1).channelNames{channel} datestr(now,'_yyyymmdd-HHMMSS') '.csv'];

[file,path] = uiputfile('*.csv',tit,[outputFolder filesep fname]);
if file ~= 0
    writetable(T, [path filesep file])
    writetable(Tslice, [path filesep fnameSlice])
    fprintf('Analysis saved in "%s".\n', [path file])
else
    fprintf('Analysis NOT saved.\n')
end

