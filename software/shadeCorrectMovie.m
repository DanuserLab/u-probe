function movieData = shadeCorrectMovie(movieData,paramsIn)

% 
% movieData = shadeCorrectMovie(movieData)
% 
% movieData = shadeCorrectMovie(movieData,paramsIn)
% 
%
% This function corrects the input movie for uneven illumination using
% "shade correction" images - Images taken of a blank area of a coverslip.
% If multiple shade correction images were taken, they are averaged. Also
% they can be spatially and/or median filtered to reduce noise and "hot
% pixels"
% 
% 
% Input:
% 
%   movieData - The movieData object describing the movie, as created using
%   setupMovieDataGUI.m
%
%   paramsIn - Structure with inputs for optional parameters. The
%   parameters should be stored as fields in the structure, with the field
%   names and possible values as described below:
% 
%   Possible Parameter Structure Field Names:
%       ('FieldName' -> possible values)
%
%       ('OutputDirectory' -> character string) Optional. A character
%       string specifying the directory to save the corrected images to.
%       Corrected images for different channels will be saved as
%       sub-directories of this directory. If not input, the corrected
%       images will be saved to the same directory as the movieData, in a
%       sub-directory called "shade_corrected_images"
%
%       ('ChannelIndex'-> Positive integer scalar or vector) The integer
%       indices of the channel(s) to perform shade correction on. This
%       index corresponds to the channel's location in the array
%       movieData.channels_. If not input, all channels will be corrected.
%   
%       ('ShadeImageDirectories'->Cell array of character arrays) This cell
%       array specifies the folder(s) containing the shade-correction
%       images for each channel. It must have a directory for each channel
%       to be corrected, though multiple channels may use the same
%       corrections. If not specified, the user will be asked.
%
%       ('MedianFilter' - True/False)
%       If true, the final (averaged) shade correction image will be median
%       filtered with a 3x3 neighborhood.
%       Optional. Default is true.
%
%       ('GaussFilterSigma' -> Positive scalar, >= 1.0)
%       This specifies the sigma (in pixels) of the gaussian filter to
%       apply to the final (averaged) shade correction image. If less than
%       one, no gaussian filtering is performed.
%       Optional. Default is 0 ( no filtering ).
%
%       ('Normalize' -> 0,1,2)
%       If set to 1, they will be divided by their own mean, resulting in
%       their mean being equal to one.        
%       If set to 2, the processed/averaged shade images will be divided by
%       their combined mean intensity. This results in their means being
%       nearer to one, minimizing rounding error in the final
%       shade-corrected image, while preserving their relative intensities.
%       If set to 0, no normalization will be done.
%       Default is 1.
%
%       ('BatchMode' -> True/False)
%       If this option value is set to true, all graphical output is
%       suppressed.
%
%   
% Output:
%
%   movieData - the updated movieData object with the correction
%   parameters, paths etc. stored in it, in the field movieData.processes_.
%
%   The corrected images are written to the directory specified by the
%   parameter OuptuDirectory, with each channel in a separate
%   sub-directory. They will be stored as bit-packed .tif files. 
%
%
% Hunter Elliott
% 11/2009
% Revamped 5/2010
%
% 
% Modified by
% Qiongjing (Jenny) Zou, Jan 2019
% Added section "Do Dark Current Correction for Shade Correction Images" as Hunter requested by email in May 2018
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


%% ------ Parameters ------- %%

pString = 'shade_corrected_'; %The string to prepend before the shade-corrected image directory & channel name
saveName = 'shade_correction_image_for_channel'; %File name for saving processed/avged shade images. Actual file name will have channel name appended.
dName = 'shade_corrected_images_for_channel_';%String for naming the directories for each corrected channel

%% ----------- Input ------------ %%


%Check that input object is a valid moviedata
if ~isa(movieData,'MovieData')
    error('The first input argument must be a valid MovieData object!')
end

if nargin < 2
    paramsIn = [];
end

%Find the dark-current correction process, as this should have already been
%performed.
iDarkProc = find(cellfun(@(x)(isa(x,'DarkCurrentCorrectionProcess')),movieData.processes_),1);                          

