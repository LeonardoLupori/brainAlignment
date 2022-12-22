%  Create dispField for ALL IMAGES of an animal

clearvars, clc

% -------------------------------------------------------------------------
defaultFolder = 'D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET';
% -------------------------------------------------------------------------

%% Load all slices from an XML file (a single mouse)

filter = [defaultFolder filesep '.xml'];
tit = 'Select an INFO XML file';
[file,path] = uigetfile(filter,tit);

if file ~= 0
    xml = [path filesep file];
    sliceArray = allSlicesFromXml(xml);
end

%% Show 8 random slices to check the alignment

% Load the annotation volume
if ~exist('annotationVolume','var')
    load('annotationVolume.mat');
end

slicesTocheck = randperm(length(sliceArray),8);
for i = 1:length(slicesTocheck)
    idx = slicesTocheck(i);
    f = sliceArray(idx).show(volume=annotationVolume, borders=1, dots=[1,1], mask=true);
    waitfor(f)
end

