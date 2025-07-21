clearvars, clc
addpath(genpath('C:\Users\valen\Documents\MATLAB\PNN_wholebrain'));


countFolder = 'D:\proj_PNN-Atlas\RESULTS\allData';
savingFolder ='D:\proj_PNN-Atlas\RESULTS\colocalization';

minDist = 15;


%%
if ~isfolder(countFolder)
error('specified count folder is not valid')
end

if ~isfolder(savingFolder)
mkdir(savingFolder)
end

%%
clc
countFiles = string(listfiles(countFolder, '_dots_'));

T = table();
for i = 1:size(countFiles, 2)

    [t,m] = regexp(countFiles(i), "(\w+)_dots_(\w+)_","tokens", "match"); 
    if  ~isempty(t)
    T = cat(1, T, array2table(t{:},VariableNames={'mice','staining'}));
    end
end

mice = unique(T.mice);
staining = unique(T.staining);
matchedMice = zeros(1, length(mice), 'logical');
matchedFiles = {};
for j = 1:size(mice)
    ind = find(T.mice == mice(j));
    if isequal(T.staining(ind) , staining)
        matchedFiles{j} = countFiles(ind);
        matchedMice(j) = 1;
    end
end
mice = mice(matchedMice);

% up to this point it is general for N channels
%%
for k = 1:length(matchedFiles)
    t_pnn_path = matchedFiles{k}(contains(matchedFiles{k}, 'wfa'));
    t_pv_path = matchedFiles{k}(contains(matchedFiles{k}, 'pv'));
    t_pnn = readtable(t_pnn_path);
    t_pv = readtable(t_pv_path);
    t_pnn.parentImg = string(t_pnn.parentImg);
    t_pv.parentImg = string(t_pv.parentImg);

    images = string(unique([t_pv.parentImg; t_pnn.parentImg]));
    images = unique(string(regexp(images, "\w+_\d+_\w+","match")));
    tableCell = cell(1, length(images));
    firstcell = 1;
    for j = 1:length(images)

        temp_pnn = t_pnn(t_pnn.parentImg == (images(j)+"-C1.tif"),:);
        temp_pv = t_pv(t_pv.parentImg == (images(j)+"-C2.tif"),:);
        coord_pnn = [temp_pnn.x, temp_pnn.y];
        coord_pv = [temp_pv.x, temp_pv.y];
        coord_pnn(coord_pnn<1) = 1;
        coord_pv(coord_pv<1) = 1;

        % coord_pv = removeDuplicateValues(coord_pv)
        % coord_pnn = removeDuplicateValues(coord_pnn)


        D = pdist2(coord_pv, coord_pnn, 'euclidean');
        D(D>minDist) = nan;
        [m, in] = min(D, [],'omitnan');

        colocalized_pv = temp_pv(in(~isnan(m)), :);
        colocalized_pnn = temp_pnn(~isnan(m), :);
        notColocalized_pnn = temp_pnn(isnan(m), :);
        notColocalized_pv = temp_pv(setdiff(1:height(temp_pv),in(~isnan(m))), :);
        num_col = height(colocalized_pv);
        num_wfa = height(notColocalized_pnn);
        num_pv = height(notColocalized_pv);
        totcells = num_col+num_wfa+num_pv;

        totTable =  table('size', [totcells, 16], ...
            'VariableTypes', {'string', 'string', 'doublenan', 'doublenan',...
            'doublenan', 'doublenan', 'doublenan', 'doublenan',...
            'doublenan', 'doublenan', 'doublenan', 'doublenan', ...
            'doublenan', 'doublenan', 'doublenan', 'doublenan'}, ...
            'VariableNames',{'cellID', 'parentImg', 'x', 'y',...
            'xCCF', 'yCCF', 'zCCF', 'regionID',...
            'wfa', 'fluoMeanWfa', 'fluoMedianWfa', 'areaPxWfa',...
            'pv',  'fluoMeanPv', 'fluoMedianPv', 'areaPxPv'});

        prefix_el = strsplit(images(j), '_');
        extended_code = 0;
        if length(prefix_el)>3
            if strcmpi(prefix_el(4), 'extended2')
                extended_code = 2;
            elseif strcmpi(prefix_el(4), 'extended')
                extended_code = 1;
            end
        end
        prefix = strjoin([prefix_el(1:2) extended_code], '_');
        prefixes = repmat(prefix,totcells, 1);
        cellnumbers =[firstcell:(firstcell + totcells-1)]';
        suffixes = arrayfun(@sprintf,repmat("_%05d", length(cellnumbers),1), cellnumbers ,'UniformOutput', true);

        cellIDs = prefixes+suffixes;
        avgX = round(mean([colocalized_pnn.x, colocalized_pv.x],2));
        avgY = round(mean([colocalized_pnn.y, colocalized_pv.y],2));
        xCCF = mean([colocalized_pnn.xCCF, colocalized_pv.xCCF],2);
        yCCF = mean([colocalized_pnn.yCCF, colocalized_pv.yCCF],2);
        zCCF = mean([colocalized_pnn.zCCF, colocalized_pv.zCCF],2);

        totTable.cellID(1:num_col) = cellIDs(1:num_col);
        totTable.parentImg(1:num_col) = colocalized_pv.parentImg(1);
        totTable.x(1:num_col) = avgX;
        totTable.y(1:num_col) = avgY;
        totTable.xCCF(1:num_col) = xCCF;
        totTable.yCCF(1:num_col) = yCCF;
        totTable.zCCF(1:num_col) = zCCF;
        totTable.regionID(1:num_col) = colocalized_pnn.regionID;
        totTable.wfa(1:num_col) = ones(num_col,1);
        totTable.pv(1:num_col) = ones(num_col,1);
        totTable{1:num_col, ["fluoMeanWfa", "fluoMedianWfa", "areaPxWfa"]} = colocalized_pnn{:, ["fluoMean", "fluoMedian", "areaPx"]} ;
        totTable{1:num_col, ["fluoMeanPv", "fluoMedianPv", "areaPxPv"]} = colocalized_pv{:, ["fluoMean", "fluoMedian", "areaPx"]} ;

        endWfa = num_col+num_wfa;
        totTable.cellID(num_col+1:endWfa) = cellIDs(num_col+1:endWfa);
        totTable{num_col+1:endWfa, {'parentImg',  'x', 'y', 'xCCF', 'yCCF','zCCF', ...
            'regionID','fluoMeanWfa', 'fluoMedianWfa', 'areaPxWfa'}} ...
            = notColocalized_pnn{:, {'parentImg',  'x', 'y', 'xCCF', 'yCCF', 'zCCF',...
            'regionID' , 'fluoMean', 'fluoMedian', 'areaPx'}} ;
        totTable.wfa(num_col+1:endWfa) = ones(num_wfa, 1);
        totTable.pv(num_col+1:endWfa) = zeros(num_wfa, 1);

        totTable.cellID(endWfa+1:totcells) = cellIDs(endWfa+1:totcells);
        totTable{endWfa+1: totcells, {'parentImg',  'x', 'y', 'xCCF', 'yCCF','zCCF', ...
            'regionID','fluoMeanPv', 'fluoMedianPv', 'areaPxPv'}} ...
            = notColocalized_pv{:, {'parentImg',  'x', 'y', 'xCCF', 'yCCF', 'zCCF',...
            'regionID' , 'fluoMean', 'fluoMedian', 'areaPx'}} ;
        totTable.wfa(endWfa+1:totcells) = zeros(num_pv, 1);
        totTable.pv(endWfa+1:totcells) = ones(num_pv, 1);

        


        tableCell{j} = totTable;
    end

    firstcell = totcells+1;
    finTable = vertcat(tableCell{:});
    filename =strcat(savingFolder ,filesep, mice(k), '_dots_processed.csv');
    fprintf('saving file of %s mouse...', mice(k))
    writetable(finTable, filename)
    fprintf('done!\n')

