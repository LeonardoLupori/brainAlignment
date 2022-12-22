classdef cellLabeler < handle
    properties (Access = protected)
        fig_controls
        fig_lumSlid

        imSlider
        maskSlider
    end
    properties (Access = public)

        fig_image
        ax_image
        imgHandle
        imageData

        mask

        maskIm
        folder

        imIndex
        channel
        
        maskTransparency = 0.4;
        imArray

        defVals = 0.5
    end
    %--------------------------------------------------------------
    % Constructor function
    %--------------------------------------------------------------
    methods
        function obj = cellLabeler(folderPath, channel, imIndex)
            arguments
                folderPath char
                channel char = "wfa"
                imIndex double {mustBeInteger} = 1

            end
            obj.folder = folderPath;
            obj.imArray = listfiles(folderPath, 'tif');
            obj.imIndex = imIndex;
            obj.channel = channel;

            screenSize =  get(0, 'ScreenSize');

            %--------------------------------------------------------------
            % Control recap
            %--------------------------------------------------------------
            width3 = 220;
            heigth3 = 240;
            obj.fig_controls = uifigure('Resize', 'off',...
                'Name', 'Controls',...
                'NumberTitle','off',...
                'Position',[25, (screenSize(4)-heigth3-50), width3, heigth3],...
                'CloseRequestFcn',@obj.closeFunction);
            grid = uigridlayout(obj.fig_controls,...
                'ColumnWidth',{'1x','2x'},...
                'RowHeight',{'fit','fit', 'fit','fit', 'fit', 'fit','fit'});

            % TEXT
            uilabel('Parent',grid,'Text','m:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Toggle mask');

            uilabel('Parent',grid,'Text','A:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Add pixels');

            uilabel('Parent',grid,'Text','D:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Delete pixels');

            uilabel('Parent',grid,'Text','U:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Binarize again');

            uilabel('Parent',grid,'Text','>:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Next image');

            uilabel('Parent',grid,'Text','<:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Previous image');

            uilabel('Parent',grid,'Text','Enter:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Save mask');

            %--------------------------------------------------------------
            % Sliders
            %--------------------------------------------------------------

            width2 = 450;
            heigth2 = 140;
            obj.fig_lumSlid = uifigure('Resize', 'off',...
                'Name', 'Luminance Sliders',...
                'NumberTitle','off',...
                'MenuBar','none',...
                'Position',[screenSize(3)-width2-25 50 width2 heigth2],...
                'CloseRequestFcn',@obj.closeFunction);
            grid = uigridlayout(obj.fig_lumSlid,...
                'ColumnWidth',{'1x','5x'},...
                'RowHeight',{'1x', '1x'});

            % image Control Slider
            uilabel('Parent',grid,'Text','Cell');
            obj.imSlider = uislider('Parent', grid,...
                'Value', obj.defVals,...
                'Limits', [0, 1],...
                'Tag','iSl',...
                'ValueChangedFcn',@obj.luminanceManager);


            % Mask Control Slider
            uilabel('Parent',grid,'Text','Mask');
            obj.maskSlider = uislider('Parent', grid,...
                'Value', obj.maskTransparency,...
                'Limits', [0, 1],...
                'Tag','mSl',...
                'ValueChangedFcn',@obj.luminanceManager);


            %--------------------------------------------------------------
            % Main figure
            %--------------------------------------------------------------
            width = 500;
            heigth = 500;

            obj.fig_image = figure('Color',[0.1,0.1,0.1],...
                'Position',[(screenSize(3)-width)/2 (screenSize(4)-heigth)/2 width heigth],...
                'Name',sprintf('Image number: %d/%d', obj.imIndex,length(obj.imArray)),...
                'NumberTitle','off',...
                'CloseRequestFcn', @obj.closeFunction,...
                'WindowKeyPressFcn', @obj.parseKey);

            % Create the axes
            obj.ax_image = axes('Parent',obj.fig_image,...
                'Units','normalized',...
                'Position',[0 0 1 .95]);

            % Plot image
            obj.imageData = imread(obj.imArray{obj.imIndex});

            if strcmpi(obj.channel, "wfa")
                obj.mask = binarizeWFA(obj.imageData);
            elseif strcmpi(obj.channel, "pv")
                obj.mask = binarizePV(obj.imageData);
            end

            newImage = imadjust(obj.imageData,...
                [0, obj.imSlider.Value],...
                [0,1]);
