classdef BiosensorsPackage < Package
    % A concrete process for Biosensor Package
%
% Copyright (C) 2019, Danuser Lab - UTSouthwestern 
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
    
    methods (Access = public)
        function obj = BiosensorsPackage (owner,varargin)
            % Construntor of class MaskProcess
            if nargin == 0
                super_args = {};
            else
                % Check input
                ip =inputParser;
                ip.addRequired('owner',@(x) isa(x,'MovieObject'));
                ip.addOptional('outputDir',owner.outputDirectory_,@ischar);
                ip.parse(owner,varargin{:});
                outputDir = ip.Results.outputDir;
                
                super_args{1} = owner;
                super_args{2} = [outputDir  filesep 'BiosensorsPackage'];
            end
            % Call the superclass constructor
            obj = obj@Package(super_args{:});
            
        end
        
        function [status processExceptions] = sanityCheck(obj,varargin) % throws Exception Cell Array
            nProcesses = length(obj.getProcessClassNames);
            
            ip = inputParser;
            ip.CaseSensitive = false;
            ip.addRequired('obj');
            ip.addOptional('full',true, @(x) islogical(x));
            ip.addOptional('procID',1:nProcesses,@(x) (isvector(x) && ~any(x>nProcesses)) || strcmp(x,'all'));
            ip.parse(obj,varargin{:});
            full = ip.Results.full;
            procID = ip.Results.procID;
            if strcmp(procID,'all'), procID = 1:nProcesses;end
            
            [status processExceptions] = sanityCheck@Package(obj,full,procID);
            
            if ~full, return; end
            
            validProc = procID(~cellfun(@isempty,obj.processes_(procID)));
            for i = validProc
                parentIndex = obj.getParent(i);
                if length(parentIndex) > 1
                    switch i
                        case 6
                            parentIndex = 2;
                        case 7
                            parentIndex = 6;
                        case 8
                            parentIndex = 6;
                        case 9
                            parentIndex = 6;
                        case 11
                            parentIndex = 9;
                        otherwise
                            parentIndex = parentIndex(1);
                    end
                    
                end
                
                % Check if input channels are included in dependent
                % processes
                if  ~isempty(parentIndex) && ~isempty(obj.processes_{parentIndex})
                    tmp =setdiff(obj.processes_{i}.funParams_.ChannelIndex, ...
                        union(obj.processes_{parentIndex}.funParams_.ChannelIndex,...
                        find(obj.processes_{parentIndex}.checkChannelOutput)));
                    
                    if  ~isempty(tmp)
                        
                        if length(tmp) ==1
                            
                            ME = MException('lccb:input:fatal',...
                                'Input channel ''%s'' is not included in step %d. Please include this channel in %d step or change another input channel for the current step.',...
                                obj.owner_.channels_(tmp).channelPath_, parentIndex, parentIndex);
                        else
                            ME = MException('lccb:input:fatal',...
                                'More than one input channels are not included in step %d. Please include these channels in %d step or change other input channels for the current step.',...
                                parentIndex, parentIndex);
                        end
                        processExceptions{i} = [ME, processExceptions{i}];
                    end
                end
                
                % Check the validity of mask channels in Background
                % Subtraction Process (step 6 in biosensors package)
                if i == 6 &&  ~isempty(obj.processes_{4})
                    tmp = setdiff(obj.processes_{i}.funParams_.MaskChannelIndex, ...
                        union(obj.processes_{4}.funParams_.ChannelIndex,...
                        find(obj.processes_{4}.checkChannelOutput)));
                    
                    if  ~isempty(tmp)
                        if length(tmp) ==1
                            ME = MException('lccb:input:fatal',...
                                'The mask channel ''%s'' is not included in step 4 (Background Mask Creation). Please include this channel in step 4 or change to another channel that has mask.',...
                                obj.owner_.channels_(tmp).channelPath_);
                        else
                            ME = MException('lccb:input:fatal',...
                                'More than one mask channels are not included in step 4 (Background Mask Creation). Please include these channels in step 4 or change to other channels that have masks.');
                        end
                        %                               processExceptions{i} = horzcat(processExceptions{i}, ME);
                        processExceptions{i} = [ME, processExceptions{i}];
                    end
                end
                
                % Check the validity of bleed channels in Bleedthrough
                % Correction Process (step 8 in biosensors package)
                if i == 8 && ~isempty(obj.processes_{6})
                    
                    validChannels = union(obj.processes_{6}.funParams_.ChannelIndex,...
                        find(obj.processes_{6}.checkChannelOutput));
                    correctionChannels = find(sum(obj.processes_{i}.funParams_.Coefficients,2)>0);
                    tmp = setdiff(correctionChannels,validChannels);
                    
                    if  ~isempty(tmp)
                        if length(tmp) ==1
                            ME = MException('lccb:input:fatal',...
                                'The bleedthrough channel ''%s'' is not included in step 6 (Background Subtraction). Please include this channel in step 6 or change to another bleedthrough channel that is background-subtracted.',...
                                obj.owner_.channels_(tmp).channelPath_);
                        else
                            ME = MException('lccb:input:fatal',...
                                'More than one bleedthrough channels are not included in step 6 (Background Subtraction). Please include these channels in step 6 or change to other bleedthrough channels that are background-subtracted.');
                        end
                        %                                 processExceptions{i} = horzcat(processExceptions{i}, ME);
                        processExceptions{i} = [ME, processExceptions{i}];
                    end
                end
                
                % Check the validity of mask channesl in Ratio Process
                % (step 9 in biosensors package)
                if i == 9 && ~isempty(obj.processes_{3})
                    tmp = setdiff(obj.processes_{i}.funParams_.MaskChannelIndex, ...
                        union(obj.processes_{3}.funParams_.ChannelIndex,...
                        find(obj.processes_{3}.checkChannelOutput)));
                    
                    if  ~isempty(tmp)
                        if length(tmp) ==1
                            ME = MException('lccb:input:fatal',...
                                'The mask channel ''%s'' is not included in step 3 (Segmentation). Please include this channel in step 3 or change to another channel that has mask.',...
                                obj.owner_.channels_(tmp).channelPath_);
                        else
                            ME = MException('lccb:input:fatal',...
                                'More than one mask channels are not included in step 3 (Segmentation). Please include these channels in step 3 or change to other channels that have masks.');
                        end
                        %                                 processExceptions{i} = horzcat(processExceptions{i}, ME);
                        processExceptions{i} = [ME, processExceptions{i}];
                    end
                end
                
                % Photobleach and Output step:
                % Check if input channel (single channel) is the numerator of ratio channel
                if ismember(i,[10 11]) &&  ~isempty(obj.processes_{9})
                    hasPBoutput = obj.processes_{9}.checkChannelOutput;
                    
                    if obj.processes_{i}.funParams_.ChannelIndex ~= ...
                            obj.processes_{9}.funParams_.ChannelIndex(1) && ...
                            ~hasPBoutput(obj.processes_{i}.funParams_.ChannelIndex )
                        
                        ME = MException('lccb:input:fatal',...
                            'The input channel of current step must be the numerator of ratio channels. There can be multiple numerator channels generated by Ratioing step (step 9) in multiple times of processing.');
                        processExceptions{i} = [ME, processExceptions{i}];
                        
                    end
                end
                
                % Set the process index of segmentationProcess
                if i == 3 && ~isempty(obj.processes_{2})
                    parseProcessParams(obj.processes_{i},...
                        struct('ProcessIndex',obj.owner_.getProcessIndex(obj.processes_{2})));
                end
                
                % Set the process index of bleedthrough correction
                if i == 8 
                    processIndex=[];
                    for parentProcId = [6 7]
                        parentProc= obj.processes_{parentProcId};
                        if ~isempty(parentProc)
                            processIndex=horzcat(processIndex,...
                                obj.owner_.getProcessIndex(parentProc)); %#ok<AGROW>
                        end
                    end
                    parseProcessParams(obj.processes_{i},struct('ProcessIndex',processIndex));
                end                
            end
            
            % Hard-coded, when processing processes 2,3,7,9,  add mask
            % process to the processes' funParams_.SegProcessIndex
            %
            % If only segmentation process exists:
            %       funParams.SegProcessIndex = [SegmentationProcessIndex]
            %
            % If segmentation and maskrefinement processes both exist:
            %       funParams.SegProcessIndex = [MaskrefinementProcessIndex,  SegmentationProcessIndex]
            %
            
            for i = intersect(validProc, [4 5 7 9])
                if ~isempty(obj.processes_{3}) % Segmentation process
                    
                    segPI = find(cellfun(@(x)isequal(x, obj.processes_{3}), obj.owner_.processes_));
                    if length(segPI) > 1
                        error('User-defined: More than one identical Threshold processes exists in movie data''s process list.')
                    end
                    funParams.SegProcessIndex = segPI;
                    
                    % If mask transformation or ratioing process, find
                    % if any mask refinement is done
                    if i == 7 || i == 9 && ~isempty(obj.processes_{5})
                        segPI = find(cellfun(@(x)isequal(x, obj.processes_{5}), obj.owner_.processes_));
                        if length(segPI) > 1
                            error('User-defined: More than one identical MaskRefinement processes exists in movie data''s process list.')
                        end
                        funParams.SegProcessIndex = cat(2, funParams.SegProcessIndex, segPI);
                    end
                    
                    % if ratioing process, find if there is any mask
                    % refinement process
                    if i == 9
                        segPI=getProcessIndex(obj.owner_,'MaskTransformationProcess',Inf,0);
                        if ~isempty(segPI)
                            funParams.SegProcessIndex = cat(2, funParams.SegProcessIndex, segPI);
                        end
                    end
                else
                    funParams.SegProcessIndex = [];
                end
                parseProcessParams(obj.processes_{i},funParams);
            end
        end
        
    end
    methods (Static)
        
        function name = getName()
            name = 'Biosensors';
        end
        
        function m = getDependencyMatrix(i,j)
            
            m = [0 0 0 0 0 0 0 0 0 0 0;  %1  DarkCurrentCorrectionProcess
                 2 0 0 0 0 0 0 0 0 0 0;  %2  ShadeCorrectionProcess
                 0 1 0 0 0 0 0 0 0 0 0;  %3  SegmentationProcess
                 0 0 1 0 0 0 0 0 0 0 0;  %4  BackgroundMasksProcess
                 0 0 1 0 0 0 0 0 0 0 0;  %5  MaskRefinementProcess
                 0 1 0 1 0 0 0 0 0 0 0;  %6  BackgroundSubtractionProcess
                 0 0 1 0 2 1 0 0 0 0 0;  %7  TransformationProcess
                 0 0 0 0 0 1 2 0 0 0 0;  %8  BleedthroughCorrectionProcessj
                 0 0 1 0 2 1 2 2 0 0 0;  %9  RatioProcess
                 0 0 0 0 0 0 0 0 1 0 0;  %10 PhotobleachCorrectionProcess
                 0 0 0 0 0 0 0 0 1 2 0]; %11 OutputRatioProcess
            if nargin<2, j=1:size(m,2); end
            if nargin<1, i=1:size(m,1); end
            m=m(i,j);
        end
        
        function varargout = GUI(varargin)
            % Start the package GUI
            varargout{1} = biosensorsPackageGUI(varargin{:});
        end
        function procConstr = getDefaultProcessConstructors(index)
            biosensorsConstr = {
                @DarkCurrentCorrectionProcess,...
                @ShadeCorrectionProcess,...
                @ThresholdProcess,...
                @BackgroundMasksProcess,...
                @MaskRefinementProcess,...
                @BackgroundSubtractionProcess,...
                @TransformationProcess,...
                @BleedthroughCorrectionProcess,...
                @RatioProcess,...
                @PhotobleachCorrectionProcess,...
                @OutputRatioProcess...
                };
            if nargin==0, index=1:numel(biosensorsConstr); end
            procConstr=biosensorsConstr(index);
        end
        function classes = getProcessClassNames(index)
            biosensorsClasses = {
                'DarkCurrentCorrectionProcess',...
                'ShadeCorrectionProcess',...
                'SegmentationProcess',...
                'BackgroundMasksProcess',...
                'MaskRefinementProcess',...
                'BackgroundSubtractionProcess',...
                'TransformationProcess',...
                'BleedthroughCorrectionProcess',...
                'RatioProcess',...
                'PhotobleachCorrectionProcess',...
                'OutputRatioProcess'};
            if nargin==0, index=1:numel(biosensorsClasses); end
            classes=biosensorsClasses(index);
        end
        
        function tools = getTools(index)
            biosensorsTools(1).name = 'Bleedthrough coefficient calculation';
            biosensorsTools(1).funHandle = @calculateBleedthroughGUI;
            biosensorsTools(2).name = 'Alignement/Registration Transform Creation';
            biosensorsTools(2).funHandle = @transformCreationGUI;
            if nargin==0, index=1:numel(biosensorsTools); end
            tools=biosensorsTools(index);
        end
    end
    
end