function totalMask = getBloodMask(cellImage, bloodVal, bloodSize, filterVal)

lumThresh = prctile(cellImage(:), bloodVal);
lumMask = cellImage <= lumThresh;
ciNorm = single((cellImage - min(cellImage,[],'all')) / ...
    max(cellImage,[],'all'));
ciNorm = imadjust(ciNorm);
ciNorm = locallapfilt(ciNorm,1,filterVal,1);
filterThresh = prctile(ciNorm(:), bloodVal);
filterMask = ciNorm <= filterThresh;
totalMask = lumMask | filterMask;
totalMask = bwareafilt(totalMask, round([numel(cellImage) * ...
    bloodSize / 100, numel(cellImage)]));
totalMask = ~bwmorph(totalMask, 'close');