end

%%
totTable = tableCell{40};
coord = [totTable{totTable.pv==false, 'x'}, totTable{totTable.pv==false, 'y'}];
coord2 = [totTable{totTable.wfa==false, 'x'}, totTable{totTable.wfa==false, 'y'}];
coord3 = [totTable{totTable.wfa==totTable.pv, 'x'}, totTable{totTable.wfa==totTable.pv, 'y'}];
blankIm = zeros(round(max(totTable.y))+50, round(max(totTable.x))+50);
% ind = sub2ind(size(blankIm), round(totTable.y), round(totTable.x));
% blankIm(ind) = 1;

ind2 = sub2ind(size(blankIm), coord(:,2), coord(:,1));
blankIm(ind2) = 2;

ind3 = sub2ind(size(blankIm), coord2(:,2), coord2(:,1));
blankIm(ind3) = 3;

ind4 = sub2ind(size(blankIm), coord3(:,2), coord3(:,1));
blankIm(ind4) = 4;
im = imdilate(blankIm, strel('disk', 10));
imagesc(im)

colormap jet


%%

red = imread("D:\DATASET_20220412\AL1A\hiRes\AL1A_130_B2-C1.tif");
green = imread("D:\DATASET_20220412\AL1A\hiRes\AL1A_130_B2-C2.tif");

im1 = cat(3, imadjust(red), green, green);
%%
imshow(im1)
hold on
plot(coord2(:,1), coord2(:,2), LineStyle='none', marker = 'x', MarkerEdgeColor=[1 0  1],linewidth= 1.5 ,MarkerSize=12 )
plot(coord(:,1), coord(:,2), LineStyle='none', marker = 'x', MarkerEdgeColor=[0 0 1],linewidth= 1.5, MarkerSize=12 )
plot(coord3(:,1), coord3(:,2), LineStyle='none', marker = 'o', MarkerEdgeColor=[1 1 0],linewidth= 1.5,  MarkerSize=12 )

hold off
legend('PV', 'WFA', 'WFA-PV')
