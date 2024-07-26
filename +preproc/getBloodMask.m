function totalMask = getBloodMask(cellImage, bloodVal, bloodSize, filterVal)
% Classify image pixels as background (dark regions) based on current
% thresholds.

% translate background threshold from percentile to pixel value
lumThresh = prctile(cellImage(:), bloodVal);
% get background mask (pixels below background threshold)
lumMask = cellImage <= lumThresh;
% normalize image to range [0 1]
ciNorm = single((cellImage - min(cellImage,[],'all')) / ...
    max(cellImage,[],'all'));
% saturate bottom and top 1% of pixel values
ciNorm = imadjust(ciNorm);
% enhance local contrast (local Laplacian filtering)
ciNorm = locallapfilt(ciNorm,1,filterVal,1);
% translate background threshold from percentile to pixel value (on
% filtered image)
filterThresh = prctile(ciNorm(:), bloodVal);
% get background mask of filtered image
filterMask = ciNorm <= filterThresh;
% combine background and filter masks
totalMask = lumMask | filterMask;
% ignore mask areas that are too small
totalMask = bwareafilt(totalMask, round([numel(cellImage) * ...
    bloodSize / 100, numel(cellImage)]));
% perform morphological closing on mask to smooth edges and close holes
totalMask = ~bwmorph(totalMask, 'close');