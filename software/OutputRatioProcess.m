classdef OutputRatioProcess < DoubleProcessingProcess
    
    %A class for creating ratios by dividing one channel by another using
    %ratioMovie.m
    %
    %Hunter Elliott,
    %6/2010
%
% Copyright (C) 2025, Danuser Lab - UTSouthwestern 
%
% This file is part of BiosensorsPackage.
% 
% BiosensorsPackage is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% BiosensorsPackage is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with BiosensorsPackage.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

    % Add options for user to adjust the up and low intensity limit (color limit)
    % BEFORE saving the output ratio images.
    % If movie saved, it is saved based on the adjusted ratio output
    % images.
    % By Qiongjing (Jenny) Zou, April 2025
    
    methods (Access = public)
        
        function obj = OutputRatioProcess(owner,outputDir,funParams,...
                inImagePaths,outImagePaths)
            
            
            
            super_args{1} = owner;
            super_args{2} = OutputRatioProcess.getName;
            super_args{3} = @outputMovieRatios;
            
            if nargin < 3 || isempty(funParams)
                if nargin <2, outputDir = owner.outputDirectory_; end
                funParams=OutputRatioProcess.getDefaultParams(owner,outputDir);
            end
            
            super_args{4} = funParams;
            
            if nargin > 3
                super_args{5} = inImagePaths;
            end
            if nargin > 4
                super_args{6} = outImagePaths;
            end
            
            obj = obj@DoubleProcessingProcess(super_args{:});
        end
        
        function status = checkChannelOutput(obj,iChan)
            
            %Checks if the selected channels have valid output images
            nChanTot = numel(obj.owner_.channels_);
            if nargin < 2 || isempty(iChan)
                iChan = 1:nChanTot;
            end
            
            status =  arrayfun(@(x)(ismember(x,1:nChanTot) && ...
                (length(dir([obj.outFilePaths_{1,x} filesep '*.tif']))...
                == obj.owner_.nFrames_)),iChan);
        end
        
        function outIm = loadChannelOutput(obj,iChan,iFrame,varargin)
            
            ip =inputParser;
            ip.addRequired('obj');
            ip.addRequired('iChan',@(x) ismember(x,1:numel(obj.owner_.channels_)));
            ip.addRequired('iFrame',@(x) ismember(x,1:obj.owner_.nFrames_));
            ip.addParamValue('output',[],@ischar);
            ip.parse(obj,iChan,iFrame,varargin{:})
            
            %get the image names
            imNames = getOutImageFileNames(obj,iChan);
            % outIm = double(imread([obj.outFilePaths_{1,iChan} filesep imNames{1}{iFrame}]));
            outIm = imread([obj.outFilePaths_{1,iChan} filesep imNames{1}{iFrame}]); % edited 2025-4, output is already double
        end
        
        
        function fileNames = getOutImageFileNames(obj,iChan)
            if obj.checkChannelOutput(iChan)
                fileNames = cellfun(@(x)(imDir(x)),obj.outFilePaths_(1,iChan),'UniformOutput',false);
                fileNames = cellfun(@(x)(arrayfun(@(x)(x.name),x,'UniformOutput',false)),fileNames,'UniformOutput',false);
                nIm = cellfun(@(x)(length(x)),fileNames);
                if ~all(nIm == obj.owner_.nFrames_)
                    error('Incorrect number of images found in one or more channels!')
                end
            else
                error('Invalid channel numbers! Must be positive integers less than the number of image channels!')
            end
            
            
        end
        function figHan = resultDisplay(obj)
            
            figHan = msgbox(['The ratio images have been saved as .tif images to the folder "' ...
                obj.funParams_.OutputDirectory '". They can be viewed with ImageJ or a comparable image viewing program.']);
            
        end

        function outIm = loadOutImage(obj, iChan, iFrame, varargin) % Added 2025-4, b/c DoubleProcessingProcess assumed output is .mat files, but this proc output is tifs
            outIm=obj.loadChannelOutput(iChan, iFrame, varargin{:});
        end
        
        
    end
    methods(Static)
        
        function name = getName()
            name = 'Ratio Output';
        end
        function h = GUI()
            h= @outputRatioProcessGUI;
        end
        
        function funParams = getDefaultParams(owner,varargin)
            % Input check
            ip=inputParser;
            ip.addRequired('owner',@(x) isa(x,'MovieData'));
            ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
            ip.parse(owner, varargin{:})
            outputDir=ip.Results.outputDir;
            
            % Set default parameters
            funParams.OutputDirectory =  [outputDir  filesep 'ratio_tiffs'];
            funParams.ChannelIndex = [];
            % funParams.ScaleFactor = 1000; % removed Scale Factor on 2024-10-8 as per Gabe Kreider-Letterman' request.

            funParams.BatchMode = false;
            funParams.MakeMovie=0;
            funParams.MovieOptions.Saturate=0; % no longer on setting GUI. Do not adjust this! As Clim already customized by user before saving output tif, when saving movie, just use the output Tifs from THIS proc. - 2025-4
            funParams.MovieOptions.ConstantScale=0; % If true, (color axis limits) selected for the first image will be used throughout the movie.
            funParams.MovieOptions.ColorBar=1;
            funParams.MovieOptions.MakeAvi=1; % Change default to make AVI movie, b/c MOV cannot play if produced from matlab 2021a and later
            funParams.MovieOptions.MakeMov=0; 
            
            % Below params added 2025-4 to apply customized clim by value or
            % percent BEFORE save outputRatio images:
            funParams.CustClim = false;
            funParams.CustClimValLow = []; % Lower end of Intensity Limit (Color Limit) set by user. 
            funParams.CustClimValHigh = []; % Higher end of Intensity Limit (Color Limit) set by user.
            funParams.CustClimByValue = true;
            funParams.CustClimPercentLow = 0; % from 0-1 float, e.g. 0.1 cut Clim 10% from lower end
            funParams.CustClimPercentHigh = 0; % from 0-1 float, e.g. 0.1 cut Clim 10% from upper end, like Saturate
            
        end
    end
end