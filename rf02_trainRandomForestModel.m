% TRAIN classifier for PNNs
clc, clearvars
pathPNN = "D:\proj_PNN-Atlas\DATASET\training_wfa";
rfPNN = cellClassifier("wfa");

rfPNN.train(pathPNN,...
    "contrastAdjustment",true, "cost",[0,1;3.5,0],...
    "minLeafSize",50, "numOfPixelsPerClass",30,...
    "numOfTrees",100, "parallelSubset",1);

%% Plot OOB prediction error

rfPNN.plotOOBerror();

%% Plot feature importance

rfPNN.plotFeatureImportance()

%% TRAIN classifier for Pv cells

rfPV = cellClassifier("pv");
pathPV = "D:\proj_PNN-Atlas\DATASET\training_pv";
rfPV.train(pathPV,...
    "contrastAdjustment",true, "cost",[0,1;4,0],...
    "minLeafSize",70, "numOfPixelsPerClass",30,...
    "numOfTrees",100, "parallelSubset",1);

%% Plot OOB prediction error

rfPV.plotOOBerror();

%% Plot feature importance

rfPV.plotFeatureImportance()

%% Predict on example image
im1 = imread("D:\proj_PNN-Atlas\DATASET\training_wfa\cell_0098_m01_wfa.tif");
rfPNN.predict(im1, contrastAdjustment=true);
im2 = imread("D:\proj_PNN-Atlas\DATASET\training_pv\cell_0033_m01_pv.tif");
rfPV.predict(im2, contrastAdjustment=true);

% [a,b] = rfPV.predict(im, "contrastAdjustment",1);

%% Save Models

rfPNN.saveModel();

rfPV.saveModel();