%             obj.imageData = newImage;
            obj.imgHandle = imshow(newImage,...
                'Parent', obj.ax_image);
            obj.ax_image.XLim = [0 size(obj.imageData,2)];
            obj.ax_image.YLim = [0 size(obj.imageData,1)];

            hold(obj.ax_image, 'on')
            % create mask
            



            blank = zeros(size(obj.mask));
            fill = ones(size(obj.mask));
            imbg = cat(3,fill,blank, fill);
            obj.maskIm = imshow(imbg);

            obj.maskIm.AlphaData = obj.mask  .* obj.maskSlider.Value;
            hold(obj.ax_image,'off')

        end

        %--------------------------------------------------------------
        % Methods
        %--------------------------------------------------------------
        function parseKey(obj, ~, event)
            key = event.Key;
            switch key
                case 'm'
                    obj.maskIm.Visible = ~obj.maskIm.Visible;
                case 'd'
                    obj.deleteMask();
                case 'a'
                    obj.drawMask();
                case 'return'
                    obj.saveMask()
                case 'u'
                    obj.restartMask()
                case 'rightarrow'
                    if obj.imIndex < length(obj.imArray)
                        obj.imIndex = obj.imIndex + 1;
                        obj.changeIm()
                    end
                case 'leftarrow'
                    if obj.imIndex > 1
                        obj.imIndex = obj.imIndex - 1;
                        obj.changeIm()
                    end
                    
            end
        end
        function restartMask(obj,~,~)
            if strcmpi(obj.channel, "wfa")
                obj.mask = binarizeWFA(obj.imageData);
            elseif strcmpi(obj.channel, "pv")
                obj.mask = binarizePV(obj.imageData);
            end
            obj.maskIm.AlphaData = obj.mask  .* obj.maskSlider.Value;
        end

        function deleteMask(obj,~,~)

            roi = drawfreehand(obj.maskIm.Parent, 'color', 'red');
            R = roi.createMask(obj.maskIm);
            obj.maskIm.AlphaData(R) = 0;
            delete(roi);
            obj.mask = obj.maskIm.AlphaData > 0;

        end

        function drawMask(obj,~,~)

            roi = drawfreehand(obj.maskIm.Parent, 'color', 'blue');
            R = roi.createMask(obj.maskIm);
            obj.maskIm.AlphaData(R) = 1 .* obj.maskSlider.Value;
            delete(roi);
            obj.mask = obj.maskIm.AlphaData > 0;

        end


        function saveMask(obj, ~, ~)
            maskToSave = obj.maskIm.AlphaData>0;

            
            savingDir = [obj.folder filesep 'labels'];
            
            if isfolder(savingDir) == false
                mkdir(savingDir)
            end
            [~,f,~] = fileparts(obj.imArray{obj.imIndex});
            saveName = strcat(savingDir, filesep, f, "_mask.png");
            imwrite(maskToSave, saveName);
            if obj.imIndex == length(obj.imArray)
                obj.closeFunction();
            end
            if obj.imIndex == length(obj.imArray)
                return
            end
            obj.imIndex = obj.imIndex +1;
            obj.changeIm();
        end

        function changeIm(obj, ~, ~)
            im = imread(obj.imArray{obj.imIndex});
            obj.fig_image.Name = sprintf('Image number: %d/%d', obj.imIndex,length(obj.imArray));

            obj.imageData = im;
            obj.imSlider.Value = obj.defVals;
            newImage = imadjust(obj.imageData,...
                [0, obj.imSlider.Value],...
                [0,1]);
            
            obj.imgHandle.CData = newImage;
            obj.ax_image.XLim = [0 size(obj.imageData,2)];
            obj.ax_image.YLim = [0 size(obj.imageData,1)];
            if  strcmpi(obj.channel, "wfa")
                obj.mask = binarizeWFA(obj.imageData);
            elseif strcmpi(obj.channel, "pv")
                obj.mask = binarizePV(obj.imageData);
            end
            

            blank = zeros(size(obj.mask));
            fill = ones(size(obj.mask));
            imbg = cat(3,fill,blank, fill);
            obj.maskIm.CData =  imbg;
            
  
            obj.maskIm.AlphaData =  obj.mask .* obj.maskSlider.Value;
        end

        function luminanceManager(obj,src,valueChangedData)
            if  strcmp(valueChangedData.Source.Tag, 'iSl')

                newImage = imadjust(obj.imageData,...
                    [0, valueChangedData.Value],...
                    [0,1]);
                obj.imgHandle.CData = newImage;

            elseif strcmp(valueChangedData.Source.Tag, 'mSl')
                if obj.maskIm.Visible == false
                    src.Value = valueChangedData.PreviousValue;
                    return
                end
                obj.maskIm.AlphaData = obj.mask.*valueChangedData.Value;

            end
        end

        function closeFunction(obj,~,~)
            delete(obj.fig_image)
            delete(obj.fig_lumSlid)
            delete(obj.fig_controls)
        end
    end
end