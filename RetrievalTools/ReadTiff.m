% Reads in a .tif-stack-file. Especially required for acquired data sets 
% with µManager, where recorded data is stored in a .tif-stack-file. 
% Input argument must be of type string.

function [Itf_Stack] = ReadTiff(file_name)
        info = imfinfo(file_name);
        for jj=1:size(info,1)
            Itf_Stack(:,:,jj) = imread(file_name, jj, 'Info', info);
        end
end

