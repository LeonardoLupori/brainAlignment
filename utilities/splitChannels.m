% -------------------------------------------------------------------------
clearvars, clc
% -------------------------------------------------------------------------

imagesFolder = "D:\PizzorussoLAB\proj_PNN-highFatDiet\tiff_Images";

% -------------------------------------------------------------------------
% -------------------------------------------------------------------------

% Collect all .tif images inside the selected folder
[fPaths,fNnames,~] = listfiles(imagesFolder, '.tif');
fprintf('%u tiff file(s) detected.\n', size(fPaths,2))

parentFolder = fullfile(imagesFolder, '..');
newFoldName = parentFolder + filesep + 'tiff_Channels';

% Create a new folder with the channels split
if ~exist(newFoldName, 'dir')
    mkdir(newFoldName)
    exportImages = true;
else
    quest = 'A single channel folder already exists. Overwrite all contents?';
    tit = 'Overwrite files';
    answer = questdlg(quest,tit,'Yes','No','No');
    
    if strcmpi(answer, 'Yes')
        rmdir(newFoldName)
        mkdir(newFoldName)
        exportImages = true;
    else
        exportImages = false;
    end
end

% Export all the images in the selected folder
if exportImages
    nImages = size(fPaths,2);
    parfor i = 1:nImages
        im = imread(fPaths{i});
        [~, f, ~] = fileparts(fPaths{i});
        
        % Accounts for files named with "_extended"
        if contains(f, "_extended")
            pre = extractBefore(f, "_extended");
            redName = newFoldName + filesep + f + "_R" + "_extended.tif";
            greenName = newFoldName + filesep + f + "_G" + "_extended.tif";
        else
            redName = newFoldName + filesep + f + "_R.tif";
            greenName = newFoldName + filesep + f + "_G.tif";
        end
        
        % Write images in the new folder
        imwrite(im(:,:,1), redName)
        imwrite(im(:,:,2), greenName)
        
        if mod(i,50) == 0 || i == nImages
            fprintf('processing image (%u/%u).\n',i,nImages)
        end
    end
end
