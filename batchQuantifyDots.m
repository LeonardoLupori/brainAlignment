clearvars, clc

% -------------------------------------------------------------------------
defaultFolder = 'D:\PizzorussoLAB\proj_PNN-highFatDiet\DATASET';
outputFolder = 'D:\PizzorussoLAB\proj_PNN-highFatDiet\RESULTS';

% randomForestModelPath = "C:\Users\Leonardo\Documents\MATLAB\PNN_wholeBrain\model_wfa_20220412-1823.mat";
randomForestModelPath = "C:\Users\Leonardo\Documents\MATLAB\PNN_wholeBrain\model_pv_20220412-1829.mat";

channel = 2;
% -------------------------------------------------------------------------

%% Load all slices from a single XML info file (a mouse)

filter = [defaultFolder filesep '.xml'];
tit = 'Select an INFO XML file';
[file,path] = uigetfile(filter,tit);

if file ~= 0
    xml = [path filesep file];
    sliceArray = allSlicesFromXml(xml);
end

%% Single dots analysis

% Load the annotation volume
if ~exist('annotationVolume','var')
    load('annotationVolume.mat');
end

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


%% Save the result of the analysis
 
tit = 'Save the analysis results';
filt = [outputFolder filesep];

fname = [sliceArray(1).mouseID '_dots_' sliceArray(1).channelNames{channel} datestr(now,'_yyyymmdd-HHMMSS') '.csv'];

[file,path] = uiputfile('*.csv',tit,[outputFolder filesep fname]);
if file ~= 0
    writetable(T, [path filesep file])
    fprintf('Analysis saved in "%s".\n', [path file])
else
    fprintf('Analysis NOT saved.\n')
end

