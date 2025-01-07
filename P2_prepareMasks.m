%% create image tiles for the training of the random forest (ilastik)

clc
pathIm =  'D:\proj_PNN-Atlas\DATASET';
pathOut =  'D:\proj_PNN-Atlas\mask_training';
numSamples = 120;
cropSize = [300,300];



l = dir([pathIm filesep '**']);
names = string({l.name})';
folds = string({l.folder})';
paths = folds+filesep+names;
match = regexp(paths, '.*-thumb\.png$', 'match');

lf = paths(~cellfun(@isempty, match));


% lf = listfiles(pathIm, '.png');
selIm = randsample(length(lf), numSamples);
for i = 1:length(selIm)
    im = imread(lf{selIm(i)});
    if any(size(im,[1,2])<cropSize)
        continue
    end
    imSmall = cropImg(im, cropSize);
    imOutName = [pathOut filesep 'crop' sprintf('%02d', i) '.png']; %Leo will definitely like this line
    imwrite(imSmall, imOutName);
end


%% create masks with ilastik classifier

% open ilastik project and perform training and batch processing of the
% images in the thumbnails folder
% NB. do not move the ilastik project once it has been saved!

%% rename ilastik ouput files

% rename ilastik output and convert segmented images into bitmap images
% where background and foreground are 0 and 1, respectively
% NB. files will be overwritten if deleteSegmentation is set to true

datasetPath = 'D:\proj_PNN-Atlas\DATASET';
mouse = 'CC6A';
deleteSegmentation = true;


maskPath = [datasetPath filesep mouse filesep 'masks'];
[imgsP, imgsN, ~ ] = listfiles(maskPath, '.png');

if any(contains(imgsP,'-thumb-mask') == 0)
    error('Masks may be already pre-processed!')
end

for i = 1:size(imgsP,2)
    mask = imread(imgsP{i});
    mask = mask ==1;
    fileN = erase(imgsN{i}, '-thumb');    
    newFileN = [maskPath filesep fileN];
    imwrite(mask, newFileN);
    if deleteSegmentation
        delete(imgsP{i});
    end
end

%% edit masks

% masks can be manually edited with batchEditSliceMask script after the
% info xml file has been created!
%--------------------------------------------------------------------------

%%
function crop = cropImg(bigIm, tileSize)
% crop = cropImg(bigIm, tileSize)
%bigIm    : image (matrix) from which the sample is taken
%tileSize : 1x2 array specifying dimensions of the crop (rounded for even numbers)

% arguments
%     bigIm uint8
%     tileSize (1,2) uint8 = [512,512];
% end
tileX = ceil(tileSize(1)/2);
tileY = ceil(tileSize(2)/2);
cropCenterX = randsample([tileX : (size(bigIm,1)-tileX)],1);
cropCenterY = randsample([tileY : (size(bigIm,2)-tileY)],1);
crop = bigIm((cropCenterX-tileX+1):(cropCenterX+tileX-1),(cropCenterY-tileY+1):(cropCenterY+tileY-1),:);

end