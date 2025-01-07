%% prepare general info file
% create a file for general info about the mice

clc, clearvars

datasetPath = 'D:\proj_PNN-Atlas\DATASET';

fileStruct = dir(datasetPath);
miceArray = {};
j = 1;
for i = 1:size(fileStruct ,1)
    mouse_name = fileStruct(i).name;
    if (~strcmp(mouse_name, '.')) && (~strcmp(mouse_name, '..') ) 
        miceArray{j} = fileStruct(i).name;
        j =j+1;
    end
end

mices = string(miceArray)';

miceT = table(mices,strings(size(mices,1),1),strings(size(mices,1),1), ...
    strings(size(mices,1),1),strings(size(mices,1),1), ...
    'VariableNames',{'mouseID', 'treatment', 'genotype','sex', 'age'});

writetable(miceT, [datasetPath filesep 'miceData.xlsx'])

%% Manually fill the xlsx file
% Add the infos in the file manually

%% Create the -info.xml file for each mouse 
clearvars,clc

mouse = 'HF6B';
channelNames = ["wfa","pv"];
% channelNames = ["GAD67","CX3CR1","cfos"];

datasetPath ='D:\proj_PNN-HighFatDiet\DATASET';
experimentInfoFile = "D:\proj_PNN-HighFatDiet\DATASET\miceData.xlsx";  

%extract mouse info
miceTable = readtable(experimentInfoFile);
vars = miceTable.Properties.VariableNames;
miceTable = varfun(@convertcolumn, miceTable);
miceTable.Properties.VariableNames = vars;

mouseTab = miceTable(string(miceTable.mouseID) ==mouse,:);
mouseStruct = table2struct(mouseTab);
mouseStruct.channelNames = channelNames;

%extract slice info
dataPath = [datasetPath filesep mouse filesep 'thumbnails'];
[~,fn,~] = listfiles(dataPath,'.png');
slicesNames = erase(string(fn'),'-thumb.png');
fields = arrayfun(@(x) strsplit(x,'_'),slicesNames,'UniformOutput', false);
fields = cat(1,fields{:});
sliceNum = uint8(str2double(fields(:,2)));
well = fields(:,3);
flipped = zeros(size(fields, 1),1);
valid = ones(size(fields, 1),1);
slices = table2struct(table(slicesNames, sliceNum, well, flipped, valid, ...
    'VariableNames',{'name', 'number', 'well','flipped','valid'}))';

mouseStruct.slices = slices;

% Save -info.xml file
writestruct(mouseStruct, [datasetPath filesep mouse filesep mouse '-info.xml']);


%%


function column = convertcolumn(column)
   if iscell(column) && ~isempty(column) && iscell(column)
      column = string(column);
   end
end


