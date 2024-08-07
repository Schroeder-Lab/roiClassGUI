%% Initialization of GUI
function varargout = classifyCells(varargin)
% CLASSIFYCELLS MATLAB code for classifyCells.fig
%      CLASSIFYCELLS, by itself, creates a new CLASSIFYCELLS or raises the existing
%      singleton*.
%
%      H = CLASSIFYCELLS returns the handle to a new CLASSIFYCELLS or the handle to
%      the existing singleton*.
%
%      CLASSIFYCELLS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CLASSIFYCELLS.M with the given input arguments.
%
%      CLASSIFYCELLS('Property','Value',...) creates a new CLASSIFYCELLS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before classifyCells_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to classifyCells_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help classifyCells

% Last Modified by GUIDE v2.5 24-May-2024 11:33:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @classifyCells_OpeningFcn, ...
                   'gui_OutputFcn',  @classifyCells_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end



if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before classifyCells is made visible.
function classifyCells_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to classifyCells (see VARARGIN)

handles.output = [];

if length(varargin) < 4
    display('Provide: (1) image, (2) ROIs, (3) neuropils, (4) ops')
    delete(hObject);
    return
end
handles.classImage = varargin{1};
handles.ROIs = varargin{2};
handles.neuropils = varargin{3};
ops = varargin{4};
if ~isfield(ops, 'classThresholds') || length(ops.classThresholds) ~= 2 || ...
        ops.classThresholds(1) > ops.classThresholds(2)
    ops.classThresholds = [30 70];
end
if ~isfield(ops, 'bloodThreshold')
    ops.bloodThreshold = 5;
end
if ~isfield(ops, 'refineThreshold')
    ops.refineThreshold = 1;
end
if ~isfield(ops, 'bloodSize')
    ops.bloodSize = 2;
end
if ~isfield(ops, 'colors')
    ops.colors = [0 .7 0; 0 0 1; 0.75 0 0.75];
end

handles.sliderBloodThresh.Min = 0;
handles.sliderBloodThresh.Max = 100;
handles.sliderBloodThresh.Value = ops.bloodThreshold;
handles.sliderBloodSize.Min = 0;
handles.sliderBloodSize.Max = 1;
handles.sliderBloodSize.Value = ops.bloodSize;
handles.sliderPosThresh.Min = 1;
handles.sliderPosThresh.Max = 100;
handles.sliderPosThresh.Value = ops.classThresholds(2);
handles.sliderNegThresh.Min = 1;
handles.sliderNegThresh.Max = 100;
handles.sliderNegThresh.Value = ops.classThresholds(1);
handles.buttonClasses.Value = 1;
handles.textNeg.BackgroundColor = ops.colors(2,:);
handles.textNoClass.BackgroundColor = ops.colors(3,:);
handles.textPos.BackgroundColor = ops.colors(1,:);

% classify ROIs based on image, ROI masks, neuropil masks, and current
% thresholds
[cellClasses, cellValues, surrPrctiles] = ...
    preproc.getCellClasses(handles.classImage, handles.ROIs, ...
    handles.neuropils, ops);
% plot image with outline of cell masks colored by class
[imageScaled, bloodMask, bloodHandle, lineHandles] = preproc.plotCellClasses( ...
    handles.classImage, handles.ROIs, cellClasses, ops, handles.axesImage);
% plot histogram of mean values across ROIs
threshHandles = plotClassHistogram(cellValues, surrPrctiles, ops.classThresholds, ...
    ops.colors, handles.axesHistogram);

handles.ops = ops;
handles.cellClasses = cellClasses;
handles.cellValues = cellValues;
handles.surrPrctiles = surrPrctiles;
handles.imageScaled = imageScaled;
handles.bloodMask = bloodMask;
handles.bloodHandle = bloodHandle;
handles.lineHandles = lineHandles;
handles.threshHandles = threshHandles;

% Update handles structure
guidata(hObject, handles);

uiwait(hObject);

