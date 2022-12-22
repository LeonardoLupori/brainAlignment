clearvars, clc

% -------------------------------------------------------------------------
defaultFolder = 'D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET';
outputFolder = 'D:\PizzorussoLAB\proj_PNN-highFatDiet\RESULTS\dotsPv';

randomForestModelPath = "C:\Users\Leonardo\Documents\MATLAB\PNN_wholeBrain\model_pv_20220412-1829.mat";
channel = 2;
% -------------------------------------------------------------------------


%%

% Load the annotation volume
if ~exist('annotationVolume','var')
    load('annotationVolume.mat');
end


xmlFileList = [...
    "D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET\AL1A\AL1A-info.xml",...
    "D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET\CC1A\CC1A-info.xml",...
    "D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET\CC1B\CC1B-info.xml",...
    "D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET\CC2B\CC2B-info.xml",...
    "D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET\CC3A\CC3A-info.xml",...
    "D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET\HF1A\HF1A-info.xml",...
    "D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET\HF1B\HF1B-info.xml",...
    "D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET\HF2B\HF2B-info.xml",...
    "D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET\HF3A\HF3A-info.xml",...
    "D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET\HF3B\HF3B-info.xml"];


for j = 1:length(xmlFileList)

    xml = xmlFileList(j);
    sliceArray = allSlicesFromXml(xml);
    
    
    T = table();
    % Analyze all the other slices
    for i = 1:length(sliceArray)
        if sliceArray(i).valid == 0
            fprintf('Slice: "%s" flagged as not valid. Skipped quantification\n',sliceArray(i).name)
            continue
        end

        new_T = sliceArray(i).quantifyDots(annotationVolume,channel,randomForestModelPath);
        T = [T; new_T];
    end

    % Print a happy end message
    beep
    fprintf(['\n' repmat('*',1,28)])
    fprintf('\n***  END OF ANALYSIS  :D ***\n')
    fprintf([repmat('*',1,28) '\n'])

    % Save the result of the analysis
    fname = [sliceArray(1).mouseID '_dots_' sliceArray(1).channelNames{channel} datestr(now,'_yyyymmdd-HHMMSS') '.csv'];
    writetable(T, [outputFolder filesep fname])

end