%Get the indices of any previous shade correction processes from this function                                                                              
iProc = find(cellfun(@(x)(isa(x,'ShadeCorrectionProcess')),movieData.processes_),1);                          

%If the process doesn't exist, create it with default settings.
if isempty(iProc)
    iProc = numel(movieData.processes_)+1;
    movieData.addProcess(ShadeCorrectionProcess(movieData,movieData.outputDirectory_));                                                                                                 
end

%Parse input, store in parameter structure
p = parseProcessParams(movieData.processes_{iProc},paramsIn);

nChan = numel(movieData.channels_);

if max(p.ChannelIndex) > nChan || min(p.ChannelIndex)<1 || ~isequal(round(p.ChannelIndex),p.ChannelIndex)
    error('Invalid channel numbers specified! Check ChannelIndex input!!')
end

nChanCorr = length(p.ChannelIndex);

if isempty(iDarkProc)
    
    warning('biosensors:shadeCorr:noDKCorr',...
        'This movie has not been dark-current corrected yet! It is recommended that you run dark-current correction before shade correction!')    
    %If no dark-current correction, then use raw images.
    movieData.processes_{iProc}.setInImagePath(p.ChannelIndex,movieData.getChannelPaths(p.ChannelIndex));
    hasDarkCorr = false(1,nChanCorr);
    
else    
    
    %Check which channels have been dark-current corrected
    hasDarkCorr = movieData.processes_{iDarkProc}.checkChannelOutput(p.ChannelIndex);    
    
    %Set the input directories to be the output directories of the
    %dark-current correction
    for j = 1:nChanCorr
        if all(hasDarkCorr(j)) %This is what was effectively happening anyways, now the input will be reflected. Quick fix.
            movieData.processes_{iProc}.setInImagePath(p.ChannelIndex(j),...
                movieData.processes_{iDarkProc}.outFilePaths_{1,p.ChannelIndex(j)});    
        else
            if j == 1
                warning('Not all channels have dark-current correction : using raw images. This is not recommended!!')
            end
            movieData.processes_{iProc}.setInImagePath(p.ChannelIndex(j),...
                movieData.getChannelPaths(p.ChannelIndex(j)));            
        end
    end
end



%If not specified, get the directories for each set of shade images.
if isempty(p.ShadeImageDirectories)
    
    %Check if the paths have been specified before
    if all(cellfun(@isempty,movieData.processes_{iProc}.inFilePaths_(2,:)))
        %If not, ask the user.
        stPath = pwd;
        p.ShadeImageDirectories = cell(1,nChanCorr);

        for j = 1:nChanCorr

            p.ShadeImageDirectories{j} = uigetdir(stPath,['Select the directory with shade images for channel ' num2str(p.ChannelIndex(j))]);

            if p.ShadeImageDirectories{j} ~= 0
                stPath = p.ShadeImageDirectories{j};
                movieData.processes_{iProc}.setCorrectionImagePath(p.ChannelIndex(j),p.ShadeImageDirectories{j});            
            else
                p.ShadeImageDirectories{j} = [];            
            end
        end    
        
    else
        %Use the existing paths
        disp('Using previously specified correction image directories...')
        p.ShadeImageDirectories = movieData.processes_{iProc}.inFilePaths_(2,p.ChannelIndex);        
    end
else
    
    movieData.processes_{iProc}.setCorrectionImagePath(p.ChannelIndex,p.ShadeImageDirectories);        
    
end

