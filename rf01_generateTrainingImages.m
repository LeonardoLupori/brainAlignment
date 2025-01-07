%% EXTRACTING TRAINING IMAGES FROM DATASET
clearvars, clc

%% INDICATE FILE FOLDER AND IMAGE PARAMETERS
% Note that the number of cells per animal can be higher due to
% rounding operations.

miceFolder = 'D:\proj_PNN-Atlas\DATASET'; %UPDATE HERE
cellPerMice = 15;
cellSize = 80; %cells will be extracted from a bounding box of side cellSide x cellSide  (Px)
channel = "wfa";

%% RANDOMLY SAMPLE CELLS FROM DIFFERENT MICE AND DIFFERENT SLICES (very slow)
% Note that the number of cells per animal can be higher due to
% rounding operations.

contents = dir(miceFolder);          % Get the contents of the path
folders = contents([contents.isdir]); % Filter to keep only directories

% Exclude '.' and '..' special directories
miceList = folders(~ismember({folders.name}, {'.', '..'}));
miceList = {miceList.name};

indabs = 1;
for mouseIdx = 1:length(miceList)
    
    mouseName = miceList{mouseIdx};
    infopath = [miceFolder, filesep,mouseName,filesep, sprintf('%s-info.xml', mouseName)];

    info = readstruct(infopath);
    
    numSlices = size(info.slices(logical(cat(info.slices.valid)')),2);
    trainingFolder = strcat(miceFolder, filesep, "training", "_", channel);
    cellPerSlice = ceil(cellPerMice/numSlices);

    validSlices = info.slices(logical(cat(info.slices.valid)'));
    % create saving directory if absent
    if ~isfolder(trainingFolder)
        mkdir(trainingFolder)
    end

    images = string(listfiles([miceFolder, filesep, mouseName,filesep, 'hiRes'], '.tif')');
    counts = string(listfiles([miceFolder, filesep, mouseName,filesep, 'counts'], '.csv')');

    for sliceIdx = 1:numSlices
        sliceName = validSlices(sliceIdx).name;
        %select channel to process
        if strcmpi(channel, "wfa")

            imWfaPath = images(contains(images,strcat(sliceName,'-C1')));
            countWfaPath =counts(contains(counts, strcat(sliceName,'-cells_C1')));
            im = imread(imWfaPath);
            cellTab = readtable(countWfaPath);
            cellIdx = randsample(height(cellTab), cellPerSlice);
            cells = cellTab{cellIdx, :};
            cells = uint16(cells);
        elseif strcmpi(channel, "pv")
            imPvPath = images(contains(images,strcat(sliceName,'-C2')));
            countPvPath =counts(contains(counts, strcat(sliceName,'-cells_C2')));
            im = imread(imPvPath);
            cellTab = readtable(countPvPath);
            cellIdx = randsample(height(cellTab), cellPerSlice);
            cells = cellTab{cellIdx, :};
            cells = uint16(cells);
        else
            error(fprintf("Selected channel (%s) is not present in the mouse dataset: %s \n", channel, miceList{mouseIdx}))
        end
        
        %pick up the images and save them
        for i = size(cells, 1)
            smallIm = extractSubImage(im, cells(i,:), cellSize);
            
            %file name definition
            cellCode = sprintf("%04d", indabs);
            mouseCode = sprintf("_m%02d", mouseIdx);
            channelCode = strcat("_", channel);
            smallImPath = strcat(trainingFolder, filesep, "cell_", cellCode, mouseCode,channelCode, ".tif");
            
            imwrite(smallIm, smallImPath, 'Compression', 'lzw');

            indabs = indabs+1;
            if indabs == 143
                break
            end
        end
        

    end
    fprintf("Extracting cells from mice %d/%d \n", mouseIdx, length(miceList));
end

%% LABEL THE GENERATED IMAGES FOR WFA STAINING

trainingFolder = "D:\proj_PNN-Atlas\DATASET\training_wfa";
clab = cellLabeler(trainingFolder, "wfa", 1);

%% LABEL THE GENERATED IMAGES FOR PV STAINING

trainingFolder = "D:\proj_PNN-Atlas\DATASET\training_pv";
clab = cellLabeler(trainingFolder, "pv", 1);



