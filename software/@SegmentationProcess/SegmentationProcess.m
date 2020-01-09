classdef SegmentationProcess < MaskProcess
    % An abstract superclass of all segmentation processes
%
% Copyright (C) 2020, Danuser Lab - UTSouthwestern 
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

    % Sebastien Besson 4/2011
    
    methods (Access = protected)
        function obj = SegmentationProcess(owner,name,funName, funParams,...
                outFilePaths)
            % Constructor of class SegmentationProcess
            if nargin == 0
                super_args = {};
            else
                super_args{1} = owner;
                super_args{2} = name;
            end
            if nargin > 2
                super_args{3} = funName;
            end
            if nargin > 3
                super_args{4} = funParams;
            end
            if nargin > 5
                super_args{5} = outFilePaths;
            end
            % Call the superclass constructor - these values are private
            obj = obj@MaskProcess(super_args{:});
           
        end
    end
    methods(Static)
        function name =getName()
            name = 'Segmentation';
        end
        function h = GUI()
            h= @abstractProcessGUI;
        end
        function procClasses = getConcreteClasses()
            procClasses = ...
                {@ThresholdProcess;
                 @MultiScaleAutoSegmentationProcess
                 @ThresholdProcess3D;
                 @ExternalSegmentationProcess;
                 @NucSegProcess;
                };
            procClasses = cellfun(@func2str, procClasses, 'Unif', 0);
        end
        
    end
end
