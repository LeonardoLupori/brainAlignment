classdef Slice

    properties(Access=public)

        % Mouse properties

        mouseID char {mustBeTextScalar}             % ID of the mouse
        mouseTreatment char {mustBeTextScalar}      % Treatment of the mouse
        mouseGenotype char {mustBeTextScalar}       % Genotype of the mouse
        mouseSex char {mustBeTextScalar}            % Sex of the mouse
        mouseAge (1,1) double {mustBeNonnegative}   % Age (postnatal days) of the mouse

        % Slice properties

        name char {mustBeTextScalar}                % Name of this slice
        number (1,1) double {mustBeNonnegative}     % Absolute number of this slice
        well char {mustBeTextScalar}                % Well name of the multiwell plate where the IHC took place
        flipped (1,1) {islogical}                   % Whether the image has been flipped
        valid (1,1) {islogical}                     % Whether the image is valid or rejected

        % Experimental data

        parentFolder char {mustBeTextScalar,mustBeFolder} = "C:\"   % Main mouse folder
        channelNames cell {mustBeText}                  % Names of the fluorescence channels
        hiResFilenames cell {mustBeText}                % Filename of the High-resolution images
        dots cell                                       % Tables with x-y dots locations for each channel
        thumbnail {mustBeA(thumbnail,"uint8")} = zeros(1,1,'uint8') % Small RGB image
        resizeFactor (1,1) double {mustBePositive} = 0.2
        mask {islogical}                                % Logical mask denoting only valid pixels

        % Alignment data

        o (1,3) double              % Anchoring vector from quickNII
        u (1,3) double              % Anchoring vector from quickNII
        v (1,3) double              % Anchoring vector from quickNII
        markers (:,4) double        % Location of the markers from visuAlign
        dispField double            % X and Y Displacement fields generated from the markers

    end

    methods(Access=public)

        function self = Slice(sliceName, xmlInfoFile)
            % self = Slice(sliceName, xmlInfoFile)
            %
            % Constructor of the Slice class.
            %
            % INPUTS
            %
            % sliceName - name of a slice that we want to instantiate
            % (e.g., AL1A_002_A1). Alternatively you can also pass a number
            % (e.g., 2) and the slice with number 002 will be loaded.
            %
            % xmlInfoFile - full path to the info file (.xml) of the
            % selected animal

            arguments
                sliceName
                xmlInfoFile {mustBeTextScalar,mustBeFile}
            end

            % Read the XML file
            infoStruct = readstruct(xmlInfoFile);

            % Fill properties about the mouse
            self.mouseID = infoStruct.mouseID;
            self.mouseTreatment = infoStruct.treatment;
            self.mouseGenotype = infoStruct.genotype;
            self.mouseSex = infoStruct.sex;
            self.mouseAge = infoStruct.age;


            % Select a single slice from the XML info file
            if isa(sliceName,'char') || isa(sliceName,'string')
                selectedSliceIdx = [infoStruct.slices.name] == sliceName;
            elseif isa(sliceName,'double')
                selectedSliceIdx = [infoStruct.slices.number] == sliceName;
            end

            foundSlicesNo = sum(selectedSliceIdx);
            if foundSlicesNo < 1
                error("No slices found with the selected name: '%s'.", string(sliceName))
            elseif foundSlicesNo > 1
                error("More than one slice found with the selected name: '%s'.", string(sliceName))
            else
                selectedSlice = infoStruct.slices(selectedSliceIdx);
            end

            % Fill properties about this slice
            self.name = selectedSlice.name;
            self.number = selectedSlice.number;
            self.well = selectedSlice.well;
            self.flipped = selectedSlice.flipped;
            self.valid = selectedSlice.valid;

            %
            parentFolder = fileparts(xmlInfoFile);
            self.parentFolder = parentFolder;
            self.channelNames = cellstr(infoStruct.channelNames);

            % Hi-res Image
            hiResFolder = [self.parentFolder filesep 'hiRes'];
            [~, fnlist] = self.listfiles(hiResFolder, char(selectedSlice.name));
            self.hiResFilenames = fnlist;

            % Cell counts
            dotsFolder = [self.parentFolder filesep 'counts'];
            [~, fnlist] = self.listfiles(dotsFolder, char(selectedSlice.name));
            fnlist = sort(fnlist);

            if ~isempty(fnlist)
                for i = 1:length(self.channelNames)
                    fileIdx = contains(fnlist, sprintf('-cells_C%u',i));
                    if any(fileIdx)
                        tablePath = [self.parentFolder filesep 'counts' filesep fnlist{fileIdx}];
                        % tablePath = [self.parentFolder filesep 'counts' filesep fnlist{i}];
                        self.dots{i} = readtable(tablePath);
                    else
                        self.dots{i} = cell2table(cell(0,2),'VariableNames', {'x', 'y'}); 
                    end
                end
            end

            % Thumbnail
            thumbFolder = [self.parentFolder filesep 'thumbnails'];
            [~, fnlist] = self.listfiles(thumbFolder, char(selectedSlice.name));
            if ~isempty(fnlist)
                self.thumbnail = imread([thumbFolder filesep fnlist{1}]);
            end

            % Mask
            maskFolder = [self.parentFolder filesep 'masks'];
            [~, fnlist] = self.listfiles(maskFolder, char(selectedSlice.name));
            if ~isempty(fnlist)
                self.mask = imread([maskFolder filesep fnlist{1}]);
            end

            % Displacement field
            dispFieldFolder = [self.parentFolder filesep 'dispFields'];
            [~, fnlist] = self.listfiles(dispFieldFolder, char(selectedSlice.name));
            fnlist = sort(fnlist);
            if ~isempty(fnlist)
                dx = readmatrix([dispFieldFolder filesep fnlist{1}]);
                dy = readmatrix([dispFieldFolder filesep fnlist{2}]);
                
                D = cat(3,dx,dy);

                D = imresize(D, size(self.thumbnail,[1,2]),'bilinear');
                self.dispField = D;
            end

            % Visualign file
            [~, fnlist] = self.listfiles(self.parentFolder, '-visualign.json');
            if ~isempty(fnlist)
                struct = self.readVisualignJson([self.parentFolder filesep fnlist{1}]);
                selectedSliceIdx = contains({struct.slices.filename}, self.name);
                selectedSlice = struct.slices(selectedSliceIdx);

                anchoring = selectedSlice.anchoring;
                self.o = anchoring(1:3);
                self.u = anchoring(4:6);
                self.v = anchoring(7:9);

                self.markers = selectedSlice.markers;

                visualignFileFound = true;
            else
                visualignFileFound = false;
            end

            % QuickNII file
            if ~visualignFileFound
                [~, fnlist] = self.listfiles(self.parentFolder, '-quicknii.xml');
                if ~isempty(fnlist)

                    struct = self.parseAlignmentXml([self.parentFolder filesep fnlist{1}]);

                    selectedSliceIdx = contains([struct.fileName], self.name);
                    selectedSlice = struct(selectedSliceIdx);

                    self.o = [selectedSlice.ox, selectedSlice.oy, selectedSlice.oz];
                    self.u = [selectedSlice.ux, selectedSlice.uy, selectedSlice.uz];
                    self.v = [selectedSlice.vx, selectedSlice.vy, selectedSlice.vz];
                end
            end

        end

        function f = show(self, opts)
            % f = sliceShow(opts)
            %
            % OPTIONS
            % mask
            % maskTransparency
            % channels
            % visualignMarkers
            % dots

            arguments
                self
                opts.mask {islogical,isscalar} = false;
                opts.maskTransparency double {isscalar} = 0.3
                opts.channels (1,3) logical {islogical} = [true, true, true]
                opts.visualignMarkers {islogical,isscalar} = false;
                opts.dots {islogical} = false;
                opts.borders {islogical,isscalar} = false;
                opts.volume = [];
            end

            blankImg = zeros(size(self.thumbnail,[1,2]),'uint8');
            maskColor = cat(3, blankImg, blankImg+255, blankImg+255);

            [f, ax] = self.figureDisplay();

            imToPlot = self.thumbnail;
            imToPlot(:,:, ~opts.channels) = 0;
            imshow(imToPlot);

            hold(ax,'on')
            maskHandle = imshow(maskColor);

            % Eventually display the mask
            if opts.mask
                maskHandle.AlphaData = ~self.mask * opts.maskTransparency;
            else
                maskHandle.AlphaData = blankImg;
            end

            % Plot the markers from visualign
            if opts.visualignMarkers && ~isempty(self.markers)
                plot(self.markers(:,3), self.markers(:,4),...
                    'LineStyle','none','Marker','+',...
                    'MarkerEdgeColor',[1,1,1],...
                    'MarkerSize',13,...
                    'LineWidth',2)
                plot(self.markers(:,[1,3])',self.markers(:,[2,4])',...
                    'LineStyle','-',...
                    'Color',[1,1,1],...
                    'LineWidth',1.5)
            end

            % Eventually plot the dots
            cellLabels = gobjects(sum(opts.dots),1);
            if any(opts.dots)
                if length(opts.dots) > length(self.dots)
                    error('This slice only has %u cell counts. You requested %u',length(self.dots),length(opts.dots))
                end
                colors = cool(sum(opts.dots));
                for i = 1:length(opts.dots)
                    if opts.dots(i)
                        tab = self.dots{i};
                        if isempty(tab)     % If there are no cells in this channel
                            cellLabels(i) = plot(0, 0,...
                                'LineStyle','none','Marker','none',...
                                'DisplayName',self.channelNames{i});
                        else
                        cellLabels(i) = plot(tab.x * self.resizeFactor, tab.y * self.resizeFactor,...
                            'LineStyle','none','Marker','.',...
                            'MarkerEdgeColor',colors(i,:),...
                            'DisplayName',self.channelNames{i},...
                            'MarkerSize',13);
                        end
                    end
                end
                legend(cellLabels,'Location','best')
            end

            % Plot the borders
            if opts.borders
                validVolume = true;
                if isempty(opts.volume)
                    warning(['No annotation volume provided an option "volume".'...
                        ' Borders will not be drawn.'])
                    validVolume = false;
                elseif ndims(opts.volume) ~=3 
                    warning(['Invalid annotation volume.'...
                        ' Borders will not be drawn.'])
                    validVolume = false;
                end
                
                if validVolume
                    % Calculate the borders
                    obliqueSlice = self.getObliqueSlice(opts.volume);
                    rescaled = self.rescaleAnnotation(obliqueSlice);
                    borders = self.annotationBorders(rescaled);
                    if ~isempty(self.dispField)
                        borders = imwarp(borders,self.dispField);
                    end

                    % Show the borders
                    whiteImg = ones(size(self.thumbnail,[1,2]),'uint8') * 255;
                    bord = imshow(whiteImg);
                    bord.AlphaData = borders * 0.5;
                end
            end

            hold(ax,'off')
            enableDefaultInteractivity(ax)
        end

        function D = getDispField(self,resizeFactor)
            % D = getDispField()
            arguments
                self
                resizeFactor {isscalar,mustBePositive} = .1;
            end
            
            if isempty(self.markers)
                error("No markers for slice %s. Impossible to calculate a displacement field.", self.name)
            end

            width = round(size(self.thumbnail,2)*resizeFactor);
            height = round(size(self.thumbnail,1)*resizeFactor);

            Dx = zeros([height, width]);
            Dy = zeros([height, width]);
            
            % Generate a list of triangles from the markers in this slice
            trList = triangulateSlice(width, height, self.markers * resizeFactor);
            % Get max and min x and y for all the triangles
            minMax = [trList.minx; trList.maxx; trList.miny; trList.maxy];
            parfor i = 1:height
                for j = 1:width
                    [Dx(i,j), Dy(i,j)] = getDisplacement(j, i, trList, minMax);
                end
            end

            D = cat(3,Dx,Dy);
            D = D / resizeFactor;
        end
    
        function borders = getAnnotationBorders(self, annotationVolume)
            % borders = getAnnotationBorders(annotationVolume)
            
            obliqueSlice = self.getObliqueSlice(annotationVolume);
            rescaled = self.rescaleAnnotation(obliqueSlice);
            borders = self.annotationBorders(rescaled);
        end
    
        function [T, meanSliceFluo] = quantifyDiffuse(self, annotationVolume, channelNumber)
            % [T, meanSliceFluo] = quantifyDiffuse(annotationVolume, channelNumber)

            % Load the correct HI-RES image
            filt = sprintf('-C%u',channelNumber);
            index = contains(self.hiResFilenames,filt);
            fName = self.hiResFilenames{index};
            fprintf('Loading %s ... ',fName)
            rawName = [self.parentFolder filesep 'hiRes' filesep fName];
            raw = imread(rawName);
            
            fprintf('preparing data... ')
            % Prepare the annotation image
            obliqueSlice = self.getObliqueSlice(annotationVolume);
            annot = imwarp(obliqueSlice, self.dispField,'nearest');
            regionIDs = unique(annot);
            annot = imresize(annot, size(raw), 'nearest');

            % Prepare the mask
            msk = imresize(self.mask, size(raw),'nearest');
            
            % Initialize diffuse fluoresce and area
            diffFluo = zeros(size(regionIDs));
            areaPx = zeros(size(regionIDs));
            
            fprintf('quantifying...')
            for i = 1:length(regionIDs)
                thisID = regionIDs(i);
