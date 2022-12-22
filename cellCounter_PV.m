classdef cellCounter_PV < handle
    properties
        fig_image
        fig_ui
        fig_lumSlid
        
        ax_image
        imgHandle
        pointHandle
        blackSlider
        whiteSlider
        
        edtSigma
        edtBright
        edtRound
        
        imgName
        imageData           % Original loaded image
        mask
        pointsCoord = []    % List of (XY) raw points coordinates
        roi_delPoints = []  % handle of the ROI object for deleting points
        radiusDelPoints = 10;
        
        modes = {'explore','count'};    % List of app mode names
        mode = 1;                       % app mode. Can be 1 (explore) or 2 (count)
        
        
        % Default values for the app
        defVals = struct('blackValue',0,...
            'whiteValue', 0.7,...
            'csvPath',[],...
            'saveCsvPath',[],...
            'loadImgPath',[]);
    end
    
    methods
        %------------------------------------------------------------------
        % CLASS CONSTRUCTOR METHOD
        %------------------------------------------------------------------
        function app = cellCounter_PV(imagePath) 
            % app = cellCounter_PV() 
            % app = cellCounter_PV(imagePath) 
            %
            % cellCounter_PV is a GUI for interactive automatic counting of
            % cells and for the manual refinement of the automatic count
            
            
            % Arguments validation
            arguments
                imagePath char = 'coins.png' % Load default Image 
            end
            
            [~, app.imgName, ~] = fileparts(imagePath);
            app.imageData = imread(imagePath);
            app.mask = ones(size(app.imageData));
            screenSize =  get(0, 'ScreenSize');
            
            %--------------------------------------------------------------
            % Main Image figure
            %--------------------------------------------------------------
            width = 1200;
            heigth = 800;
            app.fig_image = figure('Color',[0.1,0.1,0.1],...
                'Position',[(screenSize(3)-width)/2 (screenSize(4)-heigth)/2 width heigth],...
                'Name','PV Cell Counter',...
                'NumberTitle','off',...
                'WindowKeyPressFcn', @app.keyParser,...
                'CloseRequestFcn',@app.closeFunction,...
                'Pointer','hand');
            % Create the axes
            app.ax_image = axes('Parent',app.fig_image,...
                'Units','normalized',...
                'Position',[0 0 1 .95]);
            % Plot image
            app.imgHandle = imshow(imadjust(app.imageData, [app.defVals.blackValue,app.defVals.whiteValue], [0,1]),...
                'Parent', app.ax_image);
            
            % For graphical design
            app.ax_image.Title.String = upper(app.modes{app.mode});
            app.ax_image.Title.FontSize = 16;
            app.ax_image.Title.Color = [0,.7,.7];
            
            % For interactivity
            app.imgHandle.HitTest = 'off';      % The image wont catch button press events
            app.ax_image.PickableParts = 'all'; % The axis will be clickable
            
            
            %--------------------------------------------------------------
            % UI and options figure
            %--------------------------------------------------------------
            width = 250;
            heigth = 450;
            app.fig_ui = uifigure('Resize', 'off',...
                'Name', 'Cell Counter',...
                'NumberTitle','off',...
                'Position',[25, (screenSize(4)-heigth-50), width, heigth],...
                'CloseRequestFcn',@app.closeFunction);
            grid = uigridlayout(app.fig_ui,...
                'ColumnWidth',{'1x','2x'},...
                'RowHeight',{'1x','fit','fit','fit','fit','1x','1x','fit','fit','fit','1x','1x'});
            loadImgBtn = uibutton('Parent',grid,'Text','LOAD IMAGE',...
                'FontWeight','bold','ButtonPushedFcn',@app.loadImage);
            loadImgBtn.Layout.Column = [1,2];
            
            % TEXT
            uilabel('Parent',grid,'Text','SPACEBAR:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Switch mode');
            uilabel('Parent',grid,'Text','D:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','remove cells');
            uilabel('Parent',grid,'Text','T:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Toggle Cells');
            uilabel('Parent',grid,'Text','M:','FontWeight','bold',...
                'HorizontalAlignment','right');
            uilabel('Parent',grid,'Text','Draw Mask');
            
            % LOAD CSV
            loadBtn = uibutton('Parent',grid,'Text','Load from CSV',...
                'ButtonPushedFcn',@app.loadCSV);
            loadBtn.Layout.Column = [1,2];
            
            % COUNT PV
            autoPVBtn = uibutton('Parent',grid,'Text','Auto Count PV',...
                'ButtonPushedFcn',@app.autoCount_PV);
            autoPVBtn.Layout.Column = [1,2];
            
            app.edtSigma = uieditfield(grid,'numeric','Value',4,'Limits',[1 20],...
                'FontSize',10);
            uilabel('Parent',grid,'Text','Sigma (cell size)','FontSize',10);
            
            app.edtBright = uieditfield(grid,'numeric','Value',6,'Limits',[1 100],...
                'FontSize',10);
            uilabel('Parent',grid,'Text','Brightness [1 100]','FontSize',10);
            
            app.edtRound = uieditfield(grid,'numeric','Value',0.65,'Limits',[-1 1],...
                'FontSize',10);
            uilabel('Parent',grid,'Text','Roundness [-1 1]','FontSize',10);
            
            saveMaskBtn = uibutton('Parent',grid,'Text','Save Mask','ButtonPushedFcn',@app.saveMask);
            saveMaskBtn.Layout.Column = [1,2];
            
            saveBtn = uibutton('Parent',grid,'Text','Save to CSV',...
                'ButtonPushedFcn',@app.saveCSV);
            saveBtn.Layout.Column = [1,2];
            
            %--------------------------------------------------------------
            % Luminance sliders figure
            %--------------------------------------------------------------
            width = 450;
            heigth = 140;
            app.fig_lumSlid = uifigure('Resize', 'off',...
                'Name', 'Luminance Sliders',...
                'NumberTitle','off',...
                'MenuBar','none',...
                'Position',[screenSize(3)-width-25 50 width heigth],...
                'CloseRequestFcn',@app.closeFunction);
            grid = uigridlayout(app.fig_lumSlid,...
                'ColumnWidth',{'1x','5x'},...
                'RowHeight',{'1x', '1x'});
                            
            % Black Control Slider
            uilabel('Parent',grid,'Text','Black');
            app.blackSlider = uislider('Parent', grid,...
                'Value', app.defVals.blackValue,...
                'Limits', [0, 1],...
                'Tag','blkSl',...
                'ValueChangedFcn',@app.luminanceManager);
            
            % White Control Slider
            uilabel('Parent',grid,'Text','White');
            app.whiteSlider = uislider('Parent', grid,...
                'Value', app.defVals.whiteValue,...
                'Limits', [0, 1],...
                'Tag','whtSl',...
                'ValueChangedFcn',@app.luminanceManager);
        end
        
        
        %------------------------------------------------------------------
        % CLASS METHODS
        %------------------------------------------------------------------
        
        function addPoint_callback(app,~,event)
            if event.Button == 1 % Left Click (add a new point)
                newPoint = ceil(event.IntersectionPoint(1:2));
                app.pointsCoord = [app.pointsCoord; newPoint];
                app.updateGraphics()
            elseif event.Button == 3 % Right click (remove points)
                %create a circle polygon
                C = ceil(event.IntersectionPoint(1:2)); % center
                theta = 0: 2*pi/20 :2*pi; % the angle
                circCoord = app.radiusDelPoints * [cos(theta') sin(theta')] + C;
                toDelete = inpolygon(app.pointsCoord(:,1),app.pointsCoord(:,2),circCoord(:,1),circCoord(:,2));
                app.pointsCoord(toDelete,:) = [];
                app.updateGraphics()
            end  
            
        end
        
        function keyParser(app,~,event)
            key = event.Key;
            switch key
                case 'space' % Toggle app mode Explore<->Count
                    toggleAppMode(app)
                case 'd' % Delete points inside the ROI
                    app.deletePoints();
                case 'escape'
                    app.closeFunction();
                case 't'
                    app.pointHandle.Visible = ~app.pointHandle.Visible;
                case 'm'
                    app.drawMask();
            end
        end
        
        function toggleAppMode(app)
            app.mode = mod((app.mode), length(app.modes)) + 1;
            if app.mode == 1
                app.ax_image.ButtonDownFcn = [];
                app.ax_image.Title.Color = [0 .7 .7];
                app.fig_image.Pointer = 'hand';
            elseif app.mode == 2
                app.ax_image.ButtonDownFcn = @app.addPoint_callback;
                app.ax_image.Title.Color = [.7 0 0];
                app.fig_image.Pointer = 'crosshair';
            end
            newTit = upper(app.modes{app.mode});
            app.ax_image.Title.String = newTit;
        end
        
        function deletePoints(app,~,~)
            app.roi_delPoints = drawfreehand(app.ax_image);
            poly = cat(2,app.roi_delPoints.Position(:,1),app.roi_delPoints.Position(:,2));
            toDelete = inpolygon(app.pointsCoord(:,1),app.pointsCoord(:,2),poly(:,1),poly(:,2));
            app.pointsCoord(toDelete,:) = [];
            app.updateGraphics();
            fprintf([datestr(now,'[hh:MM:ss] - ') 'deleted %u cells.\n'], sum(toDelete))
        end
        
        function updateGraphics(app)
            % Delete the freehand selection for deleting points
            if ishandle(app.roi_delPoints)
                delete(app.roi_delPoints)
            end
            % Delete all drawn points if present
            if ishandle(app.pointHandle)
                delete(app.pointHandle)
            end
            % Redraw all the points
            if ~isempty(app.pointsCoord)
                hold(app.ax_image,'on')
                app.pointHandle = plot(app.pointsCoord(:,1),app.pointsCoord(:,2),...
                    'LineStyle','none','Marker','.','LineWidth',1.1,...
                    'MarkerEdgeColor',[1,0,0],'MarkerSize',12);
                app.pointHandle.HitTest = 'off';
                hold(app.ax_image,'off')
            end
            drawnow
        end
        
        function luminanceManager(app,src,valueChangedData)
            if strcmp(valueChangedData.Source.Tag, 'blkSl')
                if valueChangedData.Value >= app.whiteSlider.Value
                    src.Value = valueChangedData.PreviousValue;
                    return
                end
                newImage = imadjust(app.imageData,...
                    [valueChangedData.Value, app.whiteSlider.Value],...
                    [0,1]);
                app.imgHandle.CData = newImage;
            elseif strcmp(valueChangedData.Source.Tag, 'whtSl')
                if valueChangedData.Value <= app.blackSlider.Value
                    src.Value = valueChangedData.PreviousValue;
                    return
                end
                newImage = imadjust(app.imageData,...
                    [app.blackSlider.Value, valueChangedData.Value],...
                    [0,1]);
                app.imgHandle.CData = newImage;
            end
        end
        
        function loadImage(app,~,~)
            tit = 'Choose an Image to count.';
            [file,path] = uigetfile('*',tit, app.defVals.loadImgPath);
            if file ~= 0
                im = imresize(imread([path filesep file]),0.5);
                if size(im,3) > 1
                    im = rgb2gray(im);
                end
                app.imageData = im;
                [~,app.imgName,~] = fileparts(file);
                newImage = imadjust(app.imageData,...
                    [app.blackSlider.Value, app.whiteSlider.Value],...
                    [0,1]);
                app.imgHandle.AlphaData = ones(size(newImage));
                app.mask = ones(size(newImage));
                app.imgHandle.CData = newImage;
                app.ax_image.XLim = [0 size(newImage,2)];
                app.ax_image.YLim = [0 size(newImage,1)];
                app.pointsCoord = [];
                app.defVals.loadImgPath = path;
                app.updateGraphics()
                fprintf([datestr(now,'[hh:MM:ss] - ') 'Image: %s Loaded \n'], app.imgName)
                app.fig_image.Name = ['Current Image:' app.imgName];
                
            end
        end
        
        function loadCSV(app,~,~)
            tit = 'Choose a CSV file with an existing cell count.';
            [file,path] = uigetfile('*.csv',tit,app.defVals.csvPath);
            if file ~= 0
                try
                    t = readtable([path filesep file]);
                    t.Properties.VariableNames = lower(t.Properties.VariableNames);
                    app.pointsCoord = cat(2, t.x/2, t.y/2);
                    app.defVals.csvPath = path;
                    app.updateGraphics();
                    fprintf([datestr(now,'[hh:MM:ss] - ') 'Cells in "%s" loaded!\n'], file)
                catch ME
                    fprintf('UNABLE TO LOAD FILE.\n')
                    fprintf('The following error occurred: %s\nMESSAGE: %s\n', ME.identifier, ME.message)
                end
            end
            
        end
        
        function saveCSV(app,~,~)
            if isempty(app.pointsCoord)
                fprintf('UNABLE TO SAVE FILE.\nNo cells have been counted yet.\n')
                return
            end
            defName = [app.imgName '.csv'];
            %defName = [app.imgName '_' datestr(now,'yymmdd-hhMM') '.csv'];
            tit = 'Select a file to save the current cell count';
            [file, path] = uiputfile('*', tit, [app.defVals.saveCsvPath filesep defName]);
            if file ~= 0
                t = table(app.pointsCoord(:,1)*2,app.pointsCoord(:,2)*2,...
                    'VariableNames',{'x','y'});
                writetable(t,[path filesep file])
                fprintf([datestr(now,'[hh:MM:ss] - ') 'Cells saved in "%s"!\n'], file)
                app.defVals.saveCsvPath = path;
            end
        end
        
        function drawMask(app,~,~)
            app.imgHandle.AlphaData = ones(size(app.imageData));
            roi = drawfreehand(app.ax_image);
            app.mask = roi.createMask();
            app.imgHandle.AlphaData = (~app.mask).*0.3 + app.mask;
            delete(roi)
            fprintf('Selected ROI. Total area: %u pixels.\n', sum(app.mask(:)))
        end
        
        function autoCount_PV(app,~,~)
            app.fig_image.Pointer = 'watch';
            app.fig_ui.Pointer = 'watch';
            % Preprocessing Parameters
            gaussSigma = 20;
            topHatSize = 1;
            closeSize = 1;
            % Cell Detection Parameters
            sigma = app.edtSigma.Value;
            % 'distance to background distribution' threshold; decrease to detect more spots (range [0,~100])
            dist2BackDistThr =  app.edtBright.Value;
            % 'similarity to ideal spot' threshold; decrease to select more spots (range [-1,1])
            spotinessThreshold = app.edtRound.Value;
            
            %##### STEPS FOR PV ######
            imProc = app.imageData - imgaussfilt(app.imageData,gaussSigma);
            imProc = imProc - imtophat(imProc,strel('disk',topHatSize));
            imProc = imclose(imProc,strel('disk',closeSize));
            %##### ORIGINAL STEPS FOR CFOS ######
            % imProc = app.imageData;

            [~,ptSrcImg] = logPSD(imProc, app.mask, sigma, dist2BackDistThr);
            ptSrcImg = selLogPSD(imProc, ptSrcImg, sigma, spotinessThreshold);

            [r,c] = find(ptSrcImg);
            app.pointsCoord = cat(2,c,r);
            
            app.updateGraphics();
            app.fig_image.Pointer = 'arrow';
            app.fig_ui.Pointer = 'arrow';
        end
        
        function saveMask(app,~,~)
            defName = [app.imgName '_mask_' datestr(now,'yymmdd-hhMM') '.mat'];
            tit = 'Select a file to save the current cell count';
            [file, path] = uiputfile('*', tit, [app.defVals.csvPath filesep defName]);
            
            
            if file ~= 0
                ROI = app.mask;
                totalAreaPx = sum(app.mask(:));
                save([path filesep file], 'ROI', 'totalAreaPx')
                fprintf([datestr(now,'[hh:MM:ss] - ') 'Mask saved in "%s"!\n'], file)
            end
        end
        
        function closeFunction(app,~,~)
            delete(app.fig_image)
            delete(app.fig_lumSlid)
            delete(app.fig_ui)
        end
        
    end
end