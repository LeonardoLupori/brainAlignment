function [isChannel, isGray] = checkChannelImage(image, channelToCheck)

% [isChannel, isGray] = checkChannelImage(image, channelToCheck)
% 
% Checks wether there is data (not all zeros) on a given channel for an image
% 
% Parameters
% 
% image: 2D or 3D array
%   2D or 3D array containing the image to be checked
% channelToCheck: scalar int
%   an integer defining which channel to check
% 
% Returns
% isChannel: bool
%   if the channel has data (true) or empty (false)
% isGray: bool
%   if the provided image is a grayscale (single channel) image


arguments
    image
    channelToCheck double {mustBeInRange(channelToCheck, 1,2)}
end

if size(image,3) ==1
    isGray = true;
    if channelToCheck>1
        fprintf("Chosen channel exceed image dimensions");
    end
else
    isGray = false;
end

if sum(image(:,:, channelToCheck), 'all') == 0
    isChannel = false;
elseif sum(image(:,:, channelToCheck), 'all') > 0
    isChannel = true;
end

end