%% ------------ (NEW) Do Dark Current Correction for Shade Correction Images ----------- %%
if p.DoDarkCurrentCorrectionForShadeImages
    
    % sanity check
    if isempty(p.DarkImageDirectoriesForShadeImages)
        error('Please specify dark-current correction image directories for shade correction images!')
    else
        %Check how many directories were specified
        iDarkDir = find(cellfun(@(x)(~isempty(x)),p.DarkImageDirectoriesForShadeImages));
        iShadeDir = find(cellfun(@(x)(~isempty(x)),p.ShadeImageDirectories));
        
        if length(iDarkDir) < length(iShadeDir)
            error('You must specify a dark-current correction image directory for each shade correction image directory!')
        end
        
        %Check whether dark-current correction images have the same size as shade correction image
        for i = 1:length(iDarkDir)
            DarkfileNames = imDir(p.DarkImageDirectoriesForShadeImages{i},true);
            
            if isempty(DarkfileNames)
                error('lccb:set:fatal', ...
                    ['No proper image files are detected in:\n\n ',p.DarkImageDirectoriesForShadeImages{i}, ...
                    '\n\nPlease double check your channel path.'])
            end
            
            shadeImNames = movieData.processes_{iProc}.getCorrectionImageFileNames(p.ChannelIndex(i));
            ShadeImInfo = imfinfo([p.ShadeImageDirectories{iShadeDir(i)} filesep shadeImNames{1}{1}]);

            for j = 1:length(DarkfileNames)
                DarkImInfo = imfinfo([p.DarkImageDirectoriesForShadeImages{i} filesep DarkfileNames(j).name]);

                if DarkImInfo.Width ~= ShadeImInfo.Width || DarkImInfo.Height ~= ShadeImInfo.Height
                    error('lccb:set:fatal', ...
                        ['Dark current correction image - \n\n',...
                        obj.inFilePaths_{2,i},filesep,DarkfileNames(j).name,...
                        '\n\nmust have the same size as shade correction images. Please double check your dark correction image data.'])
                end
            end
        end
        
    end
    
    %% ----------- Get and Process Dark Current Correction Images ------------- %%
    %Loads, averages, and filters the dark current correction images
    
    disp('Loading and processing dark-current correction image...')
    
    %Go through each requested channel and process the dark current correction
    darkIm = cell(1,nChanCorr);
    for iChan = 1:nChanCorr
        
        % ---- Average the dark images --- %
        darkImFileNames=imDir(p.DarkImageDirectoriesForShadeImages{iChan});
        nDarkIm = length(darkImFileNames);
        
        for iImage = 1:nDarkIm
            
            currIm = imread([p.DarkImageDirectoriesForShadeImages{iChan} filesep darkImFileNames(iImage).name]);
            
            if iImage == 1
                darkIm{iChan} = zeros(size(currIm));
            end
            
            %Average the images together
            darkIm{iChan} = darkIm{iChan} + double(currIm) ./ nDarkIm;
        
        end
        
        %---Filter the averaged dark image---%
        
        %Median filter
        if p.MedianFilter % just use the same parameter as Shade Correction
            %Add a border to prevent distortion
            darkIm{iChan} = medfilt2(darkIm{iChan},'symmetric'); %Uses default 3x3 neighborhood
        end
        
        %Gaussian filter
        if p.GaussFilterSigma >= 1 % just use the same parameter as Shade Correction
            darkIm{iChan} = filterGauss2D(darkIm{iChan},p.GaussFilterSigma);
        end
        
    end
    
    
    %% -------------- Apply dark Correction ------------%%
    %Applies the dark correction from above to each selected channel
    
    disp('Applying dark current correction to shade correction images...')
    
    
    %Go through each image and apply the appropriate dark current correction
    for iChan = 1:nChanCorr
        
        shadeOutDir{iChan} = [p.OutputDirectory filesep ...
            'darkCorrected_shade_images_for_channel_' num2str(p.ChannelIndex(iChan))];    
        %Check/create directory
        mkClrDir(shadeOutDir{iChan});
        
        darkCorrDir = p.DarkImageDirectoriesForShadeImages{iChan};
        shadeCorrDir = movieData.processes_{iProc}.inFilePaths_{2,p.ChannelIndex(iChan)}; %original shade images
        
        disp(['Dark-current correcting channel ' num2str(p.ChannelIndex(iChan)) '...'])
        disp(['Using dark-current correction images in ' darkCorrDir])
        disp(['Correcting images from channel ' num2str(p.ChannelIndex(iChan)) ', resulting images will be stored in ' shadeOutDir{iChan}])
        
        shadeImFileNames = imDir(shadeCorrDir);
        nShadeImages = length(shadeImFileNames);
        
        for iImage = 1:nShadeImages
            
            %Load the image to be corrected
            currIm = imread([shadeCorrDir filesep shadeImFileNames(iImage).name]);
            
            %Check it's class
            ogClass = class(currIm);
            
            %Correct it
            currIm = double(currIm) - darkIm{iChan};
            
            if min(currIm(:)) < 1
                %Make sure that the correction makes sense...
                warning('BIOSENSORS:dkCorrect:badDarkCorr',...
                    'Dark current correction resulted in non-positive image values! Check correction images...')
            end
            
            %Cast to original class
            currIm = cast(currIm,ogClass);
            
            %Write it to disk
            imwrite(currIm,[shadeOutDir{iChan} filesep 'dark_current_corrected_shade_' num2str(iImage,['%0' num2str(floor(log10(nShadeImages))+1) '.f']) '.tif' ]);
            
        end
    end
    
    
    disp('Finished Correcting!')
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% (END NEW) Do Dark Current Correction for Shade Correction Images %%%%%%%%%%%%%%%%%%%%%%%


