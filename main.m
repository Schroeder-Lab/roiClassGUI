%% Folder definitions
% folder.code = 'C:\Repositories\roiClassGUI';
% folder.python = "C:\Users\liad0\anaconda3\python.exe";
folder.code = 'C:\dev\workspaces\SchroederLab';
% folder.python = "C:\Users\liad0\anaconda3\python.exe";

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
% Put your repo root first so package import resolves correctly
pyrun("import sys; p=r'C:\dev\workspaces\SchroederLab\suite2p_v1'; sys.path=[x for x in sys.path if x!=p]; sys.path.insert(0,p)");

% Clear previously loaded suite2p modules from cache
pyrun("import sys; [sys.modules.pop(k) for k in list(sys.modules) if k=='suite2p' or k.startswith('suite2p.')]");

% Verify this now works
pyrun("import importlib; m=importlib.import_module('suite2p.extraction.masks'); print(m.__file__)");

% pyenv(Version = folder.python);
py.importlib.import_module('numpy');

%% Load data
nmasks = pyrunfile( ...
    "C:\dev\workspaces\SchroederLab\depth-for-2p\scratch_files\neuropil_masks_wrapper.py", ...
    "masks", folder=pwd);
% nmasks is a py.list of numpy arrays
n = int64(py.len(nmasks));
npixels = cell(n, 1);
for i = 1:n
    npixels{i} = double(nmasks{i});  % or int64() if indices
end

ops_file = 'ops.npy';
db_file = 'db.npy';
if isfile(ops_file)
    hasOps = true;
    ops = py.numpy.load(ops_file, allow_pickle=true).item();
    meanImg = ops{"meanImg_chan2"};
    meanImg = double(meanImg);
    Ly = ops{"Ly"};
    Ly = double(Ly);
    Lx = ops{"Lx"};
    Lx = double(Lx);
elseif isfile(db_file)
    hasOps = false;
    db = py.numpy.load(db_file, allow_pickle=true).item();
    reg_outputs = py.numpy.load('reg_outputs.npy', allow_pickle=true).item();
    meanImg = double(reg_outputs{'meanImg_chan2'});
    Lx = double(db{'Lx'});
    Ly = double(db{'Ly'});
else
    warning('Current folder does NOT contain suite2p output files.')
    return
end

stat = py.numpy.load('stat.npy', allow_pickle=true);

iscell = double(py.numpy.load('iscell.npy', allow_pickle=true));
% only consider 
isgood = find(iscell(:,1) == 1);

%% Get necessary variables: image, ROI + neuropil masks
% mean image of red imaging channel
meanImg = meanImg - min(meanImg);

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
    
    if hasOps
        str = sprintf("npix = s[%d]['neuropil_mask']", id);
        npix = double(pyrun(str, "npix", s = stat));
    else
        npix = npixels{k};
    end
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

% save cell classes as .npy
py.numpy.save('2pRois.isInhibitory.npy', classes)