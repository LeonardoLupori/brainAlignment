classdef cellClassifier < handle
    properties
        channel
        modelPath
        trained logical {mustBeScalarOrEmpty} = []
        model
        params


    end


    methods (Access= public)
        function self = cellClassifier(channel, modelPath)
            arguments
                channel string {mustBeTextScalar}
                modelPath string {mustBeScalarOrEmpty} = ""
            end

            if strlength(modelPath)>0 && isfile(modelPath)
                load(modelPath);
                if isa(t, "TreeBagger")
                    self.modelPath = modelPath;
                    self.model = t;
                    self.trained = true;
                else
                    error("The specified path does not contain any TreeBagger object!")
                end

                if exist("trainingParams", "var") && isa(trainingParams, "struct")
                    self.params = trainingParams;
                else
                    warning("No training parameters found!")
                end

            elseif strlength(modelPath) == 0
                self.trained = false;
            end
            self.channel = channel;
        end


        function train(self, trainingFolder, trainingOptions)
            arguments
                self
                trainingFolder string {mustBeFolder}
                trainingOptions.numOfTrees uint16 {mustBeNumeric,mustBeInteger,mustBeScalarOrEmpty, mustBeNonnegative} = 100
                trainingOptions.minLeafSize uint16 {mustBeNumeric,mustBeInteger,mustBeScalarOrEmpty, mustBeNonnegative} = 70
                trainingOptions.cost (2,2) double = [0,1;1,0]
                trainingOptions.numOfPixelsPerClass uint16 {mustBeNumeric,mustBeInteger,mustBeScalarOrEmpty, mustBeNonnegative} = 30
                trainingOptions.contrastAdjustment logical {mustBeScalarOrEmpty} = true
                trainingOptions.parallelSubset uint8 {mustBePositive} = 1
            end
            if self.trained == true
                error("The model has already been trained!");
            end

            imList = self.listfiles(trainingFolder, ".tif");
            pathMask = strcat(trainingFolder, filesep,"labels");
            maskList = self.listfiles(pathMask, '_mask.png');
            fprintf("Random Forest classifier: computing image features...\n")
            tic
            if trainingOptions.parallelSubset == 1
                FT = [];
                LB = [];
                for i = 1:length(imList)
                    fprintf("Processing image %d/%d \n", i, length(imList));
                    im = imread(imList{i});
                    if trainingOptions.contrastAdjustment == true
                        im = imadjust(im);
                    end
                    [features, featNames] = self.extractImageFeatures(im);

                    imMask = imread(maskList{i});
                    if sum(imMask, 'all')<trainingOptions.numOfPixelsPerClass
                        trainingOptions.numOfPixelsPerClass = sum(imMask, 'all');
                    end
                    [ft, lb] = self.createFeatureMatrix(im, features, imMask, trainingOptions.numOfPixelsPerClass);

                    FT =cat(1, FT, ft);
                    LB =cat(1, LB, lb);
                end
            else

                indices = round(linspace(0,size(imList,2),trainingOptions.parallelSubset+1));

                imgSubset = cell(1,trainingOptions.parallelSubset);
                maskSubset = cell(1,trainingOptions.parallelSubset);
                FTcell = cell(1,trainingOptions.parallelSubset);
                LBcell = cell(1,trainingOptions.parallelSubset);
                for i = 1:trainingOptions.parallelSubset
                    imgSubset{i} = imList(indices(i)+1:indices(i+1));
                    maskSubset{i} = maskList(indices(i)+1:indices(i+1));
                end

                adjustContrast = ones(1, length(imgSubset)).*trainingOptions.contrastAdjustment;
                numPxPerClass = ones(1, length(imgSubset)).*double(trainingOptions.numOfPixelsPerClass);
                tempNumPxPerClass =0;
                parfor j = 1:length(imgSubset)
                    imSub = imgSubset{j}
                    maskSub = maskSubset{j}
                    for i = 1:length(imSub)

                        %                         fprintf("Processing image %d/%d \n", i, length(imList));
                        im = imread(imSub{i});
                        if adjustContrast(j) == true
                            im = imadjust(im);
                        end
                        [features, featNames] = self.extractImageFeatures(im);

                        imMask = imread(maskSub{i});

                        if sum(imMask, 'all')<numPxPerClass(j)
                            tempNumPxPerClass = sum(imMask, 'all');
                        else
                            tempNumPxPerClass = numPxPerClass(j);
                        end
                        [ft, lb] = self.createFeatureMatrix(im, features, imMask, tempNumPxPerClass);

                        FTcell{j} =cat(1, FTcell{j}, ft);
                        LBcell{j} =cat(1, LBcell{j}, lb);
                        featcell{j} = features;
                        namescell{j} = featNames;
                    end
                end
                FT = vertcat(FTcell{:});
                LB = vertcat(LBcell{:});
                features = featcell{1};
                featNames = namescell{1};
            end
            fprintf("done\n")
            fprintf("Feature matrix computed! Number of features: %d \n", size(features, 3));
            fprintf("Time for feature extraction: %f\n", toc);
            tic
            fprintf("Training the random forest... ")

            self.model = TreeBagger(trainingOptions.numOfTrees, FT, LB, 'OOBPrediction','On', ...
                'Cost', trainingOptions.cost,...
                'PredictorNames',featNames,...
                'OOBPredictorImportance','on', 'MinLeafSize',trainingOptions.minLeafSize);

            self.trained = true;
            fprintf("done!\n");
            fprintf("Time for training: %f\n", toc);

            self.params = struct("numOfTrees", trainingOptions.numOfTrees,...
                "cost", trainingOptions.cost,...
                "minLeafSize", trainingOptions.minLeafSize,...
                "contrastAdjustment", trainingOptions.contrastAdjustment, ...
                "dateOfTraining", datestr(now));

        end

        function saveModel(self, filepath)
            arguments
                self
                filepath string {mustBeScalarOrEmpty} = ""
            end
            if self.trained == false
                error("The classifier has not been trained yet! Unable to save any model")
            end

            savingDate = datestr(now, 'yyyymmdd-HHMM');
            filename = filepath + "model_" + self.channel + "_" + savingDate + ".mat";
            t = self.model;
            trainingParams = self.params;
            save(filename, "t", "trainingParams");
        end

        function [cellMask, cellProbs] = predict(self, image, opts)
            arguments
                self
                image uint8
                opts.numOfSubsets uint8 {mustBePositive} = 1
                opts.contrastAdjustment logical {mustBeScalarOrEmpty} = true
            end

            if self.trained == false
                error("Random Forest Classifier needs to be trained before perfoming predictions!")
            end
            if opts.contrastAdjustment == true
                image = imadjust(image);
            end

            features = self.extractImageFeatures(image);
            [labels, cellProbs] = self.imClassify(features, self.model, opts.numOfSubsets);
            cellMask = labels == 1;

        end
        
        function plotOOBerror(self)
            if self.trained == false
                error("The model has not been trained yet!");
            end

            f = figure;
            ax = axes('Parent',f);
            oobErrorBaggedEnsemble = oobError(self.model);
            plot(oobErrorBaggedEnsemble, 'Parent',ax)
            ax.XLabel.String = "Number of grown trees";
            ax.YLabel.String = "Out-of-bag classification error";
        end

        function plotFeatureImportance(self)
            if self.trained == false
                error("The model has not been trained yet!");
            end
            imp = self.model.OOBPermutedPredictorDeltaError;

            f = figure;
            ax = axes('Parent',f);
            barh(imp, 'Parent',ax);
            ax.Title.String = "Curvature Test";
            ax.XLabel.String = "Predictor importance estimates";
            ax.YLabel.String = "Predictors";

            ax.YTick = [1:size(imp, 2)];
            ax.YTickLabel = self.model.PredictorNames;
        end

    end

    methods (Access= public)
        function [fplist,fnlist,fblist] = listfiles(~, folderpath, token)
            % [fplist,fnlist,fblist] = listfiles(folderpath, token)
            %
            %
            % returns cell arrays with the filepaths/filenames of files ending with 'fileextension' in folder 'folderpath'
            % token examples: '.tif', '.png', '.txt'
            %
            %
            % fplist: list of full paths
            % fnlist: list of file names
            % fblist: list of file sizes in bytes

            listing = dir(folderpath);
            index = 0;
            fplist = {};
            fnlist = {};
            fblist = [];
            for i = 1:size(listing,1)
                s = listing(i).name;
                if contains(s,token)
                    index = index+1;
                    if isstring(folderpath)
                        fplist{index} = folderpath + filesep + s;
                        fnlist{index} = s;
                        fblist = [fblist; listing(i).bytes];
                    else
                        fplist{index} = [folderpath filesep s];
                        fnlist{index} = s;
                        fblist = [fblist; listing(i).bytes];
                    end

                end
            end
        end

        function [classLabels,classProbs] = imClassify(~, imFeat,treeBag,nSubsets)

            [nr,nc,nVariables] = size(imFeat);
            rfFeat = reshape(imFeat,[nr*nc,nVariables]);

            if nSubsets == 1
                % ----- single thread

                [~,scores] = predict(treeBag,rfFeat);
                [~,indOfMax] = max(scores,[],2);
            else
                % ----- parallel

                indices = round(linspace(0,size(rfFeat,1),nSubsets+1));

                ftsubsets = cell(1,nSubsets);
                for i = 1:nSubsets
                    ftsubsets{i} = rfFeat(indices(i)+1:indices(i+1),:);
                end

                scsubsets = cell(1,nSubsets);
                imsubsets = cell(1,nSubsets);
                parfor i = 1:nSubsets
                    [~,scores] = predict(treeBag,ftsubsets{i});
                    [~,indOfMax] = max(scores,[],2);
                    scsubsets{i} = scores;
                    imsubsets{i} = indOfMax;
                end

                scores = zeros(nVariables,length(treeBag.ClassNames));
                indOfMax = zeros(nVariables,1);
                for i = 1:nSubsets
                    scores(indices(i)+1:indices(i+1),:) = scsubsets{i};
                    indOfMax(indices(i)+1:indices(i+1)) = imsubsets{i};
                end
            end

            classLabels = reshape(indOfMax,[nr,nc]);
            classProbs = zeros(nr,nc,size(scores,2));
            for i = 1:size(scores,2)
                classProbs(:,:,i) = reshape(scores(:,i),[nr,nc]);
            end

        end

        function [features, names] = extractImageFeatures(self, im)
            im = double(im);
            imageSize = size(im);
            numRows = imageSize(1);
            numCols = imageSize(2);

            wavelengthMin = 4/sqrt(2);
            wavelengthMax = hypot(numRows,numCols);
            n = floor(log2(wavelengthMax/wavelengthMin));
            wavelength = 2.^(0:(n-2)) * wavelengthMin;

            deltaTheta = 45;
            orientation = 0:deltaTheta:(180-deltaTheta);

            g = gabor(wavelength,orientation);
            gabormag = imgaborfilt(im, g);

            %             sigmas = [0.7, 1];
            %             hessianFeat = zeros(numRows, numCols, 3*size(sigmas,2));
            %             for i = 1:size(sigmas,2)
            %                 [hessianFeat(:,:,1+(3*(i-1))),hessianFeat(:,:,2+(3*(i-1))),hessianFeat(:,:,3+(3*(i-1)))] = self.hessian2D(im, 10, sigmas(i));
            %             end

            ypos = ones(1,numCols).* [1:numCols]';
            ypos = ypos - numCols/2;
            xpos = ones(1,numRows)'.* [1:numRows];
            xpos = xpos - numRows/2;
            %             features = cat(3,im, xpos, ypos,gabormag,hessianFeat);
            features = cat(3,im, xpos, ypos,gabormag);

            featprefix = cellstr(repmat("gabor", [1 size(g,2)]));
            featnum = cellstr(string([1:size(g,2)]));
            featnames = strcat(featprefix, featnum);
            %             featprefix2 = cellstr(repmat("hessian", [1 size(hessianFeat,3)]));
            %             featnum2 = cellstr(string([1:size(hessianFeat,3)]));
            %             featnames2 = strcat(featprefix2, featnum2);
            %             firstfeat = cellstr(["contrast","xpos", "ypos"]);
            %             names = [firstfeat, featnames,featnames2];
            firstfeat = cellstr(["contrast","xpos", "ypos"]);
            names = [firstfeat, featnames];

        end

        function [rfFeat,rfLbl] = rfFeatLab(~, imFeat,imLbl)

            nVariables = size(imFeat,3);

            nLabels = 2; % assuming labels are 1, 2, 3, ...

            nPixelsPerLabel = zeros(1,nLabels);
            pxlIndices = cell(1,nLabels);

            for i = 1:nLabels
                pxlIndices{i} = find(imLbl == i);
                nPixelsPerLabel(i) = numel(pxlIndices{i});
            end

            nSamples = sum(nPixelsPerLabel);

            rfFeat = zeros(nSamples,nVariables);
            rfLbl = zeros(nSamples,1);

            offset = [0 cumsum(nPixelsPerLabel)];
            for i = 1:nVariables
                F = imFeat(:,:,i);
                for j = 1:nLabels
                    rfFeat(offset(j)+1:offset(j+1),i) = F(pxlIndices{j});
                end
            end
            for j = 1:nLabels
                rfLbl(offset(j)+1:offset(j+1)) = j;
            end

        end

        function [ft, lb] = createFeatureMatrix(self, im, features, mask, numOfPixelsPerClass)
            % [FT, LB] = createFeatureMatrix(im, numOfPixelsPerClass)
            % create a matrix for the training of the random forest classifier
            % The code supports classification in 2 classes.


            A = zeros(size(im));

            [r1,c1] = find(mask);
            [r2,c2] = find(~mask);

            ind1 = randsample([1:length(r1)], numOfPixelsPerClass);
            indx1 = c1(ind1);
            indy1 = r1(ind1);

            ind2 = randsample([1:length(r2)], numOfPixelsPerClass);
            indx2 = c2(ind2);
            indy2 = r2(ind2);

            lind1 = sub2ind(size(A), indy1, indx1) ;
            A(lind1) = 1;

            lind2 = sub2ind(size(A), indy2, indx2) ;
            A(lind2) = 2;

            [ft, lb] = self.rfFeatLab(features, A);

        end

        function [Dxx,Dxy,Dyy] =  hessian2D(~, im, k,sigma)
            arguments
                ~
                im
                k double {mustBePositive} = 10
                sigma double {mustBeNonnegative} = 0.7
            end


            G1=fspecial('gauss',[round(k*sigma), round(k*sigma)], sigma);
            [Gx,Gy] = gradient(G1);
            [Gxx,Gxy] = gradient(Gx);
            [~,Gyy] = gradient(Gy);

            Dxx = imfilter(im, Gxx);
            Dxy = imfilter(im, Gxy);
            Dyy = imfilter(im, Gyy);

        end

    end



end