%% ------------ Init ---------- %%



%Check how many directories were specified
iShadeDir = find(cellfun(@(x)(~isempty(x)),p.ShadeImageDirectories));

if length(iShadeDir) ~= nChanCorr
    error('You must specify a shade correction image directory for each channel you are correcting!')    
end

%Set up the directories for corrected images as sub-directories of the
%output directory, and specify the directories for the images to be
%corrected in the movieData.
for j = 1:nChanCorr;
    
    %Create string for current directory
    currDir = [p.OutputDirectory filesep dName num2str(p.ChannelIndex(j))];    
    
    %Check/create directory 
    mkClrDir(currDir);
    
    %Save this in the process object
    movieData.processes_{iProc}.setOutImagePath(p.ChannelIndex(j),currDir);       

end

% Set the path of the processed correction images
outFilePaths=movieData.processes_{iProc}.outFilePaths_;
for j = 1:nChanCorr;
    outFilePaths{2,p.ChannelIndex(j)} = [p.OutputDirectory filesep saveName ...
        num2str(p.ChannelIndex(j)) '.mat'];
end
movieData.processes_{iProc}.setOutFilePaths(outFilePaths);


%Get the analysis image file names.
if all(hasDarkCorr)
    %Get image file names for input images (dark-current corrected images)
    inNames =  movieData.processes_{iProc}.getInImageFileNames(p.ChannelIndex);
end
    

disp('Starting shade correction...')

nImages = movieData.nFrames_;
nImTot = nImages * nChanCorr;


%% ----------- Get and Process Shade Correction Images ------------- %%
%Loads, averages, filters  and normalizes the shade correction images

disp('Loading and processing shade correction image(s)...')

%Go through each requested channel and process the shade correction
shadeIm = cell(1,nChanCorr);
for iChan = 1:nChanCorr

    %Get the shade image file names.
    if p.DoDarkCurrentCorrectionForShadeImages
        shadeImNames = imDir(shadeOutDir{iChan});
        nShadeIm = length(shadeImNames);
    else
        shadeImNames = movieData.processes_{iProc}.getCorrectionImageFileNames(p.ChannelIndex(iChan));
        nShadeIm = cellfun(@(x) numel(x),shadeImNames);
    end

    % ---- Average the shade images --- %
    for iImage = 1:nShadeIm
        if p.DoDarkCurrentCorrectionForShadeImages
            currIm = imread([shadeOutDir{iChan} filesep shadeImNames(iImage).name]);
        else
            currIm = imread([p.ShadeImageDirectories{iShadeDir(iChan)} ...
                filesep shadeImNames{1}{iImage}]);
        end        
        
        
        if iImage == 1
           shadeIm{iChan} = zeros(size(currIm));
        end
        
        %Average the images together
        shadeIm{iChan} = shadeIm{iChan} + double(currIm) ./ nShadeIm;                
               
        
    end        
    
    %---Filter the averaged shade image---%
    
    %Median filter
    if p.MedianFilter                
        shadeIm{iChan} = medfilt2(shadeIm{iChan},'symmetric');
    end
    
    %Gaussian filter
    if p.GaussFilterSigma >= 1
        shadeIm{iChan} = filterGauss2D(shadeIm{iChan},p.GaussFilterSigma,'symmetric');
    end
    
    if any(shadeIm{iChan} == 0)
        error('Shade images cannot contain zero values! Check shade images!')
    end           
        
    
