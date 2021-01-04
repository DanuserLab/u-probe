function refinedMask = multiscaleSeg_im(im, varargin)
% multiscaleSeg Segment a single cell image by combining segmentation
% results obtained at multiple smoothing scales. Since it requires only one
% tuning parameters (tightness) and ‘tightness’=0.5 works well for many cases, 
% it achieves almost automatic segmentation.
%
% Input: an image
% Output: refined mask
%
% 2017/05/29, Jungsik Noh
% Updated Andrew R. Jamieson - Sept. 2017
%
% Copyright (C) 2021, Danuser Lab - UTSouthwestern 
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

ip = inputParser;
ip.addRequired('im');
ip.addParameter('type', 'middle', @(x) ismember(x, {'middle','tight','minmax'}));
ip.addParameter('tightness', -1, @(x) isnumeric(x) && (x==-1 || x >= 0 || x<=1));
ip.addParameter('numModels', -1);
ip.parse(im, varargin{:});
p = ip.Results;


sigmas = [0 0.66 1 1.66 2.5 4];  % unit: pixel (common scales for xxx by xxx size confocal images)
p.MinimumSize = 100;        
p.ObjectNumber = 1;
p.FillHoles = 1;

numModels = numel(sigmas)*2*2;
maskingResultArr = nan(size(im, 1), size(im, 2), numModels);

%%  Gaussian filtering, method, refinement
for k = 1:numel(sigmas)
    currImage = im;

    if sigmas(k) > 0
        currImage = filterGauss2D(currImage, sigmas(k));
    end

    % minmax
    try
        currThresh = thresholdFluorescenceImage(currImage); 
        currMask1 = (currImage >= currThresh);

        p.ClosureRadius = 1;
        refinedMask1 = maskRefinementCoreFunc(currMask1, p);
        maskingResultArr(:,:, 4*(k-1)+1) = refinedMask1;

        p.ClosureRadius = 3;
        refinedMask1 = maskRefinementCoreFunc(currMask1, p);
        maskingResultArr(:,:, 4*(k-1)+2) = refinedMask1;

    catch
        disp(['GaussFilterSigma: ', num2str(sigmas(k))])
        disp('Error in minmax thresholding')
        maskingResultArr(:,:, 4*(k-1)+1) = nan(size(currImage, 1), size(currImage, 2));
        maskingResultArr(:,:, 4*(k-1)+2) = nan(size(currImage, 1), size(currImage, 2));
    end

    % Rosin
    currThresh = thresholdRosin(currImage); 
    currMask1 = (currImage >= currThresh); 

    p.ClosureRadius = 1;
    refinedMask1 = maskRefinementCoreFunc(currMask1, p);
    maskingResultArr(:,:, 4*(k-1)+3) = refinedMask1;

    p.ClosureRadius = 3;
    refinedMask1 = maskRefinementCoreFunc(currMask1, p);
    maskingResultArr(:,:, 4*(k-1)+4) = refinedMask1;

end



%% sum maskings from multiple methods

res = sum(maskingResultArr(:,:,1:end), 3, 'omitnan');
tab = tabulate(res(:));
tabulate(res(:));

val = tab(:,1);
counts = tab(:,2);

[~, ind] = sort(counts, 'descend');

a = val(ind(1));
b = val(ind(2));
backgroundth = min(a, b);
maskth = max(a, b);


