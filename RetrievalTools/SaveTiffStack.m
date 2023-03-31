% Saves a 2D or 3D MATLAB data array as a .tif-file. If the data array 
% is 3D, the saved file is a 3D .tif-stack. The first input 
% argument is the variable of the data array. 
% The path and filename must be of type string.

function SaveTiffStack(ImageStack,path,filename)
    if ndims(ImageStack) == 2
        minVal = min(min(ImageStack));
        ImageStack = ImageStack - minVal;
        maxVal = max(max(ImageStack));
    else
        minVal = min(min(min(ImageStack)));
        ImageStack = ImageStack - minVal;
        maxVal = max(max(max(ImageStack)));
    end
    
    ImageStack = ImageStack*(2^16/maxVal);
    ImageStack16 = uint16(ImageStack);
    tifffile = fullfile(path, append(filename,'.tif'));
    imwrite(ImageStack16(:,:,1), tifffile)

    for ii= 2:(size(ImageStack16,3))
        imwrite(ImageStack16(:,:,ii), tifffile, 'WriteMode','append')
    end
end

