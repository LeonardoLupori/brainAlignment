function [maskBackground,rescaledMask] =  createEditableMask(imageDisplay, mask)

imageDisplay = imageDisplay(:,:,1);
blankImg = zeros(size(imageDisplay),'uint8');
maxImg = ones(size(imageDisplay),'uint8') * 255;
maskBackground = cat(3,blankImg,round((maxImg).*0.6),maxImg);
% Preprocess the Mask
rescaledMask = mask;
% rescaledMask = uint8(rescale(mask) * 80);
if size(rescaledMask,1) ~= size(imageDisplay,1)
    rescaledMask = imresize(rescaledMask, size(imageDisplay),'nearest');
end