%                 if thisID == 0
%                     continue
%                 end
                validMap = (annot == thisID) & msk;
                % Calculate Area and Fluorescence
                areaPx(i) = sum(validMap,'all');
                diffFluo(i) = sum(raw(validMap),'all');
            end
            
            meanSliceFluo = mean(raw(msk),'all');

            T = table(regionIDs, areaPx, diffFluo,...
                'VariableNames',{'regionID','areaPx','diffFluo'});
            fprintf(' done.\n')
        end
          
        function T = quantifyDots(self, annotationVolume, channelNumber, rfModelPath)
            % T = quantifyCells(annotationVolume, channelNumber)

            % Load the correct HI-RES image
            filt = sprintf('-C%u',channelNumber);
            index = contains(self.hiResFilenames,filt);
            fName = self.hiResFilenames{index};
            fprintf('Loading %s ... ',fName)
            rawName = [self.parentFolder filesep 'hiRes' filesep fName];
            raw = imread(rawName);
            
            fprintf('preparing data... ')
            % Load the correct Cells table
            dotsT = self.dots{channelNumber};

            % Prepare the annotation image
            obliqueSlice = self.getObliqueSlice(annotationVolume);
            annot = imwarp(obliqueSlice, self.dispField,'nearest');
            annot = imresize(annot, size(raw), 'nearest');

            % Prepare the mask
            msk = imresize(self.mask, size(raw),'nearest');

            % Initialize the struct for holding dots data
            T = struct(...
                'cellID',[],...
                'parentImg',[],...
                'x',[],...
                'y',[],...
                'xCCF',[],...
                'yCCF',[],...
                'zCCF',[],...
                'regionID',[],...
                'fluoMean',[],...
                'fluoMedian',[],...
                'areaPx',[]);
            
            % Transformation matrix to get 3D positions for each cell in
            % this slice
            tm = [self.u ; self.v; self.o];
            
            % Upsample displacement field for cell position calculation
            D = self.dispField;
            D = imresize(D,size(raw),'bilinear');

            % Load the random forest model
            RF = cellClassifier(self.channelNames{channelNumber},rfModelPath);

            % Cycle through dots and quantify each
            fprintf('quantifying dots...\n')
            count = 1;
            skipped = 0;
            for i = 1:size(dotsT,1)

                x = round(dotsT.x(i));
                y = round(dotsT.y(i));
                
                % Skip this dot if it's outside of the mask area
                if msk(y,x) == 0
                    skipped = skipped + 1;
                    continue
                end
                
                % Unique ID for this dot
                dotID = sprintf('%s_%03u_%s_%05u',...
                    self.mouseID, self.number,...
                    self.channelNames{channelNumber},i);

                % ID of the region where this dot is located
                regionID = annot(y,x);
                
                % Convert the xy position of this cell to the 3D CCF
                newX = x - D(y,x,1);
                newY = y - D(y,x,2);
                coordCcf = [newX/size(raw,2), newY/size(raw,1), 1] * tm;
                
                % RandomForest Classifier
                subImg = self.extractSubImage(raw, [x,y], 80, 1);
                bw = RF.predict(subImg);
                bw = bwareaopen(bw,10);


                fluoMean = mean(subImg(bw),'all');
                fluoMedian = median(double(subImg(bw)),'all');
                area = sum(bw,'all');



                % Fill the results for this dot
                T(count).cellID = dotID;
                T(count).parentImg = fName;
                T(count).x = x;
                T(count).y = y;
                T(count).xCCF = coordCcf(1);
                T(count).yCCF = coordCcf(2);
                T(count).zCCF = coordCcf(3);
                T(count).regionID = regionID;
                T(count).fluoMean = fluoMean;
                T(count).fluoMedian = fluoMedian;
                T(count).areaPx = area;

                count = count+1;
                
                % Print progress messages
                if mod(i,500) == 0 || i == size(dotsT,1)
                    fprintf('\tdots quantified: (%u/%u)...\n', i, size(dotsT,1))
                end
            end
            
            % Print summary messages
            fprintf('done!\n\n')
            fprintf('SUMMARY\n')
            fprintf([repmat('*',1,30),'\n'])
            fprintf('\t%u valid cells quantified.\n',count)
            fprintf('\t%u cells skipped (out of the mask).\n',skipped)
            fprintf([repmat('*',1,30),'\n'])

            % Convert to table for the output
            T = struct2table(T);
        end

        function T = annotatedDotsTable(self, annotationVolume, channelNumber)
            
            % Load the correct HI-RES image
            filt = sprintf('-C%u',channelNumber);
            index = contains(self.hiResFilenames,filt);
            fName = self.hiResFilenames{index};
            fprintf('Loading %s ... ',fName)
            rawName = [self.parentFolder filesep 'hiRes' filesep fName];
            raw = imread(rawName);
            
            fprintf('preparing data... ')
            % Load the correct Cells table
            dotsT = self.dots{channelNumber};

            % Prepare the annotation image
            obliqueSlice = self.getObliqueSlice(annotationVolume);
            annot = imwarp(obliqueSlice, self.dispField,'nearest');
            annot = imresize(annot, size(raw), 'nearest');


            % Initialize the struct for holding dots data
            T = struct(...
                'imageName',[],...
                'x',[],...
                'y',[],...
                'regionID',[]);

            % Cycle through dots and quantify each
            fprintf('quantifying dots...\n')
            count = 1;
            for i = 1:size(dotsT,1)

                x = round(dotsT.x(i));
                y = round(dotsT.y(i));
                
                % ID of the region where this dot is located
                regionID = annot(y,x);
                
                % Fill the results for this dot
                T(count).imageName = fName;
                T(count).x = x;
                T(count).y = y;
                T(count).regionID = regionID;

                count = count+1;
                
                % Print progress messages
                if mod(i,500) == 0 || i == size(dotsT,1)
                    fprintf('\tdots quantified: (%u/%u)...\n', i, size(dotsT,1))
                end
            end
                
            % Convert to table for the output
            T = struct2table(T);
        end
    
        function obliqueSlice = getObliqueSlice(self, volume)
            % obliqueSlice = getObliqueSlice(self, volume)
            %
            % Get a slice from the average template of the annotation volume


            width = size(self.thumbnail,2);
            height = size(self.thumbnail,1);

            tranfMatrix = [self.u; self.v; self.o];
            volSz = size(volume);

            % Initialize the output image
            obliqueSlice = zeros(height, width, class(volume));

            for i = 1:height
                for j = 1:width
                    % Correct for 0-indexing in MATLAB
                    xp = j-1;
                    yp = i-1;
                    % As explained in Puchades et Al. 2019
                    a = [xp/width yp/height,1] * tranfMatrix;
                    b = round(a);
                    % Correct back for 0-indexing in X and Y
                    b = b + [0 1 1];
                    % Deal with slices that are very oblique and extend outside of the
                    % volume
                    if any(b<1) || b(1)>volSz(1) || b(2)>volSz(2) || b(3)>volSz(3)
                        obliqueSlice(i,j) = 0;
                    else
                        obliqueSlice(i,j) = volume(b(1),b(2),b(3));
                    end
                end
            end
        end
    end

    methods (Access=private)

        function [fplist,fnlist,fblist] = listfiles(~, folderpath, token)
            % [fplist,fnlist,fblist] = listfiles(folderpath, token)
            %
            % returns cell arrays with the filepaths/filenames of files ending with 'fileextension' in folder 'folderpath'
            % token examples: '.tif', '.png', '.txt'
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

        function struct = readVisualignJson(~,jsonPath)
            % struct = readVisualignJson(~,jsonPath)
            %

            f = fopen(jsonPath);
            txt = fread(f, '*char');
            fclose(f);
            struct = jsondecode(strrep(txt','\','/'));
        end

        function sliceInfo = parseAlignmentXml(~,pathToXml)
            % sliceInfo = parseAlignmentXml(pathToXml)
            %
            % Create a multidimensional struct for each slice in the xml file

            xml = readstruct(pathToXml);
            for i = length(xml.slice):-1:1
                thisSlice = xml.slice(i);

                sliceInfo(i).fileName = thisSlice.filenameAttribute;
                sliceInfo(i).imNumber = thisSlice.nrAttribute;
                sliceInfo(i).width = thisSlice.widthAttribute;
                sliceInfo(i).height = thisSlice.heightAttribute;

                if isfield(xml, 'target_resolutionAttribute')
                    sliceInfo(i).targetVolumeResolution = xml.target_resolutionAttribute;
                else
                    sliceInfo(i).targetVolumeResolution = "none";
                end

                % Fill the values for the 3D vectors o u and v
                if isfield(thisSlice, 'anchoringAttribute') && ~ismissing(thisSlice.anchoringAttribute)
                    temp = split(thisSlice.anchoringAttribute, ["&", "="]);
                    for j = 1:9
                        sliceInfo(i).(temp(j*2-1)) = str2double(temp(j*2));
                    end
                else
                    sliceInfo(i).ox = nan;
                    sliceInfo(i).oy = nan;
                    sliceInfo(i).oz = nan;
                    sliceInfo(i).ux = nan;
                    sliceInfo(i).uy = nan;
                    sliceInfo(i).uz = nan;
                    sliceInfo(i).vx = nan;
                    sliceInfo(i).vy = nan;
                    sliceInfo(i).vz = nan;
                end

            end
        end

        function [f, ax] = figureDisplay(self)
            % Creates a bigger and darker figure object for displaying images
            % more clearer on a darker background.
            figBrightness = 0.05;
            axBrightness = 0.2;
            ticksBrightness = 0.6;

            % Compute figure size based on screen size
            scrSz = get(0, 'ScreenSize');
            w = scrSz(3) * 3/4;
            h = scrSz(4) * 3/4;
            x = (scrSz(3) - w) / 2;
            y = (scrSz(4) - h) / 2;

            f = figure('Position',[x,y,w,h],...
                'Color',ones(3,1)*figBrightness,...
                'MenuBar','none',...
                'ToolBar','none',...
                'NumberTitle','off',...
                'Name',sprintf('Slice: %s',self.name));
            ax = axes('Parent',f,...
                'Color',ones(3,1)*axBrightness,...
                'XColor',ones(3,1)*ticksBrightness,...
                'YColor',ones(3,1)*ticksBrightness,...
                'Units','normalized',...
                'Position',[.05 .05 .9 .9]);
            enableDefaultInteractivity(ax);
        end

    end

    methods (Static)

        function rescaledImg = rescaleAnnotation(annotationImg)
            % rescaledImg = rescaleAnnotation(annotationImg)
            %
            % Rescale an image of annotation ID that vary wildly between
            % huge and small numbers to a more uniform set of numbers

            sorted = unique(annotationImg(:));
            [~, index] = ismember(annotationImg(:), sorted);
            % Reshape to the original size
            rescaledImg = reshape(index,size(annotationImg));
        end

        function borders = annotationBorders(annotationImage)
            % borders = annotationBorders(annotationImage)
            %
            % From an image of annotation ID computes an image with borders
            % of each region

            gradients = imgradient(annotationImage);
            binary = gradients > 0;
            binaryFiltered = imgaussfilt(double(binary),2);
            borders = binaryFiltered > 0.1;
        end

        function subImg = extractSubImage(sourceImg, XY, outSize, channel)
            % subImg = extractSubImage(sourceImg, XY, outSize, channel)
            arguments
                sourceImg           % Input image (2D or 3D)
                XY (1,2)            % [x,y] position of the center of the subImg
                outSize {mustBePositive,isscalar} = 60      % Size of the square subImg
                channel {mustBePositive,isscalar} = 1       % source chanel in sourceImg
            end
            
            [width, height] = size(sourceImg, [2, 1]);
            
            % Check that the requested sumIng size is even
            if mod(outSize,2) ~= 0
                outSize = outSize+1;
                warning('outSize must be an even number, corrected to %upx', outSize)
            end
            
            % Borders of the output image
            xPoints = [XY(1)-(outSize/2)+1 XY(1)+(outSize/2)];
            yPoints = [XY(2)-(outSize/2)+1 XY(2)+(outSize/2)];

            % Resolve possible border effects for the X axis
            if xPoints(1) < 1
                xPoints = [1 outSize];
            elseif xPoints(2) > width
                xPoints = [width-outSize+1 width];
            end
            % Resolve possible border effects for the Y axis
            if yPoints(1) < 1
                yPoints = [1 outSize];
            elseif yPoints(2) > height
                yPoints = [height-outSize+1 height];
            end
            
            subImg = sourceImg(yPoints(1):yPoints(2) , xPoints(1):xPoints(2), channel);
            
        end
    
    end


end