end

%---Normalize the Shade Images---%
if p.Normalize == 1
    %Divide each image by its own mean
    shadeIm = cellfun(@(x)(x ./ mean(x(:))),shadeIm,'UniformOutput',false);            
elseif p.Normalize == 2
    %Calculate the combined mean of all the shade images
    combMean = mean(cellfun(@(x)(mean(x(:))),shadeIm));
    %Divide each image by this mean
    shadeIm = cellfun(@(x)(x ./ combMean),shadeIm,'UniformOutput',false);
end


%% -------------- Apply shade Correction ------------%%
%Applies the shade correction from above to each selected channel

disp('Applying shade correction to images...')

if ~p.BatchMode
    wtBar = waitbar(0,['Please wait, correcting channel ' num2str(p.ChannelIndex(1)) ' ...']);        
end        

%Go through each image and apply the appropriate shade correction
for iChan = 1:nChanCorr
    
    inDir  = movieData.processes_{iProc}.inFilePaths_{1,p.ChannelIndex(iChan)};    
    outDir = movieData.processes_{iProc}.outFilePaths_{1,p.ChannelIndex(iChan)};
    if p.DoDarkCurrentCorrectionForShadeImages
        corrDir = shadeOutDir{iChan};
    else
        corrDir = movieData.processes_{iProc}.inFilePaths_{2,p.ChannelIndex(iChan)};
    end

    disp(['Shade correcting channel ' num2str(p.ChannelIndex(iChan)) '...'])
    disp(['Correcting images from "' inDir '", resulting images will be stored in "' outDir '"']);     
    disp(['Using correction images from ' corrDir])    
    
    if ~p.BatchMode        
        waitbar((iChan-1)*nImages / nImTot,wtBar,['Please wait, correcting channel ' num2str(p.ChannelIndex(iChan)) ' ...']);        
    end                
    
    for iImage = 1:nImages
    
        %Load the image to be corrected
        if all(hasDarkCorr)
            currIm = imread([inDir filesep inNames{iChan}{iImage}]);
        else
            currIm = movieData.channels_(p.ChannelIndex(iChan)).loadImage(iImage);
        end
        ogClass = class(currIm);
    
        %Correct it
        currIm = double(currIm) ./ shadeIm{iChan};
        %Cast to original class
        currIm = cast(currIm,ogClass);
        
        %Write it to disk        
        imwrite(currIm,[outDir filesep pString num2str(iImage,['%0' num2str(floor(log10(nImages))+1) '.f']) '.tif' ]);
        
        if ~p.BatchMode && mod(iImage,5)
            %Update the waitbar occasionally to minimize slowdown
            waitbar((iImage + (iChan-1)*nImages) / nImTot,wtBar)
        end                        
         
 
    end
end


if ~p.BatchMode && ishandle(wtBar)
    close(wtBar)
end


%% ------------- Output ------- %%

disp('Saving results...')


%Save the averaged/filtered shade images
for i = 1:nChanCorr
    outCorrPath = movieData.processes_{iProc}.outFilePaths_{2,p.ChannelIndex(i)}; 
    processedShadeImage = shadeIm{i}; %#ok<NASGU> %Get this element of save array because the save function sucks.
    save(outCorrPath,'processedShadeImage');
end

%Log the correction in the movieData object and save it

movieData.processes_{iProc}.setDateTime;
movieData.save;

disp('Finished Correcting!')


