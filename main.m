%% Folder definitions
folder.code = 'C:\dev\workspaces';

%% Add paths
addpath(genpath(fullfile(folder.code, 'roiClassGUI')))

%% Parameters
classThresholds = [55 85];
bloodThreshold = 20;

%% Initialize python etc
pyenv(Version="C:\Users\Sylvia\anaconda3\python.exe");
py.importlib.import_module('numpy');

%% Load data
ops = py.numpy.load('ops.npy', allow_pickle=true).item();
ops = dictionary(ops);

stat = py.numpy.load('stat.npy', allow_pickle=true);

iscell = double(py.numpy.load('iscell.npy', allow_pickle=true));
isgood = find(iscell(:,1) == 1);

%% Get necessary variables: image, ROI + neuropil masks
meanImg = ops("meanImg_chan2");
meanImg = double(meanImg{1});

Ly = ops("Ly");
Ly = double(Ly{1});
Lx = ops("Lx");
Lx = double(Lx{1});

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
    neuropils{k} = double(pyrun(str, "npix", s = stat));
end

opsGUI.classThresholds = classThresholds;
opsGUI.bloodThreshold = bloodThreshold;
opsGUI.xrange = 1:Lx;
opsGUI.yrange = 1:Ly;

[classes, opsDetect] = classifyCells(meanImg, ROIs, neuropils, opsGUI);
isInhibitory = NaN(size(iscell,1),1);
isInibitory(isgood) = classes;

% save isInhibitory & opsDetect (as python dictionary)