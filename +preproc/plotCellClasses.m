function [ci, bloodMask, bloodHandle, lines] = ...
    plotCellClasses(classImage, ROIs, classes, ops, ax)
% Plot image, edges of ROI masks color coding the cell class, and
% background mask.

if nargin < 5
    figure
    ax = gca;
end

if ~isfield(ops, 'bloodThreshold')
    ops.bloodThreshold = 0; % 0-100% maximum pixel value to count as blood vessel
end
if ~isfield(ops, 'refineThreshold')
    ops.refineThreshold = 1; % 0-100% maximum pixel value to count as blood vessel
end
if ~isfield(ops, 'bloodSize')
    ops.bloodSize = 0; % 0-100%; minimum size to count as blood vessel
end
if ~isfield(ops, 'colors')
    ops.colors = [0 .7 0; 0 0 1; 0.75 0 0.75];
end

% translate image into RGB matrix using "hot" colormap
classImage = double(classImage);
ci = classImage - min(classImage(:));
ci = round(ci ./ max(ci(:)) .* 255 + 1);
ci = ind2rgb(ci, hot(256));

% determine background/blood mask
bloodMask = preproc.getBloodMask(classImage, ops.bloodThreshold, ...
    ops.bloodSize, ops.refineThreshold);

axes(ax);
% plot image
imshow(ci)
hold on
% overlay with gray pixels
blood = ones(size(ci(:,:,1)));
bloodHandle = imshow(blood, ones(1,3)*0.5);
% make gray values of non-background pixels transparent 
alpha(bloodHandle, single(~bloodMask));

% add edges of ROI masks
lines = NaN(1, length(ROIs));
if ~all(isnan(classes))
    % choose edge colors according to cell classification
    colors = repmat(ops.colors(3,:), length(ROIs),1);
    colors(classes == 1,:) = repmat(ops.colors(1,:), sum(classes == 1), 1);
    colors(classes == -1,:) = repmat(ops.colors(2,:), sum(classes == -1), 1);
    for iCell = 1:length(ROIs)
        tmp = zeros(size(classImage));
        tmp(ROIs{iCell}) = 1;
        perim = bwperim(tmp, 8);
        [yPerim, xPerim] = find(perim);
        lines(iCell) = plot(xPerim,yPerim,'.', ...
            'Color', colors(iCell,:), 'MarkerSize', 3);
    end
end