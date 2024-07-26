%% Folder definitions
% folder.code = 'C:\Repositories\roiClassGUI';
% folder.python = "C:\Users\liad0\anaconda3\python.exe";
folder.code = 'C:\dev\workspaces';
folder.python = "C:\Users\Sylvia\anaconda3\python.exe";

%% Add paths
addpath(genpath(fullfile(folder.code, 'roiClassGUI')))

%% Parameters
classThresholds = [55 85]; % thresholds for positive and negative ROIs 
                           % (in percentiles)
bloodThreshold = 20; % threshold below which pixels are considered background 
                     % (not considered for surround calculation)
                     % (in percentiles)
refineThreshold = 0.2; % spatial parameter for local Laplacian filtering (local contrast)
bloodSize = 0.03;    % minimum size of background areas (in percent of all pixels)

if isfile('cellTypes.mat')
    data = load('cellTypes.mat');  
    bloodThreshold = data.bTh;  
    classThresholds = data.cTh; 
    refineThreshold = data.rTh;   
    bloodSize = data.bs;
end

%% Initialize python etc
pyenv(Version = folder.python);
py.importlib.import_module('numpy');

%% Load data
try
    ops = py.numpy.load('ops.npy', allow_pickle=true).item();
catch
    warning('Current folder does NOT contain suite2p output files.')
    return
end

stat = py.numpy.load('stat.npy', allow_pickle=true);

iscell = double(py.numpy.load('iscell.npy', allow_pickle=true));
% only consider 
isgood = find(iscell(:,1) == 1);

%% Get necessary variables: image, ROI + neuropil masks
% mean image of red imaging channel
meanImg = ops{"meanImg_chan2"};
meanImg = double(meanImg);

% size of mean image (in pixels)
Ly = ops{"Ly"};
Ly = double(Ly);
Lx = ops{"Lx"};
Lx = double(Lx);

% get pixel locations of ROI masks and corresponding neuropil masks
ROIs = cell(length(isgood), 1);
neuropils = cell(length(isgood), 1);
for k = 1:length(ROIs)
    id = isgood(k) - 1;
    str = sprintf("ypix = s[%d]['ypix'][~s[%d]['overlap']]", id, id);
    ypix = double(pyrun(str, "ypix", s = stat));
    str = sprintf("xpix = s[%d]['xpix'][~s[%d]['overlap']]", id, id);
    xpix = double(pyrun(str, "xpix", s = stat));
    ROIs{k} = sub2ind([Ly Lx], ypix, xpix)';

    str = sprintf("npix = s[%d]['neuropil_mask']", id);
    npix = double(pyrun(str, "npix", s = stat));
    [nx, ny] = ind2sub([Lx Ly], npix);
    neuropils{k} = sub2ind([Ly Lx], ny, nx);
end

opsGUI.classThresholds = classThresholds;
opsGUI.bloodThreshold = bloodThreshold;
opsGUI.refineThreshold = refineThreshold;
opsGUI.bloodSize = bloodSize;
opsGUI.xrange = 1:Lx;
opsGUI.yrange = 1:Ly;

% call GUI
[classes, opsDetect] = classifyCells(meanImg, ROIs, neuropils, opsGUI);