%% ensemble method
if ((p.tightness < 0) && (p.numModels < 0))

    switch p.type
        case 'middle'
        % ensemble method: median number of models
            midNumModel0 = (backgroundth+1+maskth)/2;
            midNumModel = midNumModel0;
        %   midNumModel = max(midNumModel0, halfEffNumModel);  
            % middle of two peaks should be greater than 50% voting. (xx)

            res0 = (res > midNumModel);
            mnum_smallest = maskth;
            mnum_biggest = backgroundth + 1;
            tightness_interp = interp1([mnum_biggest, mnum_smallest], [0, 1], midNumModel);        
            disp('Threshold of votes:'); 
            disp([num2str(midNumModel), ' (tightness: ', num2str(tightness_interp), ')'])

        case 'tight'
        % ensemble: tight        
            res0 = (res >= maskth);
            mnum_smallest = maskth;
            mnum_biggest = backgroundth + 1;
            tightness_interp = interp1([mnum_biggest, mnum_smallest], [0, 1], maskth);        
            disp('Threshold of votes:'); 
            disp([num2str(maskth), ' (tightness: ', num2str(tightness_interp), ')'])

        case 'minmax'
            mnumint = max(ind(1), ind(2))-1:-1:min(ind(1), ind(2))+1;
            tmp = counts(mnumint);
            tmp2 = tmp(2:end) + tmp(1:end-1);
            dif0 = reshape( diff( tmp2 ), [], 1);
            delta = find(([dif0; 1] > 0), 1);
            localMinIndex0 = max(ind(1), ind(2)) - delta - 1;
            localMinIndex = max(localMinIndex0, 1);
            minmaxNumModel = max(val(localMinIndex), backgroundth+1);

            res0 = (res > minmaxNumModel);
            mnum_smallest = maskth;
            mnum_biggest = backgroundth + 1;
            tightness_interp = interp1([mnum_biggest, mnum_smallest], [0, 1], minmaxNumModel);        
            disp('Threshold of votes:'); 
            disp([num2str(minmaxNumModel), ' (tightness: ', num2str(tightness_interp), ')'])
    end

    elseif p.tightness >= 0
        if p.tightness > 1
            error('Tightness should range from 0 to 1.')
        end

        mnum_smallest = maskth;
        mnum_biggest = backgroundth + 1;
        mnum_interp = interp1([0, 1], [mnum_biggest, mnum_smallest], p.tightness);
        tightnessNumModel = round(mnum_interp);

        res0 = (res > tightnessNumModel);
        disp('Threshold of votes:'); 
        disp([num2str(tightnessNumModel), ' (tightness: ', num2str(p.tightness), ')'])

    else
        res0 = (res >= p.numModels);
        disp('Threshold of votes:'); 
        disp(num2str(p.numModels))
end

%% final refinement
p.ClosureRadius = 1;
refinedMask = maskRefinementCoreFunc(res0, p);
 
end

function currMask = maskRefinementCoreFunc(currMask, p)
% maskRefinementCoreFunc is a part of refineMovieMasks.m to implement
% imclose, object number and filling holes.
% 2017/05/29

% ----- Mask Clean Up ------ %
        
seClose = strel('disk',p.ClosureRadius,0);

            %Remove objects that are too small
            if p.MinimumSize > 0
                currMask = bwareaopen(currMask,p.MinimumSize);
            end            
            
            %Perform initial closure operation
            if p.ClosureRadius > 0
                currMask = imclose(currMask,seClose);            
            end            
            
            %%Perform initial opening operation
            %if p.OpeningRadius > 0
            %    currMask = imopen(currMask,seOpen);
            %end
            
        
        
        % ---------- Object Selection -------- %
        
        %Keep only the largest objects
        if ~isinf(p.ObjectNumber)
                
            %Label all objects in the mask
            labelMask = bwlabel(currMask);

            %Get their area
            obAreas = regionprops(labelMask,'Area');       %#ok<MRPBW>

            %First, check that there are objects to remove
            if length(obAreas) > p.ObjectNumber 
                obAreas = [obAreas.Area];
                %Sort by area
                [dummy,iSort] = sort(obAreas,'descend'); %#ok<ASGLU>
                %Keep only the largest requested number
                currMask = false(size(currMask));
                for i = 1:p.ObjectNumber
                    currMask = currMask | labelMask == iSort(i);
                end
            end
        end
        
        % ------ Hole-Filling ----- %
        if p.FillHoles
            
            %If the mask touches the image border, we want to close holes
            %which are on the image border. We do this by adding a border
            %of ones on the sides where the mask touches.
            if any([currMask(1,:) currMask(end,:) currMask(:,1)' currMask(:,end)'])                
                m = size(currMask, 1);
                n = size(currMask, 2);            
                %Add a border of 1s
                tmpIm = vertcat(true(1,n+2),[true(m,1) ...
                                currMask true(m,1)],true(1,n+2));
                
                %Find holes - the largest "hole" is considered to be the
                %background and ignored.
                cc = bwconncomp(~tmpIm,4);                                
                holeAreas = cellfun(@(x)(numel(x)),cc.PixelIdxList);
                [~,iBiggest] = max(holeAreas);                                
                tmpIm = imfill(tmpIm,'holes');
                tmpIm(cc.PixelIdxList{iBiggest}) = false;
                currMask = tmpIm(2:end-1,2:end-1);
             else                        
                 currMask = imfill(currMask,'holes');
            end
        end
        
end
