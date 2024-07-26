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

bloodMask = preproc.getBloodMask(classImage, ops.bloodThreshold, ...
    ops.bloodSize, ops.refineThreshold);
bloodMask = find(bloodMask);

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