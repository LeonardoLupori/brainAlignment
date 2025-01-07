%  Create dispField for ALL IMAGES of an animal

clearvars, clc

% -------------------------------------------------------------------------
defaultFolder = 'D:\proj_PNN-Atlas\DATASET';
resizeFactor = 0.2;
% -------------------------------------------------------------------------

%% Load all slices from an XML file (a single mouse)

filter = [defaultFolder filesep '.xml'];
tit = 'Select an INFO XML file';
[file,path] = uigetfile(filter,tit);

if file ~= 0
    xml = [path filesep file];
    sliceArray = allSlicesFromXml(xml);
end
 
%% Calculate and save displacement fields for all the slices
for i = 1:length(sliceArray)
    thisSlice = sliceArray(i);
    fprintf('Processing slice: %s... ', thisSlice.name)
    
    % Split the displacement field in X and Y
    D = thisSlice.getDispField(resizeFactor);
    Dx = single(D(:,:,1));
    Dy = single(D(:,:,2));
    
    % Compose the filename of the 2 files
    dipPath = [thisSlice.parentFolder filesep 'dispFields' filesep];
    if ~isfolder(dipPath)
        mkdir(dipPath)
    end

    dipNameX = [thisSlice.name '-dispFieldX.csv'];
    dipNameY = [thisSlice.name '-dispFieldY.csv'];
     
    % Actually save the files
    fprintf('saving... ')
    writematrix(Dx, [dipPath dipNameX])
    writematrix(Dy, [dipPath dipNameY])

    fprintf(' done.\n')
end

fprintf('COMPLETE! :D\n')
