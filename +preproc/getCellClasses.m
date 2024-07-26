function [cellClasses, cellValues, surrPrctiles] = ...
    getCellClasses(classImage, ROIs, neuropils, ops)
% Classify all ROIs based on their median pixel mask value compared to the 
% pixel values of their surrounds (neuropil masks).

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

% get blood/background masks
bloodMask = preproc.getBloodMask(classImage, ops.bloodThreshold, ...
    ops.bloodSize, ops.refineThreshold);
bloodMask = find(bloodMask);

% loop across all ROIs
for iCell = 1:length(ROIs)
    % get median value from all pixels inside ROI mask (strength of label)
    cellValues(iCell) = median(classImage(ROIs{iCell}));
    % get all pixel values of ROI's neuropil mask, ignore pixels inside
    % background/blood vessels (dark regions)
    surrVals = classImage(intersect(neuropils{iCell}, bloodMask));
    % get ROI's class tresholds based on its neuropil values and current
    % thresholds
    threshs = prctile(surrVals, ops.classThresholds);
    % get percentiles (1-100) of neuropil values for easy updates of cell
    % class later when only labelling thresholds are changed
    surrPrctiles(iCell,:) = prctile(surrVals, 1:100);
    % determine cell class for ROI
    if isempty(intersect(ROIs{iCell}, bloodMask))
        % ROI is completely outside blood masks, i.e. it is as dark as
        % background
        cellClasses(iCell) = -1;
    elseif cellValues(iCell) <= threshs(1)
        cellClasses(iCell) = -1;
    elseif cellValues(iCell) >= threshs(2)
        cellClasses(iCell) = 1;
    else 
        % ROI value is between both thresholds OR
        % surround is completely outside blood mask (threshs = NaN)
        cellClasses(iCell) = 0;
    end
end