function multiScaleAutoSeg(movieDataOrProcess, iChan, varargin)
% MSA_Seg (multi-scale automatic segmentation) 
% Segment a single cell image by combining segmentation
% results obtained at multiple smoothing scales. Since it requires only one
% tuning parameters (tightness) and ‘tightness’=0.5 works well for many cases, 
% it achieves almost automatic segmentation.
% Usage :
%           MSA_Seg(MD, 1, 'tightness', 0.5, 'imagesOut', 1)
% 2017/05/29, Jungsik Noh
% Updated Andrew R. Jamieson Sept. 2017
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


%% ------------------ Input ---------------- %%
ip = inputParser;
ip.addRequired('movieDataOrProcess', @isProcessOrMovieData);
ip.addOptional('paramsIn',[], @isstruct);
ip.parse(movieDataOrProcess, varargin{:});
p = ip.Results;
paramsIn = p.paramsIn; % extra?

[movieData, thisProc] = getOwnerAndProcess(movieDataOrProcess,'MultiScaleAutoSegmentationProcess', true);
MD = movieData;
p = parseProcessParams(thisProc, paramsIn); % in case more parameters passed in.

% MSA Seg Parameters
currType = p.type;
currTightness = p.tightness;

% Sanity Checks
nChan = numel(movieData.channels_);
if max(p.ChannelIndex) > nChan || min(p.ChannelIndex)<1 || ~isequal(round(p.ChannelIndex), p.ChannelIndex)
    error('Invalid channel numbers specified! Check ChannelIndex input!!')
end

% Input paths
% Set up the input directories (input images)
inFilePaths = cell(1, numel(movieData.channels_));
for i = p.ChannelIndex
    if isempty(p.ProcessIndex)
        inFilePaths{1,i} = movieData.getChannelPaths{i};
    else
        inFilePaths{1,i} = movieData.processes_{p.ProcessIndex}.outFilePaths_{1,i}; 
    end
end
thisProc.setInFilePaths(inFilePaths);


% Output paths
dName = 'masks_for_channel_';%String for naming the mask directories for each channel
outFilePaths = cell(1, numel(movieData.channels_));
mkClrDir(p.OutputDirectory);
for iChan = p.ChannelIndex;
    % Create string for current directory
    currDir = [p.OutputDirectory filesep dName num2str(iChan)];
    outFilePaths{1,iChan} = currDir;
    thisProc.setOutMaskPath(iChan, currDir);
    mkClrDir(outFilePaths{1,iChan});

    if p.diagnostics
        currDirStats = [p.OutputDirectory filesep dName num2str(iChan) filesep 'stats'];
        outFilePaths{2,iChan} = currDirStats;
        mkClrDir(outFilePaths{2,iChan});
    end
end

thisProc.setOutFilePaths(outFilePaths);   

%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for iChan = p.ChannelIndex
    if p.diagnostics
        %%% Segmentation Diagnostics
        %% Load images
        I = cell(MD.nFrames_, 1);
        imgStack = [];
        for fr=1:MD.nFrames_
            I{fr} = MD.channels_(iChan).loadImage(fr);
            imgStack = cat(3, imgStack, I{fr});
        end
        imageStats(imgStack, thisProc, iChan);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% prep for parfor linearization 
pRunSet = {}; cell(MD.nFrames_ * length(p.ChannelIndex));
outDir = {}; 

i = 1;
for chIdx = p.ChannelIndex
    imFileNamesF = MD.getImageFileNames(chIdx);
    imFileNames = imFileNamesF{1};
    outDir{chIdx} = thisProc.outFilePaths_{1, chIdx};
    for frameIdx = 1:MD.nFrames_
        pRunSet{i}.chIdx = chIdx; %struct('chIdx', chIdx)
        pRunSet{i}.frameIdx = frameIdx; %struct('chIdx', chIdx)
        imFileNames_pRunSet{chIdx, frameIdx} = imFileNames{frameIdx}; 
        i = i + 1;
    end
end



tic
pString = ['MSA_', 'refined_'];      %Prefix for saving masks to file

parfor pfi = 1:length(pRunSet)

    chIdx = pRunSet{pfi}.chIdx;
    frameIdx = pRunSet{pfi}.frameIdx;

    %% -------- Parameters ---------- %%

    %% Multi Scale Segmentation
    disp('=====');
    disp(['Channel ' , num2str(chIdx), ' Frame: ', num2str(frameIdx)]);    
    im = MD.channels_(chIdx).loadImage(frameIdx);
    refinedMask = multiscaleSeg_im(im, 'type', currType, 'tightness', currTightness);
    imwrite(refinedMask, fullfile(outFilePaths{chIdx}, [pString, imFileNames_pRunSet{chIdx, frameIdx}]));

end



toc
disp('Multi-Scale Automatic Segmentation is done!')

end


function imageStats(imgStack, thisProc, iChan)
    %%% Segmentation Diagnostics
    %% TS of 5 numbers
    MD = thisProc.owner_;
    pixelmat = reshape(imgStack, [], MD.nFrames_);
    pixelmat1 = pixelmat;
    pixelmat1(pixelmat1 == 0) = NaN;

    mts = mean(pixelmat1, 1, 'omitnan');
    medts = median(pixelmat1, 1, 'omitnan');
    q1ts = quantile(pixelmat1, 0.25, 1);
    q3ts = quantile(pixelmat1, 0.75, 1);
    q99ts = quantile(pixelmat1, 0.99, 1);
    q01ts = quantile(pixelmat1, 0.01, 1);

    fts = figure;
    plot(mts)
    hold on

    plot(medts)
    plot(q1ts)
    plot(q3ts)
    plot(q01ts)
    plot(q99ts)
    hold off

    legend('Mean', 'Median', 'Perct25', 'Perct75', 'Perct01', 'Perct99');
    title('Time series of 5 summary statistics');

    %%
    saveas(fts, fullfile(thisProc.outFilePaths_{2,iChan}, 'TS_of_5statistics.png'), 'png')
    saveas(fts, fullfile(thisProc.outFilePaths_{2,iChan}, 'TS_of_5statistics.fig'), 'fig')
end