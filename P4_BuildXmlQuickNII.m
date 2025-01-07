clearvars, clc

% -------------------------------------------------------------------------
defaultFolder = 'D:\proj_PNN-Atlas\DATASET';
mouse = 'CC5B';
% -------------------------------------------------------------------------

%

mouseFolder = [defaultFolder filesep mouse];
infoPath = [mouseFolder filesep mouse '-info.xml'];
thumbPath = [mouseFolder filesep 'thumbnails'];
infos = readstruct(infoPath);

[fp,fn,~] = listfiles(thumbPath, '.png');

tempstr = struct('filenameAttribute',cell(1, size(fn,2)),'nrAttribute',cell(1, size(fn,2)), ...
    'widthAttribute',cell(1, size(fn,2)),'heightAttribute',cell(1, size(fn,2)));
for i = 1:size(fn,2)
    im = imread(fp{i});
    imsize = size(im,[1,2]);
    
    tempstr(i).filenameAttribute = ['thumbnails' '/' fn{i}];
    tempstr(i).nrAttribute = infos.slices(i).number;
    tempstr(i).widthAttribute = imsize(2);
    tempstr(i).heightAttribute = imsize(1);
end
mStruct = struct('nameAttribute', string(mouse), 'slice', tempstr);

%

writestruct(mStruct, [mouseFolder filesep mouse '-quicknii.xml'], 'StructNodeName', 'series');

