% -------------------------------------------------------------------------
clearvars, clc
% -------------------------------------------------------------------------

imagesFolder = "D:\PizzorussoLAB\proj_PNN-highFatDiet\tiff_Images";
savingFolder = "D:\PizzorussoLAB\proj_PNN-highFatDiet\smallImages\imAdjusted_jpg";

resizeFactor = 0.2;
adjustContrast = true;
outputExtension = '.jpg';
% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

% Selects .tif images to resize
tit = "Select Images to resize.";
[fN, path] = uigetfile('*.tif',tit,imagesFolder, 'MultiSelect', 'on');

parfor i = 1:length(fN)
    im = imread([path fN{i}]);
    
    % Resize
    imSmall = imresize(im, resizeFactor);
    
    % Adjust contrast
    if adjustContrast
        lims = [prctile(imSmall(:,:,1),1,'all'),prctile(imSmall(:,:,2),1,'all'),0;...
            prctile(imSmall(:,:,1),99.9,'all'),prctile(imSmall(:,:,2),99.9,'all'),255];
        lims = double(lims)/255;
        imSmall = imadjust(imSmall,lims);
    end
    
    [~,f,~] = fileparts(fN{i});
    newName = [f, outputExtension];
    
    imwrite(imSmall, savingFolder + filesep + newName)
    fprintf('Image (%u)\n', i)
end




