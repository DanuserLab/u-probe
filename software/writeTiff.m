function writeTiff(img, filename, bits, append_to_end)
% writeTiff - Save image data as a multi-frame TIFF with specified bit depth.
%
% This function writes a image matrix to a TIFF file. It supports
% bit depths of 8, 16, 32, and 1 (binary) and allows appending to an
% existing TIFF file if required.
%
% Syntax:
%    writeTiff(img, filename, bits, append_to_end)
%
% Inputs:
%    img - Image data matrix.
%    filename - Name (with path) of the output TIFF file.
%    bits - Bit depth (1, 8, 16, or 32). Defaults to 32 if not provided.
%    append_to_end - (Optional) Logical flag to append to an existing file (default: false).
%
% Notes:
%    - If append_to_end is false or omitted, the function overwrites any existing file.
%    - The function converts the image to the appropriate type based on the specified bit depth.
%
% Example:
%    writeTiff(rand(256, 256, 3), 'output_image.tif', 16, false);
%
% Adapted from MATLAB TIFF documentation (https://www.mathworks.com/help/matlab/ref/tiff.html)
% 
% Written by Saygin Gulec sayging@live.unc.edu from Klaus Hahn's lab, 2024
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

if ~exist("append_to_end","var")
    append_to_end = 0;
end

if ~append_to_end
    % Overwrite
    warning('off','MATLAB:DELETE:FileNotFound')
    delete(filename)
    warning('on','MATLAB:DELETE:FileNotFound') 
end

% Boilerplate
tagstruct.ImageLength = height(img);
tagstruct.ImageWidth = width(img);
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
tagstruct.Software = 'MATLAB';
tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
tagstruct.SamplesPerPixel = 1;
if exist("bits","var")
    tagstruct.BitsPerSample = bits;
    if bits == 32
        img = single(img);
        tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
    elseif bits == 16
        img = uint16(img);
        tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
    elseif bits == 8
        img = uint8(img);
        tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
    elseif bits == 1
        img = logical(img);
        tagstruct.SampleFormat = Tiff.SampleFormat.UInt;
    else
        error("Unsupported bit-depth.")
    end
else
    tagstruct.BitsPerSample = 32;
    img = single(img);
end

% Write each frame
for frame = 1:size(img,3)
    t = Tiff(filename,"a");
    setTag(t,tagstruct)
    write(t,img(:,:,frame))
    close(t)
end

end