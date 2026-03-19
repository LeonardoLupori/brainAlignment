classdef maskEditor < handle
    properties (Access = protected)
        fig_controls
        fig_lumSlid

        redSlider
        greenSlider
        maskSlider
    end
    properties (Access = public)
        metaT
        fileM
        slice
        sliceArray

        fig_image
        ax_image
        imgHandle
        imageData

        maskIm

        resizeFactor
        negative
        maskTransparency = 0.4;
        maskLum = 1
        imArray

        defVals = struct('redValue',1,...
            'greenValue', 1);
    end
    %--------------------------------------------------------------
    % Constructor function
    %--------------------------------------------------------------
    methods
        function obj = maskEditor(sliceArray,negative)
            arguments
                sliceArray 
                negative logical = false
            end
            obj.sliceArray = sliceArray;
            obj.negative = negative;
            

            obj.slice = obj.sliceArray(1);

            screenSize =  get(0, 'ScreenSize');


            %--------------------------------------------------------------
            % Control recap
            %--------------------------------------------------------------
            width3 = 200;
            heigth3 = 240;
            obj.fig_controls = uifigure('Resize', 'off',...
                'Name', 'Controls',...
                'NumberTitle','off',...
                'Position',[25, (screenSize(4)-heigth3-50), width3, heigth3],...
                'CloseRequestFcn',@obj.closeFunction);
            grid = uigridlayout(obj.fig_controls,...
                'ColumnWidth',{'1x','2x'},...
                'RowHeight',{'fit','fit', 'fit','fit','fit', 'fit'...
                'fit','fit','fit'});

            % TEXT
            uilabel('Parent',grid,'Text','>:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Next image');

            uilabel('Parent',grid,'Text','<:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Previous image');

            uilabel('Parent',grid,'Text','Spacebar:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Negative mask');

            uilabel('Parent',grid,'Text','m:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Toggle mask');

            uilabel('Parent',grid,'Text','A:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Add pixels');

            uilabel('Parent',grid,'Text','D:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Delete pixels');

            uilabel('Parent',grid,'Text','R:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Toggle Red channel');

            uilabel('Parent',grid,'Text','G:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Toggle Green channel');

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
                'RowHeight',{'1x', '1x', '1x'});

            % Red Control Slider
            uilabel('Parent',grid,'Text','Red');
            obj.redSlider = uislider('Parent', grid,...
                'Value', obj.defVals.redValue,...
                'Limits', [0.01, 1],...
                'Tag','rSl',...
                'ValueChangedFcn',@obj.luminanceManager);

            % Green Control Slider
            uilabel('Parent',grid,'Text','Green');
            obj.greenSlider = uislider('Parent', grid,...
                'Value', obj.defVals.greenValue,...
                'Limits', [0.01, 1],...
                'Tag','gSl',...
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
            width = 950;
            heigth = 600;

            obj.fig_image = figure('Color',[0.1,0.1,0.1],...
                'Position',[(screenSize(3)-width)/2 (screenSize(4)-heigth)/2 width heigth],...
                'Name',sprintf('Image preview: %s',obj.slice.name),...
                'NumberTitle','off',...
                'CloseRequestFcn', @obj.closeFunction,...
                'WindowKeyPressFcn', @obj.parseKey);

            % Create the axes
            obj.ax_image = axes('Parent',obj.fig_image,...
                'Units','normalized',...
                'Position',[0 0 1 .95]);

            % Plot image
            obj.imageData = obj.slice.thumbnail;
            r = obj.redSlider.Value;
            g = obj.greenSlider.Value;
            newImage = imadjust(obj.imageData,...
                [0, 0, 0; r, g, 1],...
                [0,0,0;1,1,1]);

            obj.imgHandle = imshow(newImage,...
                'Parent', obj.ax_image);
            obj.ax_image.XLim = [0 size(obj.imageData,2)];
            obj.ax_image.YLim = [0 size(obj.imageData,1)];

            hold(obj.ax_image, 'on')
            % create mask
            [blankIm,maskNew] =  createEditableMask(obj.imageData, obj.slice.mask);

            obj.maskIm = imshow(blankIm.*obj.maskLum);

            if obj.negative == true
                obj.maskIm.AlphaData = ~maskNew .* obj.maskSlider.Value;
            elseif obj.negative == false
                obj.maskIm.AlphaData = maskNew .* obj.maskSlider.Value;
            end

            hold(obj.ax_image,'off')

        end

        %--------------------------------------------------------------
        % Methods
        %--------------------------------------------------------------
        function parseKey(obj, ~, event)
            key = event.Key;
            switch key
                case 'leftarrow'
                    obj.changeIm([],[],1)
                case 'rightarrow'
                    obj.changeIm([],[],-1)
                case 'm'
                    obj.maskIm.Visible = ~obj.maskIm.Visible;
                case 'space'
                    obj.switchMask();
                case 'd'
                    obj.deleteMask();
                case 'a'
                    obj.drawMask();
                case 'g'
                    obj.toggleGreen()
                case 'r'
                    obj.toggleRed()

                case 'return'
                    answer = questdlg('Are you sure you want to save the mask?',...
                        'Saving Mask to .mat file' ,...
                        'Yes','No','Yes');
                    % Handle response
                    switch answer
                        case 'Yes'
                            obj.saveMask()
                        case 'No'
                            return
                    end

            end
        end

        function switchMask(obj, ~, ~)
            whiteIm = ones(size(obj.maskIm.AlphaData));
            whiteIm(obj.maskIm.AlphaData > 0) = 0;
            obj.maskIm.AlphaData = whiteIm .* obj.maskSlider.Value;
            obj.negative = ~obj.negative;
        end

        function deleteMask(obj,~,~)

            roi = drawfreehand(obj.maskIm.Parent, 'color', 'red');
            R = roi.createMask(obj.maskIm);
            if obj.negative == false
                obj.maskIm.AlphaData(R) = 0;
            elseif obj.negative == true
                obj.maskIm.AlphaData(R) = 1 .* obj.maskSlider.Value;
            end

            delete(roi);

        end

        function drawMask(obj,~,~)

            roi = drawfreehand(obj.maskIm.Parent, 'color', 'blue');
            R = roi.createMask(obj.maskIm);
            if obj.negative == false
                obj.maskIm.AlphaData(R) = 1 .* obj.maskSlider.Value;
            elseif obj.negative == true
                obj.maskIm.AlphaData(R) = 0;
            end

            delete(roi);

        end

        function toggleGreen(obj, ~, ~)
            isGreen = checkChannelImage(obj.imgHandle.CData, 2);
            if isGreen
                obj.imgHandle.CData(:,:,2) = zeros(size(obj.imageData, [1,2]));
            else
                r = obj.redSlider.Value;
                g = obj.greenSlider.Value;
                newImage = imadjust(obj.imageData,...
                    [0, 0, 0; r, g, 1],...
                    [0,0,0;1,1,1]);
                obj.imgHandle.CData(:,:,2) = newImage(:,:,2);
            end
        end


        function toggleRed(obj, ~, ~)
            isRed = checkChannelImage(obj.imgHandle.CData, 1);
            if isRed
                obj.imgHandle.CData(:,:,1) = zeros(size(obj.imageData, [1,2]));
            else
                r = obj.redSlider.Value;
                g = obj.greenSlider.Value;
                newImage = imadjust(obj.imageData,...
                    [0, 0, 0; r, g, 1],...
                    [0,0,0;1,1,1]);
                obj.imgHandle.CData(:,:,1) = newImage(:,:,1);
            end
        end

        function saveMask(obj, ~, ~)
            if obj.negative == false
                maskToSave = obj.maskIm.AlphaData>0;
            elseif obj.negative == true
                maskToSave = obj.maskIm.AlphaData == 0;
            end
            maskToSave = logical(maskToSave);
            maskToSave = imresize(maskToSave, size(obj.slice.mask,[1,2]),'nearest');
            
            obj.sliceArray(1).mask = maskToSave;
                
            newMaskPath = [obj.slice.parentFolder filesep 'masks' filesep obj.slice.name '-mask.png'];
            imwrite(maskToSave, newMaskPath)

            fprintf('Saved mask (image: %s)\n', obj.slice.name);


        end

        function changeIm(obj, ~, ~, direction)
            arguments
                obj
                ~
                ~
                direction double {mustBeInRange(direction, -1, 1)} = -1
            end

            obj.sliceArray = circshift(obj.sliceArray, direction);
            obj.slice = obj.sliceArray(1);
            obj.fig_image.Name = sprintf('Image preview: %s', obj.slice.name);

            obj.imageData = obj.slice.thumbnail;

            r = obj.redSlider.Value;
            g = obj.greenSlider.Value;
            newImage = imadjust(obj.imageData,...
                [0, 0, 0; r, g, 1],...
                [0,0,0;1,1,1]);

            obj.ax_image.XLim = [0 size(obj.imageData,2)];
            obj.ax_image.YLim = [0 size(obj.imageData,1)];

            [blankIm,maskNew] =  createEditableMask(obj.imageData, obj.slice.mask);
            obj.imgHandle.CData = newImage;

            if obj.negative == false
                obj.maskIm.AlphaData =  maskNew .* obj.maskSlider.Value;
            elseif obj.negative == true
                obj.maskIm.AlphaData =  ~maskNew .* obj.maskSlider.Value;
            end

            obj.maskIm.CData =  blankIm.*obj.maskLum;

        end

        function luminanceManager(obj,src,valueChangedData)
            if  strcmp(valueChangedData.Source.Tag, 'rSl')
                if ~checkChannelImage(obj.imgHandle.CData,1)
                    src.Value = valueChangedData.PreviousValue;
                    return
                end
                newImage = imadjust(obj.imageData(:,:,1),...
                    [0, valueChangedData.Value],...
                    [0,1]);
                obj.imgHandle.CData(:,:,1) = newImage;

            elseif strcmp(valueChangedData.Source.Tag, 'gSl')
                if ~checkChannelImage(obj.imgHandle.CData,2)
                    src.Value = valueChangedData.PreviousValue;
                    return
                end
                newImage = imadjust(obj.imageData(:,:,2),...
                    [0, valueChangedData.Value],...
                    [0,1]);
                obj.imgHandle.CData(:,:,2) = newImage;

            elseif strcmp(valueChangedData.Source.Tag, 'mSl')
                if obj.maskIm.Visible == false
                    src.Value = valueChangedData.PreviousValue;
                    return
                end
                newImage = (obj.maskIm.AlphaData >0).*valueChangedData.Value;
                obj.maskIm.AlphaData = newImage;

            end
        end

        function closeFunction(obj,~,~)
            delete(obj.fig_image)
            delete(obj.fig_lumSlid)
            delete(obj.fig_controls)
        end
    end
end