%% Callback functions (important)
% Show/hide cell masks and blood/background masks
% --- Executes on button press in buttonClasses.
function buttonClasses_Callback(hObject, eventdata, handles)
% hObject    handle to buttonClasses (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = get(hObject, 'Value');
if val == 0
    set(handles.lineHandles, 'Visible', 'off');
    alpha(handles.bloodHandle, 0);
else
    set(handles.lineHandles, 'Visible', 'on');
    alpha(handles.bloodHandle, single(~handles.bloodMask));
end

% Close GUI and save variables (cell types, used thresholds)
% --- Executes on button press in buttonDone.
function buttonDone_Callback(hObject, eventdata, handles)
% hObject    handle to buttonDone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bTh = handles.ops.bloodThreshold;
cTh = handles.ops.classThresholds;
rTh = handles.ops.refineThreshold;
bs = handles.ops.bloodSize;
cClasses = handles.cellClasses;

save('cellTypes.mat', "bTh", "cTh", "rTh", "bs", "cClasses");

close(handles.figure1);

% Change threshold for positively labelled ROIs
% --- Executes on slider movement.
function sliderPosThresh_Callback(hObject, eventdata, handles)
% hObject    handle to sliderPosThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = max(1, round(hObject.Value));
negThresh = handles.sliderNegThresh.Value;
% positive threshold has to be >= negative threshold
if val < negThresh
    val = negThresh;
end
hObject.Value = val;
cellClasses = updateClasses(handles.cellValues, handles.surrPrctiles, ...
    [negThresh val]);
classes = [1 -1 0];
for c = 1:3
    set(handles.lineHandles(cellClasses == classes(c)), 'Color', ...
        handles.ops.colors(c,:))
end
handles.cellClasses = cellClasses;
handles.ops.classThresholds(2) = val;
delete(handles.threshHandles(2));
hold(handles.axesHistogram, 'on')
maxi = handles.axesHistogram.YLim(2); 
handles.threshHandles(2) = plot(handles.axesHistogram, [1 1]*val, [0 maxi], ...
    'Color', handles.ops.colors(1,:), 'LineWidth', 2);
guidata(hObject, handles);

% Change threshold for negatively labelled ROIs
% --- Executes on slider movement.
function sliderNegThresh_Callback(hObject, eventdata, handles)
% hObject    handle to sliderNegThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = max(1, round(hObject.Value));
posThresh = handles.sliderPosThresh.Value;
% negative threshold has to be <= positive threshold
if val > posThresh
    val = posThresh;
end
hObject.Value = val;
cellClasses = updateClasses(handles.cellValues, handles.surrPrctiles, ...
    [val posThresh]);
classes = [1 -1 0];
for c = 1:3
    set(handles.lineHandles(cellClasses == classes(c)), 'Color', ...
        handles.ops.colors(c,:))
end
handles.cellClasses = cellClasses;
handles.ops.classThresholds(1) = val;
delete(handles.threshHandles(1));
hold(handles.axesHistogram, 'on')
maxi = handles.axesHistogram.YLim(2); 
handles.threshHandles(1) = plot(handles.axesHistogram, [1 1]*val, [0 maxi], ...
    'Color', handles.ops.colors(2,:), 'LineWidth', 2);
guidata(hObject, handles);

% Change threshold for background
% --- Executes on slider movement.
function sliderBloodThresh_Callback(hObject, eventdata, handles)
% hObject    handle to sliderBloodThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = hObject.Value;
handles.ops.bloodThreshold = val;
ci = handles.classImage;
% update cell classes and blood/background mask
[cellClasses, cellValues, surrPrctiles] = preproc.getCellClasses(ci, ...
    handles.ROIs, handles.neuropils, handles.ops);
handles.cellClasses = cellClasses;
handles.surrPrctiles = surrPrctiles;
% plot updated results
[~,bloodMask,bloodHandle,lineHandles] = preproc.plotCellClasses( ...
    ci, handles.ROIs, cellClasses, handles.ops, handles.axesImage);
threshHandles = plotClassHistogram(cellValues, surrPrctiles, ...
    handles.ops.classThresholds, handles.ops.colors, handles.axesHistogram);
handles.bloodMask = bloodMask;
handles.bloodHandle = bloodHandle;
handles.lineHandles = lineHandles;
handles.threshHandles = threshHandles;
guidata(hObject, handles);

% Change minimum size of each blood/background area
% --- Executes on slider movement.
function sliderBloodSize_Callback(hObject, eventdata, handles)
% hObject    handle to sliderBloodSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = hObject.Value;
handles.ops.bloodSize = val;
ci = handles.classImage;
% update cell classes and blood/background mask
[cellClasses, cellValues, surrPrctiles] = preproc.getCellClasses(ci, ...
    handles.ROIs, handles.neuropils, handles.ops);
handles.cellClasses = cellClasses;
handles.surrPrctiles = surrPrctiles;
% plot updated results
[~,bloodMask,bloodHandle,lineHandles] = preproc.plotCellClasses( ...
    ci, handles.ROIs, cellClasses, handles.ops, handles.axesImage);
threshHandles = plotClassHistogram(cellValues, surrPrctiles, ...
    handles.ops.classThresholds, handles.ops.colors, handles.axesHistogram);
handles.bloodMask = bloodMask;
handles.bloodHandle = bloodHandle;
handles.lineHandles = lineHandles;
handles.threshHandles = threshHandles;
guidata(hObject, handles);

% Change spatial parameter for local Laplacian filtering (local contrast)
% --- Executes on slider movement.
function refineSlider_Callback(hObject, eventdata, handles)
% hObject    handle to refineSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
val = hObject.Value;
handles.ops.refineThreshold = val;
ci = handles.classImage;
% update cell classes and blood/background mask
[cellClasses, cellValues, surrPrctiles] = preproc.getCellClasses(ci, ...
    handles.ROIs, handles.neuropils, handles.ops);
handles.cellClasses = cellClasses;
handles.surrPrctiles = surrPrctiles;
% plot updated results
[~,bloodMask,bloodHandle,lineHandles] = preproc.plotCellClasses( ...
    ci, handles.ROIs, cellClasses, handles.ops, handles.axesImage);
threshHandles = plotClassHistogram(cellValues, surrPrctiles, ...
    handles.ops.classThresholds, handles.ops.colors, handles.axesHistogram);
handles.bloodMask = bloodMask;
handles.bloodHandle = bloodHandle;
handles.lineHandles = lineHandles;
handles.threshHandles = threshHandles;
guidata(hObject, handles);

%% Local functions (important)
% Update cell classification after changing thresholds for labelling
function cellClasses = updateClasses(cellValues, surrPrctiles, thresholds)
negThreshs = surrPrctiles(:,round(thresholds(1)));
posThreshs = surrPrctiles(:,round(thresholds(2)));
cellClasses = NaN(length(cellValues),1);
cellClasses(cellValues <= negThreshs) = -1;
cellClasses(cellValues >= posThreshs) = 1;
cellClasses(cellValues > negThreshs & cellValues < posThreshs) = 0;

% Plot histogram of ROI values and current labelling thresholds
function threshHandles = plotClassHistogram(cellValues, surrPrctiles, ...
    classThresholds, colors, ax)
[r,cellPrctiles] = find(cumsum(bsxfun(@le, cellValues, ...
    [surrPrctiles, ones(size(surrPrctiles,1),1)*max(cellValues)+1]), 2) == 1);
[~,ind] = sort(r);
cellPrctiles = cellPrctiles(ind);
x = 0:2.5:100;
n = histcounts(cellPrctiles, x);
hold(ax, 'off')
bar(ax, x(1:end-1)+1.25, n, 'k')
hold(ax, 'on')
maxi = 1.05 * max(n);
threshHandles = [0 0];
threshHandles(1) = plot(ax, [1 1]*classThresholds(1), [0 maxi], ...
    'Color', colors(2,:), 'LineWidth', 2);
threshHandles(2) = plot(ax, [1 1]*classThresholds(2), [0 maxi], ...
    'Color', colors(1,:), 'LineWidth', 2);
ylim(ax, [0 maxi])
xlabel(ax, 'Percentile of ROI')
ylabel(ax, '# ROIs')

%% GUI functions irrelevant for what it does
% --- Outputs from this function are returned to the command line.
function varargout = classifyCells_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

varargout{1} = handles.cellClasses;
varargout{2} = handles.ops;
delete(hObject);

% --- Executes during object creation, after setting all properties.
function sliderPosThresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderPosThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function sliderNegThresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderNegThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function editSurround_CreateFcn(hObject, eventdata, handles)
% hObject    handle to editSurround (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function sliderBloodThresh_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderBloodThresh (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function sliderBloodSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sliderBloodSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

uiresume(hObject);

% --- Executes during object creation, after setting all properties.
function refineSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to refineSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end