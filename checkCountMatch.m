% Given a set of images and a set of cell counts .csv files, this script
% checks whether there is a count for each image or not

clearvars, clc

%--------------------------------------------------------------------------
imagesFolder = 'D:\PizzorussoLAB\proj_PNN-highFatDiet\tiff_Channels';
countFolder = 'D:\PizzorussoLAB\proj_PNN-highFatDiet\cellCounts\PV_03';
channel = 'G';
%--------------------------------------------------------------------------

% Loadd all the images and counts
[fP, allCounts] = listfiles(countFolder, '.csv');
[~, allImgs] = listfiles(imagesFolder, '.tif');

% Select only images for the correct channel
imgs = allImgs(contains(allImgs, ['_' channel]));

% Remove extension form filenames
rmExt = @(x) x(1:end-4);
imgs = cellfun(rmExt, imgs, 'UniformOutput', false);
counts = cellfun(rmExt, allCounts, 'UniformOutput', false);

% Compare and put togheter in a table
counted = ismember(imgs, counts);
T = table(imgs', counted');
