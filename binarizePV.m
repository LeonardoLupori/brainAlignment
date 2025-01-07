function BW = binarizePV(im)
% BW = binarizePV(im)

binarized = imbinarize(im);

if sum(binarized(:)) > 30
    binarized = bwareaopen(binarized,50);
    
    binarized = imerode(binarized,strel('disk',3));
    binarized = bwmorph(binarized,'hbreak',1);
    binarized = imdilate(binarized,strel('disk',3));
    binarized = bwmorph(binarized,'majority',1);
%     binarized = bwmorph(binarized,'fill',3);
    
    % Select the region closest to the center
    L = bwlabel(binarized);
    stats = regionprops(L,'centroid');
    if size(stats,1) >1
        centers = cat(1,stats.Centroid);
        imCenter = [size(binarized,1)/2 size(binarized,2)/2];
        dist = pdist([imCenter;centers],'euclidean');
        dist = squareform(dist);
        dist = dist(2:end,1);
        [~, indMin] = min(dist);
        binarized(L~=indMin)=0;
    end
end

BW = binarized;