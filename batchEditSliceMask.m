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

%% (OPTIONAL) - Run this cell if you want to preprocess all masks

% Objects smaller than this number of pixels will be removed
threshold = 50;

for i = 1:length(sliceArray)
    msk = sliceArray(i).mask;
    temp = bwareaopen(msk,threshold);
    % Invert the mask and perform the same processing
    temp = bwareaopen(~temp,threshold);
    % Dilate the mask to erode a few pixels on the outside of the slice
    temp = imdilate(temp,strel('disk',3));
    % Invert back the mask to normal
    temp = ~temp;
    
    % Save the mask back into the objects
    sliceArray(i).mask = temp;
end

fprintf('\nMasks for all slices filtered.\n')

%% Run the maskEditor GUI on all the slices

maskEditor(sliceArray);

%% (OPTIONAL) - Use this cell to show one specific slice

if ~exist('annotationVolume','var')
    load('annotationVolume.mat');
end

sl = Slice(7,xml);
sl.show('volume',annotationVolume,'borders',true,'mask',true);

