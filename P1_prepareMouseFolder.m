%% Specify folder containing mouse images
clearvars, clc
addpath(genpath(['.' filesep 'utilities']))

mouse = 'CC6B';

rawTiffPath = 'D:\proj_PNN-Atlas\rawData\rawRGB';
flipInfoPath  = 'D:\proj_PNN-Atlas\flipInfo';
datasetPath = 'D:\proj_PNN-Atlas\DATASET';

rawTiffPath = [rawTiffPath filesep mouse];
[imgsP, imgsN , ~]= listfiles(rawTiffPath, '.tif');

% Create xlxs file to select images that need to be flipped

if isfolder(rawTiffPath) == false
    error('specified path for raw images must be a directory');
end
flipInfoFile = [flipInfoPath,filesep,mouse,'.xlsx'];
if isfile(flipInfoFile) == false
    fprintf("%s file saved\n", [mouse '.xls'])

    infoTable = table(string(imgsN'), strings(size(imgsN, 2),1), VariableNames={'Image', 'morePosterior'});

    pathfields = split(rawTiffPath, '\');
    mouse = char(pathfields(end));
    writetable(infoTable,  flipInfoFile)
else
    fprintf("%s file already exists!!!\n", [mouse '.xls'])
end

%% Manually fill the xlsx file

% open the xlxs file and indicate whether the most posterior part of the
% is the left or the right emisphere (or side of the image)

%% Load list of images to be flipped

% Load the table with flip information
flipMap = readtable([flipInfoPath filesep mouse '.xlsx']);
flipMap.morePosterior = categorical(flipMap.morePosterior);

numberLeft = sum(flipMap.morePosterior=='l');
numberRight = sum(flipMap.morePosterior=='r');
% Find undefined values in order to assign them the same orientation as the
% majority of the slices
missing = isundefined(flipMap.morePosterior);

% Decide which slices to flip
if numberLeft > numberRight
    toFlip = 'r';
    flipMap.morePosterior(missing) = 'l';
else
    toFlip = 'l';
    flipMap.morePosterior(missing) = 'r';
end

% List of images that need to be flipped
imagesToflip_name = flipMap.Image(flipMap.morePosterior==toFlip);
imagesToflip_bool = flipMap.morePosterior==toFlip;



fprintf('\nA total of %u images will be flipped:\n', length(imagesToflip_name))
for i = 1:length(imagesToflip_name)
    fprintf('\t- %s\n', imagesToflip_name{i})
end

%% save flipped images

targetFolder = [datasetPath filesep mouse '_flip'];

if ~isfolder(targetFolder)
    mkdir(targetFolder)
    fprintf('Saving folder not found, created!\n')
end 

parfor i = 1:size(imgsP,2)
    im = imread(imgsP{i});
    if imagesToflip_bool(i)
        im = fliplr(im)
        fprintf('\t- %s flipped\n', imgsN{i})
    else
        fprintf('\t- %s NOT flipped\n', imgsN{i})
    end
    imwrite(im, [targetFolder filesep imgsN{i}])
end

%% Create DATASET subfolders

% mouse = 'BG1B';
flippedImageFolder = [datasetPath filesep mouse '_flip'];

% Collect images path and names and define suitable variables
[imgsP, imgsN , ~]= listfiles(flippedImageFolder, '.tif');

% Define mouse dataset folder path
dirPath = [datasetPath filesep mouse];
if isfolder(dirPath)==false
    mkdir(dirPath)
else
    fprintf("%s DATASET folder already exists!\n", dirPath)
end

% CREATE SUBFOLDERS
% create hiRes subfolder
channelPath = [dirPath filesep 'hiRes'];
if isfolder(channelPath)==false
    mkdir(channelPath)
else
    fprintf("%s hiRes folder already exists!\n", channelPath)
end

% create thumbnails subfolder
thumbPath = [dirPath filesep 'thumbnails'];
if isfolder(thumbPath)==false
    mkdir(thumbPath)
else
    fprintf("%s thumbnails folder already exists!\n", thumbPath)
end


maskPath = [dirPath filesep 'masks'];
if isfolder(maskPath)==false
    mkdir(maskPath)
else
    fprintf("%s thumbnails folder already exists!\n", maskPath)
end

%% Separate and save channels in hiRes folder`

[fp, ~, ~] = listfiles(channelPath, '.tif');
if isempty(fp) == false
    error('hiRes folder already contains images');
end
fprintf('Separating channels:\n');

numOfImages = size(imgsP,2);
parfor i = 1:numOfImages
    im = imread(imgsP{i});
    for j = 1:size(im,3)
        if sum(im(:,:,j), 'all') == 0
            continue
        end
        file = split(imgsN{i},'.');
        file = file{1};
        fullName = [channelPath filesep file sprintf('-C%1d',j) '.tif'];
        imwrite(im(:,:,j),fullName);
    end
    fprintf("%4d/%4d image processed\n", i , numOfImages); % not that meaningful for parallel processing
end

%% Generate thumbnails


adjustContrast = true;
resizeFactor = 0.2;

numOfImages = size(imgsP,2);


[fp, ~, ~] = listfiles(thumbPath, '.png');
if isempty(fp) == false
    error('thumbnails path already contains images');
end
fprintf('Generating thumbnails:\n');
for i = 1:numOfImages
    im = imread(imgsP{i});
    smallIm =imresize(im, resizeFactor);
    if adjustContrast
%         lims = [prctile(smallIm(:,:,1),1,'all'),prctile(smallIm(:,:,2),1,'all'),prctile(smallIm(:,:,3),1,'all');...
%             prctile(smallIm(:,:,1),99.8,'all'),prctile(smallIm(:,:,2),99.8,'all'),prctile(smallIm(:,:,3),99.8,'all')];
        lims = [prctile(smallIm(:,:,1),1,'all'),prctile(smallIm(:,:,2),1,'all'),0;...
            prctile(smallIm(:,:,1),99.8,'all'),prctile(smallIm(:,:,2),99.8,'all'),255];        
%         lims = [0,prctile(smallIm(:,:,2),1,'all'),0;...
%             255,prctile(smallIm(:,:,2),99.8,'all'),255];
        lims = double(lims)/255;
        smallIm = imadjust(smallIm,lims);
    end
    file = split(imgsN{i},'.');
    file = file{1};
    fullName = [thumbPath filesep file '-thumb' '.png'];
    imwrite(smallIm,fullName);

    fprintf("%4d/%4d image processed\n", i , numOfImages); % not that meaningful for parallel processing
end

%% Create masks

% To create mask use the ilastik pipeline.
% See prepareMasks.m
