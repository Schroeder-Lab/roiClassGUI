function [cellClasses, cellValues, surrPrctiles] = ...
    getCellClasses(classImage, ROIs, neuropils, ops)

cellClasses = NaN(length(ROIs),1);
cellValues = NaN(length(ROIs),1);
surrPrctiles = NaN(length(ROIs),100);

if ~isfield(ops, 'classThresholds')
    ops.classThresholds = [30 70]; % thresholds in percentiles to classify
                                   % cells as not marked, unknown, and
                                   % marked
end
if ~isfield(ops, 'bloodThreshold')
    ops.bloodThreshold = 0; % 0-100% maximum pixel value to count as blood vessel
end
if ~isfield(ops, 'bloodSize')
    ops.bloodSize = 0; % 0-100%; minimum size to count as blood vessel
end

bloodThresh = prctile(classImage(:), ops.bloodThreshold);
bloodInd = classImage <= bloodThresh;
bloodInd = bwareafilt(bloodInd, round([numel(classImage) * ops.bloodSize / 100, ...
    numel(classImage)]));
bloodMask = ~bwmorph(bloodInd, 'close');
bloodMask = find(bloodMask);

% xVals = linspace(min(classImage(:)), max(classImage(:)), 100);
for iCell = 1:length(ROIs)
    cellValues(iCell) = median(classImage(ROIs{iCell}));
    surrVals = classImage(intersect(neuropils{iCell}, bloodMask));
    threshs = prctile(surrVals, ops.classThresholds);
    surrPrctiles(iCell,:) = prctile(surrVals, 1:100);
    if cellValues(iCell) <= threshs(1)
        cellClasses(iCell) = -1;
    elseif cellValues(iCell) >= threshs(2)
        cellClasses(iCell) = 1;
    else
        cellClasses(iCell) = 0;
    end
end