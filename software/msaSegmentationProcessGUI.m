function varargout = msaSegmentationProcessGUI(varargin)
% MSASEGMENTATIONPROCESSGUI M-file for msaSegmentationProcessGUI.fig
%      MSASEGMENTATIONPROCESSGUI, by itself, creates a new MSASEGMENTATIONPROCESSGUI or raises the existing
%      singleton*.
%
%      H = MSASEGMENTATIONPROCESSGUI returns the handle to a new MSASEGMENTATIONPROCESSGUI or the handle to
%      the existing singleton*.
%
%      MSASEGMENTATIONPROCESSGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MSASEGMENTATIONPROCESSGUI.M with the given input arguments.
%
%      MSASEGMENTATIONPROCESSGUI('Property','Value',...) creates a new MSASEGMENTATIONPROCESSGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before msaSegmentationProcessGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to msaSegmentationProcessGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES
%
% Copyright (C) 2021, Danuser Lab - UTSouthwestern 
%
% This file is part of BiosensorsPackage.
% 
% BiosensorsPackage is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% BiosensorsPackage is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with BiosensorsPackage.  If not, see <http://www.gnu.org/licenses/>.
% 
% 

% Edit the above text to modify the response to help msaSegmentationProcessGUI

% Last Modified by GUIDE v2.5 22-Sep-2017 15:39:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @msaSegmentationProcessGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @msaSegmentationProcessGUI_OutputFcn, ...
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


% --- Executes just before msaSegmentationProcessGUI is made visible.
function msaSegmentationProcessGUI_OpeningFcn(hObject, eventdata, handles, varargin)


processGUI_OpeningFcn(hObject, eventdata, handles, varargin{:},'initChannel',1);

% Parameter setup
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
funParams = userData.crtProc.funParams_;


% set GUI with Parameters
% MSA type
handles.type_menu.String = {'middle','tight','minmax'};
handles.type_menu.Value = find(ismember(funParams.type, handles.type_menu.String));

if funParams.tightness == -1
    handles.tightness_checkbox.Value = 0;
    handles.tightness_panel.Visible = 'off';
    handles.tightness_slider.Value = .5;
elseif funParams.tightness <=1 && funParams.tightness >= 0
    handles.tightness_checkbox.Value = 1;
    handles.tightness_panel.Visible = 'on';
    handles.tightness_slider.Value = funParams.tightness;
end
handles.tightness_display.String = num2str(handles.tightness_slider.Value);
handles.stat_diagnostics_checkbox.Value = funParams.diagnostics;

% Update user data and GUI data
handles.output = hObject;
set(handles.figure1, 'UserData', userData);
guidata(hObject, handles);


% --- Outputs from this function are returned to the command line.
function varargout = msaSegmentationProcessGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in pushbutton_cancel.
function pushbutton_cancel_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton_cancel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
delete(handles.figure1);


% --- Executes on button press in pushbutton_done.
function pushbutton_done_Callback(hObject, eventdata, handles)


%  Check user input --------
if isempty(get(handles.listbox_selectedChannels, 'String'))
    errordlg('Please select at least one input channel from ''Available Channels''.','Setting Error','modal')
    return;
end

%  Process Sanity check ( only check underlying data )
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end
try
    userData.crtProc.sanityCheck;
catch ME
    errordlg([ME.message 'Please double check your data.'],...
                'Setting Error','modal');
    return;
end

% Retrieve GUI-defined parameters
channelIndex = get(handles.listbox_selectedChannels, 'Userdata');
funParams.ChannelIndex = channelIndex;
funParams.type = handles.type_menu.String(handles.type_menu.Value);
if handles.tightness_checkbox.Value == 1
    funParams.tightness = handles.tightness_slider.Value;
else
    funParams.tightness = -1;
end
funParams.diagnostics = logical(handles.stat_diagnostics_checkbox.Value);


% Set parameters and update main window
processGUI_ApplyFcn(hObject, eventdata, handles,funParams);

% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
userData = get(handles.figure1, 'UserData');
if isempty(userData), userData = struct(); end

if isfield(userData, 'helpFig') && ishandle(userData.helpFig)
   delete(userData.helpFig) 
end

set(handles.figure1, 'UserData', userData);
guidata(hObject,handles);


% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end


% --- Executes on key press with focus on pushbutton_done and none of its controls.
function pushbutton_done_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to pushbutton_done (see GCBO)
% eventdata  structure with the following fields (see UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
if strcmp(eventdata.Key, 'return')
    pushbutton_done_Callback(handles.pushbutton_done, [], handles);
end


% --- Executes on button press in stat_diagnostics_checkbox.
function stat_diagnostics_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to stat_diagnostics_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of stat_diagnostics_checkbox


% --- Executes on selection change in type_menu.
function type_menu_Callback(hObject, eventdata, handles)
% hObject    handle to type_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns type_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from type_menu


% --- Executes during object creation, after setting all properties.
function type_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to type_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function tightness_slider_Callback(hObject, eventdata, handles)
% hObject    handle to tightness_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
handles.tightness_display.String = num2str(handles.tightness_slider.Value);


% --- Executes during object creation, after setting all properties.
function tightness_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tightness_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
handles.tightness_slider.Value = .5;

% --- Executes on button press in tightness_checkbox.
function tightness_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to tightness_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of tightness_checkbox
if handles.tightness_checkbox.Value == 0
    handles.tightness_panel.Visible = 'off';
    handles.tightness_display.String = num2str(-1);
else
    handles.tightness_panel.Visible = 'on';
    handles.tightness_display.String = num2str(handles.tightness_slider.Value);
end

    
