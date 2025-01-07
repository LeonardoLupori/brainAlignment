function BW = binarizeWFA(im)
% BW = binarizeWFA(im)


binarized = imbinarize(im);

% Computer vision modifications
binarized = bwmorph(binarized,'clean',1);
binarized = bwmorph(binarized,'hbreak',1);
binarized = bwmorph(binarized,'fill',1);
if sum(binarized(:)) > 100
    binarized = bwareaopen(binarized,80);
end

BW = binarized;