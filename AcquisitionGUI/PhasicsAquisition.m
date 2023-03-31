% Acquisition software for 2D and 3D acquisition with Phasics SID4Bio camera
% and an inverted microscope stand Zeiss Axio Observer 7

% The wavefront estimation uses the retrieval tools associated with this
% package

function varargout = PhasicsAquisition(varargin)
% PHASICSAQUISITION MATLAB code for PhasicsAquisition.fig

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PhasicsAquisition_OpeningFcn, ...
                   'gui_OutputFcn',  @PhasicsAquisition_OutputFcn, ...
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


% --- Executes just before PhasicsAquisition is made visible.
function PhasicsAquisition_OpeningFcn(hObject, eventdata, handles, varargin)
% Set global Init Variables
clear global
global vid, global src, global Ref0, global FLAG_Itf, global FLAG_WF
global savenameRef, global savenameItf, global savedirRef, global savedirItf
global filenameRef, global filenameItf
global rootZeiss, global StageAxis, global FocusAxis, global defaultPosition
global FLAG_ZStack
global StepSize, global deltaZmax, global deltaZmin
global xStageAxis, global yStageAxis

% This function has no output args, see OutputFcn.

handles.output = hObject;

% Add path with all required functions
addpath(genpath('../'))
imaqreset

% Initialize Phasics camera

vid = videoinput('qimaging', 1, 'MONO8_1600x1200');
src = getselectedsource(vid);

vid.FramesPerTrigger = 1;

vid.ReturnedColorSpace = 'grayscale';

triggerconfig(vid, 'manual');

% Initialize Microscope

cl = NET.addAssembly('MTBApi');
import ZEISS.MTB.Api.*
connection = ZEISS.MTB.Api.MTBConnection();
mtbid = connection.Login('en');
rootZeiss = connection.GetRoot(mtbid);
deviceCount = rootZeiss.GetDeviceCount();
device=rootZeiss.GetDevice(0);

reflectorChanger = rootZeiss.GetComponent(char("MTBReflectorChanger"));
reflectorChanger.SetPosition(mtbid,1,ZEISS.MTB.Api.MTBCmdSetModes.Default);

StageAxis=rootZeiss.GetComponent(char("MTBStage"));
FocusAxis=rootZeiss.GetComponent(char("MTBFocus"));
xStageAxis = rootZeiss.GetComponent(char("MTBStageAxisX"));
yStageAxis = rootZeiss.GetComponent(char("MTBStageAxisY"));
defaultPosition=zeros(1,3);
[defaultX,defaultY]=StageAxis.GetPosition("µm");
defaultPosition(1:2)=[defaultX,defaultY];
defaultPosition(3)=FocusAxis.GetPosition("µm");
yStageAxis.SetContinualAcceleration(100, "µm/s2");
xStageAxis.SetContinualAcceleration(100, "µm/s2");
FocusAxis.SetContinualAcceleration(100, "µm/s²")


% Initialize User Interface

set(handles.edit_Exposure,'userdata', src.Exposure*1000)
set(handles.edit_Exposure,'string',get(handles.edit_Exposure,'userdata'))
set(handles.radiobutton_Itf, 'value', 1)
set(handles.radiobutton_wavefront, 'value', 0)
FLAG_Itf = 1;
FLAG_WF = 0;
set(handles.text_RefAcquired, 'string', 'No Reference', 'ForegroundColor', 'red')
set(handles.edit_FramesPerTrigger, 'userdata', vid.FramesPerTrigger)
set(handles.edit_FramesPerTrigger, 'string', vid.FramesPerTrigger)
set(handles.edit_Filename, 'string', 'Choose file name')
set(handles.text_status,'string','')
FLAG_ZStack = 0;
StepSize = 0;
deltaZmax = 0;
deltaZmin = 0;

% Initialize stage control GUI
set(handles.edit_xpos,'userdata',0)
set(handles.edit_xpos,'string','0')
set(handles.edit_ypos,'userdata',0)
set(handles.edit_ypos,'string','0')
set(handles.edit_zpos,'userdata',0)
set(handles.edit_zpos,'string','0')
set(handles.edit_deltaZmin,'String','0')
set(handles.edit_deltaZmin,'userdata',0)
set(handles.edit_deltaZmax,'String','0')
set(handles.edit_deltaZmax,'userdata',0)    
set(handles.edit_StepSize,'String','0')
set(handles.edit_StepSize,'userdata',0) 

% Maximize GUI to full window size
set(gcf, 'WindowState', 'maximized')

guidata(hObject, handles);

% UIWAIT makes PhasicsAquisition wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = PhasicsAquisition_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% Acquisition of initial reference interferogram for direct wavefront
% estimation
function pushbutton_InitRef_Callback(hObject, eventdata, handles)
    global Ref0, global vid, global src
    set(handles.pushbutton_StopPreview, 'userdata',1)
    stop(vid)
    triggerconfig(vid, 'manual');
    start(vid)
    Ref0 = getsnapshot(vid);
    pause(src.Exposure)
    stop(vid)
    set(handles.text_RefAcquired, 'string', 'Reference acquired', 'ForegroundColor', 'green')
pushbutton_startPrev_Callback(hObject, eventdata, handles)

% Adjust exposure time of camera in ms
function edit_Exposure_Callback(hObject, eventdata, handles)
    global src, global vid
    stop(vid)
    set(handles.pushbutton_StopPreview,'userdata',1)
    src.Exposure = str2double(get(handles.edit_Exposure,'string'))/1000;
    set(handles.edit_Exposure,'userdata',str2double(get(handles.edit_Exposure,'string')));
pushbutton_startPrev_Callback(hObject, eventdata, handles)
    

% --- Executes during object creation, after setting all properties.
function edit_Exposure_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Exposure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Start preview of either camera signal or wavefront estimation for higher
% speed only one of both is updated and previewed
function pushbutton_startPrev_Callback(hObject, eventdata, handles)
    global vid, global src, global FLAG_Itf, global FLAG_WF, global Ref, global Itf, global Ref0
    set(handles.pushbutton_StopPreview,'userdata',0)
    stop(vid)
%     vid = get(handles.pushbutton_startPrev,'userdata');
%     src = getselectedsource(vid);
    triggerconfig(vid, 'manual');
    src.Exposure = get(handles.edit_Exposure,'userdata')/1000;   
    
    if ~isempty(Ref0)
        gpuRef0 = gpuArray(Ref0);
    end
    start(vid)
    while 1
        snap = getsnapshot(vid);
        pause(src.Exposure)
        if FLAG_Itf == 1 && FLAG_WF == 0 % Camera image
            axes(handles.fig_Camera);
            imagesc(snap),axis image,colormap('gray');
            axis off
            title('Camera Preview', 'FontSize', 16)
            
            % Calculate histogram to see camera saturation
            axes(handles.fig_Sat);
            [counts, binLocations] = imhist(snap);
            bar(binLocations, counts, 'black')
            xlabel('Counts','FontSize', 14)
            ylabel('Saturation','FontSize', 14)
            drawnow
            
            % Update of either wavefront or camera preview
        elseif FLAG_WF == 1 && FLAG_Itf == 0 % Wavefront estimation
            if isempty(Ref0)
                msgbox('Initial Reference Image is required')
                stop(vid)
                break
            else
                gpuSnap = gpuArray(snap);
                [DWx, DWy] = GetGradients(gpuSnap, gpuRef0);
                W = IntegrateGradients(DWx, DWy);
                axes(handles.fig_Camera);
                imagesc(W),axis image,colormap(viridis());
                axis off
                title('OPD Preview', 'FontSize', 16)
                cb = colorbar;
                ylabel(cb,'OPD [a.u.]','FontSize',14)
                drawnow
            end
        end
        
        if get(handles.pushbutton_StopPreview,'userdata') == 1
            stop(vid)
            break
        end
    end
  
% Allows to adjust frames per single acquisition    
function edit_FramesPerTrigger_Callback(hObject, eventdata, handles)
    global vid
    stop(vid)
    set(handles.pushbutton_StopPreview,'userdata',1)
    set(handles.edit_FramesPerTrigger, 'userdata', str2double(get(handles.edit_FramesPerTrigger, 'String')))
    vid.FramesPerTrigger = get(handles.edit_FramesPerTrigger, 'userdata');
    disp(vid.FramesPerTrigger)


% --- Executes during object creation, after setting all properties.
function edit_FramesPerTrigger_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_FramesPerTrigger (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Button to select save folder for both object and reference interferograms
function pushbutton_SelectFolder_Callback(hObject, eventdata, handles)
    global filenameRef, global filenameItf, global savenameRef, global savenameItf
    global savedirRef, global savedirItf
    dir = uigetdir('D:\Florian\Data\');
    set(handles.text_SaveFolder, 'string', dir)
    savedirRef = fullfile(dir, 'Ref');
    savedirItf = fullfile(dir, 'Itf');
    
    if ~isempty(filenameRef) && ~isempty(filenameItf)
        savenameRef = fullfile(savedirRef,filenameRef);
        savenameItf = fullfile(savedirItf,filenameItf);
    end

% Acquire and save reference interferogram of current FOV
function pushbutton_AquireRef_Callback(hObject, eventdata, handles)
    global vid, global src, global Ref0, global FLAG_Itf, global FLAG_WF
    global savenameRef, global savedirRef, global zCount, global FLAG_ZStack
    stop(vid)
    set(handles.pushbutton_StopPreview,'userdata',1)
    
    set(handles.text_status,'string','Acquisition in progress','ForegroundColor', 'red')
    set(handles.radiobutton_Itf, 'value', 1)
    set(handles.radiobutton_wavefront, 'value', 0)
    FLAG_Itf = 1;
    FLAG_WF = 0;
    
    if isempty(savenameRef)
        set(handles.text_status,'string','Acquisition error','ForegroundColor', 'red')
        msgbox('File name and save directory required!')
    else    
        if ~exist(savedirRef, 'dir')
            mkdir(savedirRef)
        end

        triggerconfig(vid, 'immediate');
        start(vid);

        while vid.FramesAvailable < vid.FramesPerTrigger
            pause(src.Exposure)
        end

        Ref = getdata(vid, vid.FramesPerTrigger);
        Ref=squeeze(Ref(:,:,1,:));

        flushdata(vid)
        
        if FLAG_ZStack == 1
            save(append(savenameRef,num2str((zCount).', '%04d')),'Ref')
        else
            save(savenameRef,'Ref')
        end
        
        set(handles.text_status,'string','Acquisition finished','ForegroundColor', 'green')
        
        % Update preview with acquired reference image
        axes(handles.fig_Camera);
        imagesc(Ref(:,:,vid.FramesPerTrigger)),axis image,colormap('gray');
        axis off
        title('Camera Preview', 'FontSize', 16)
        
        % Update histogram with data from acquired reference image
        axes(handles.fig_Sat);
        [counts, binLocations] = imhist(Ref(:,:,vid.FramesPerTrigger));
        bar(binLocations, counts, 'black')
        xlabel('Counts','FontSize', 14)
        ylabel('Saturation','FontSize', 14)
    end

% Adjust saving filename of the acquisition data. Same for both Itf and Ref
% with corresonding prefix
function edit_Filename_Callback(hObject, eventdata, handles)
    global savenameRef, global savenameItf, global filenameRef, global filenameItf
    global savedirRef, global savedirItf
    filename = get(hObject, 'String');
    set(hObject, 'userdata', filename)
    filenameRef = append('Ref_',filename);
    filenameItf = append('Itf_',filename);
    if ~isempty(savedirItf) && ~isempty(savedirRef)
        savenameRef = fullfile(savedirRef,filenameRef);
        savenameItf = fullfile(savedirItf,filenameItf);
    end

% --- Executes during object creation, after setting all properties.
function edit_Filename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_Filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Acquisition and saving of sample interferogram
function pushbutton_AquireItf_Callback(hObject, eventdata, handles)
    global vid, global src, global FLAG_Itf, global FLAG_WF
    global savenameItf, global savedirItf, global FLAG_ZStack, global zCount
    
    stop(vid)
    set(handles.pushbutton_StopPreview,'userdata',1)
    
    set(handles.text_status,'string','Acquisition in progress','ForegroundColor', 'red')
    set(handles.radiobutton_Itf, 'value', 1)
    set(handles.radiobutton_wavefront, 'value', 0)
    FLAG_Itf = 1;
    FLAG_WF = 0;
    
    if isempty(savenameItf)
        set(handles.text_status,'string','Acquisition error','ForegroundColor', 'red')
        msgbox('File name and save directory required!')
    else
        if ~exist(savedirItf, 'dir')
            mkdir(savedirItf)
        end

        triggerconfig(vid, 'immediate');
        start(vid);

        while vid.FramesAvailable < vid.FramesPerTrigger
            pause(src.Exposure)
        end

        Itf = getdata(vid, vid.FramesPerTrigger);
        Itf=squeeze(Itf(:,:,1,:));

        flushdata(vid)
        
        if FLAG_ZStack == 1
            save(append(savenameItf,num2str((zCount).', '%04d')),'Itf')
        else
            save(savenameItf,'Itf')
        end

        set(handles.text_status,'string','Acquisition finished','ForegroundColor', 'green')
        
        % Update preview with acquired interferogram
        axes(handles.fig_Camera);
        imagesc(Itf(:,:,vid.FramesPerTrigger)),axis image,colormap('gray');
        axis off
        title('Camera Preview', 'FontSize', 16)
        
        % Update histogram with acquired data
        axes(handles.fig_Sat);
        [counts, binLocations] = imhist(Itf(:,:,vid.FramesPerTrigger));
        bar(binLocations, counts, 'black')
        xlabel('Counts','FontSize', 14)
        ylabel('Saturation','FontSize', 14)
    end


% Select Itf for camera interferogram in preview
function radiobutton_Itf_Callback(hObject, eventdata, handles)
    global FLAG_Itf, global FLAG_WF
    FLAG_Itf = get(hObject,'Value');
    if FLAG_Itf == 1
        FLAG_WF = 0;
        set(handles.radiobutton_wavefront,'value',0)
    elseif FLAG_Itf == 0
        FLAG_WF = 1;
        set(handles.radiobutton_wavefront,'value',1)
    end


% --- Executes on button press in radiobutton_wavefront.
function radiobutton_wavefront_Callback(hObject, eventdata, handles)
    global FLAG_Itf, global FLAG_WF
    FLAG_WF = get(hObject,'Value');
    if FLAG_WF == 1
        FLAG_Itf = 0;
        set(handles.radiobutton_Itf,'value',0)
    elseif FLAG_WF == 0
        FLAG_Itf = 1;
        set(handles.radiobutton_Itf,'value',1)
    end


% Stop preview
function pushbutton_StopPreview_Callback(hObject, eventdata, handles)  
    set(handles.pushbutton_StopPreview,'userdata',1)

% Move stage manually to certain absolute x-value in µm     
function edit_xpos_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global CurrentPosition, global defaultPosition
    global positionVal
    
    newX = str2double(get(handles.edit_xpos,'string'));
    
    [ReadPosX,ReadPosY]=StageAxis.GetPosition("µm");
    
    oldX = ReadPosX - defaultPosition(1);
    moveX = abs(newX - oldX);
    if moveX > 1000
        msgbox('You are going to move more than 1000 µm. Please choose smaller distance!')
        set(handles.edit_xpos,'string', num2str(get(hObject,'userdata')))
    elseif isnan(newX)
        msgbox('NaN entered. Please check again!')
        set(handles.edit_xpos,'string', num2str(get(hObject,'userdata')))
    elseif isinf(newX)
        msgbox('Infinity number entered. Please check again!')
        set(handles.edit_xpos,'string', num2str(get(hObject,'userdata')))
    else
        StageAxis.SetPosition(defaultPosition(1)+newX,ReadPosY,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
        pause(0.5)
        [posX,posY]=StageAxis.GetPosition("µm");
        posZ=FocusAxis.GetPosition("µm");
        posX=posX-defaultPosition(1);
        posY=posY-defaultPosition(2);
        posZ=posZ-defaultPosition(3);
        positionVal=[posX posY posZ];
        set(handles.edit_ypos,'string', posY)
        set(handles.edit_ypos,'userdata', posY)
        set(handles.edit_xpos,'string', posX)
        set(handles.edit_xpos,'userdata', posX)
        set(handles.edit_zpos,'string', posZ)
        set(handles.edit_zpos,'userdata', posZ)
    end
 

% --- Executes during object creation, after setting all properties.
function edit_xpos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_xpos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Move stage manually to certain absolute y-value in µm   
function edit_ypos_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global CurrentPosition, global defaultPosition
    global positionVal
    
    newY = str2double(get(handles.edit_ypos,'string'));
    
    [ReadPosX,ReadPosY]=StageAxis.GetPosition("µm");
    
    oldY = ReadPosY - defaultPosition(2);
    moveY = abs(newY - oldY);
    if moveY > 1000
        msgbox('You are going to move more than 1000 µm. Please choose smaller distance!')
        set(handles.edit_ypos,'string', num2str(get(hObject,'userdata')))
    elseif isnan(newY)
        msgbox('NaN entered. Please check again!')
        set(handles.edit_ypos,'string', num2str(get(hObject,'userdata')))
    elseif isinf(newY)
        msgbox('Infinity number entered. Please check again!')
        set(handles.edit_ypos,'string', num2str(get(hObject,'userdata')))
    else
        StageAxis.SetPosition(ReadPosX,defaultPosition(2)+newY,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
        pause(0.5)
        [posX,posY]=StageAxis.GetPosition("µm");
        posZ=FocusAxis.GetPosition("µm");
        posX=posX-defaultPosition(1);
        posY=posY-defaultPosition(2);
        posZ=posZ-defaultPosition(3);
        positionVal=[posX posY posZ];
        set(handles.edit_ypos,'string', posY)
        set(handles.edit_ypos,'userdata', posY)
        set(handles.edit_xpos,'string', posX)
        set(handles.edit_xpos,'userdata', posX)
        set(handles.edit_zpos,'string', posZ)
        set(handles.edit_zpos,'userdata', posZ)
    end


% --- Executes during object creation, after setting all properties.
function edit_ypos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_ypos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Move focus manually to certain absolute z-value in µm   
function edit_zpos_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global CurrentPosition, global defaultPosition
    global positionVal
    
    newZ = str2double(get(handles.edit_zpos,'string'));
    
    ReadPosZ=FocusAxis.GetPosition("µm");
    
    oldZ = ReadPosZ - defaultPosition(3);
    moveZ = abs(newZ - oldZ);
    if moveZ > 100
        msgbox('You are going to move more than 100 µm. Please choose smaller distance!')
        set(handles.edit_zpos,'string', num2str(get(hObject,'userdata')))
    elseif isnan(newZ)
        msgbox('NaN entered. Please check again!')
        set(handles.edit_zpos,'string', num2str(get(hObject,'userdata')))
    elseif isinf(newZ)
        msgbox('Infinity number entered. Please check again!')
        set(handles.edit_zpos,'string', num2str(get(hObject,'userdata')))
    else
        FocusAxis.SetPosition(defaultPosition(3)+newZ,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
        pause(0.5)
        [posX,posY]=StageAxis.GetPosition("µm");
        posZ=FocusAxis.GetPosition("µm");
        posX=posX-defaultPosition(1);
        posY=posY-defaultPosition(2);
        posZ=posZ-defaultPosition(3);
        positionVal=[posX posY posZ];
        set(handles.edit_ypos,'string', posY)
        set(handles.edit_ypos,'userdata', posY)
        set(handles.edit_xpos,'string', posX)
        set(handles.edit_xpos,'userdata', posX)
        set(handles.edit_zpos,'string', posZ)
        set(handles.edit_zpos,'userdata', posZ)
    end


% --- Executes during object creation, after setting all properties.
function edit_zpos_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_zpos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Move stage with an incremental +1 µm step in y direction
function pushbutton_yUp_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global CurrentPosition, global defaultPosition
    global positionVal
    yUpIncrement = 1;
    [ReadPosX,ReadPosY]=StageAxis.GetPosition("µm");
    ReadPosZ=FocusAxis.GetPosition("µm");
    StageAxis.SetPosition(ReadPosX,ReadPosY+yUpIncrement,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
    [posX,posY]=StageAxis.GetPosition("µm");
    posZ=FocusAxis.GetPosition("µm");
    posX=posX-defaultPosition(1);
    posY=posY-defaultPosition(2);
    posZ=posZ-defaultPosition(3);
    positionVal=[posX posY posZ];
    yposUserData = str2double(get(handles.edit_ypos, 'string'));
    set(handles.edit_ypos,'string', num2str(yposUserData + yUpIncrement))
    set(handles.edit_ypos,'userdata', posY)
    set(handles.edit_xpos,'userdata', posX)
    set(handles.edit_zpos,'userdata', posZ)


% Move stage with an incremental -1 µm step in y direction
function pushbutton_yDown_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global CurrentPosition, global defaultPosition
    global positionVal
    yDownIncrement = -1;
    [ReadPosX,ReadPosY]=StageAxis.GetPosition("µm");
    ReadPosZ=FocusAxis.GetPosition("µm");
    StageAxis.SetPosition(ReadPosX,ReadPosY+yDownIncrement,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
    [posX,posY]=StageAxis.GetPosition("µm");
    posZ=FocusAxis.GetPosition("µm");
    posX=posX-defaultPosition(1);
    posY=posY-defaultPosition(2);
    posZ=posZ-defaultPosition(3);
    positionVal=[posX posY posZ];
    yposUserData = str2double(get(handles.edit_ypos, 'string'));
    set(handles.edit_ypos,'string', num2str(yposUserData + yDownIncrement))
    set(handles.edit_ypos,'userdata', posY)
    set(handles.edit_xpos,'userdata', posX)
    set(handles.edit_zpos,'userdata', posZ)


% Move stage with an incremental +1 µm step in x direction
function pushbutton_xLeft_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global CurrentPosition, global defaultPosition
    global positionVal
    xLeftIncrement = 1;
    [ReadPosX,ReadPosY]=StageAxis.GetPosition("µm");
    ReadPosZ=FocusAxis.GetPosition("µm");
    StageAxis.SetPosition(ReadPosX+xLeftIncrement,ReadPosY,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
    [posX,posY]=StageAxis.GetPosition("µm");
    posZ=FocusAxis.GetPosition("µm");
    posX=posX-defaultPosition(1);
    posY=posY-defaultPosition(2);
    posZ=posZ-defaultPosition(3);
    positionVal=[posX posY posZ];
    xposUserData = str2double(get(handles.edit_xpos, 'string'));
    set(handles.edit_xpos,'string', num2str(xposUserData + xLeftIncrement))
    set(handles.edit_ypos,'userdata', posY)
    set(handles.edit_xpos,'userdata', posX)
    set(handles.edit_zpos,'userdata', posZ)


% Move stage with an incremental -1 µm step in x direction
function pushbutton_xRight_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global CurrentPosition, global defaultPosition
    global positionVal
    xRightIncrement = -1;
    [ReadPosX,ReadPosY]=StageAxis.GetPosition("µm");
    ReadPosZ=FocusAxis.GetPosition("µm");
    StageAxis.SetPosition(ReadPosX+xRightIncrement,ReadPosY,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
    [posX,posY]=StageAxis.GetPosition("µm");
    posZ=FocusAxis.GetPosition("µm");
    posX=posX-defaultPosition(1);
    posY=posY-defaultPosition(2);
    posZ=posZ-defaultPosition(3);
    positionVal=[posX posY posZ];
    xposUserData = str2double(get(handles.edit_xpos, 'string'));
    set(handles.edit_xpos,'string', num2str(xposUserData + xRightIncrement))
    set(handles.edit_ypos,'userdata', posY)
    set(handles.edit_xpos,'userdata', posX)
    set(handles.edit_zpos,'userdata', posZ)


% Move focus with an incremental +1 µm step in z direction
function pushbutton_zUp_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global CurrentPosition, global defaultPosition
    global positionVal
    zUpIncrement = 1;
    [ReadPosX,ReadPosY]=StageAxis.GetPosition("µm");
    ReadPosZ=FocusAxis.GetPosition("µm");
    FocusAxis.SetPosition(ReadPosZ+zUpIncrement,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
    [posX,posY]=StageAxis.GetPosition("µm");
    posZ=FocusAxis.GetPosition("µm");
    posX=posX-defaultPosition(1);
    posY=posY-defaultPosition(2);
    posZ=posZ-defaultPosition(3);
    positionVal=[posX posY posZ];
    zposUserData = str2double(get(handles.edit_zpos, 'string'));
    set(handles.edit_zpos,'string', num2str(zposUserData + zUpIncrement))
    set(handles.edit_ypos,'userdata', posY)
    set(handles.edit_xpos,'userdata', posX)
    set(handles.edit_zpos,'userdata', posZ)


% Move focus with an incremental -1 µm step in z direction
function pushbutton_zDown_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global CurrentPosition, global defaultPosition
    global positionVal
    zDownIncrement = -1;
    [ReadPosX,ReadPosY]=StageAxis.GetPosition("µm");
    ReadPosZ=FocusAxis.GetPosition("µm");
    FocusAxis.SetPosition(ReadPosZ+zDownIncrement,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
    [posX,posY]=StageAxis.GetPosition("µm");
    posZ=FocusAxis.GetPosition("µm");
    posX=posX-defaultPosition(1);
    posY=posY-defaultPosition(2);
    posZ=posZ-defaultPosition(3);
    positionVal=[posX posY posZ];
    zposUserData = str2double(get(handles.edit_zpos, 'string'));
    set(handles.edit_zpos,'string', num2str(zposUserData + zDownIncrement))
    set(handles.edit_ypos,'userdata', posY)
    set(handles.edit_xpos,'userdata', posX)
    set(handles.edit_zpos,'userdata', posZ)


% Update displayed positions
function pushbutton_GetPositions_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global defaultPosition, global positionVal
    [posX,posY]=StageAxis.GetPosition("µm");
    posZ=FocusAxis.GetPosition("µm");
    posX=posX-defaultPosition(1);
    posY=posY-defaultPosition(2);
    posZ=posZ-defaultPosition(3);
    positionVal=[posX posY posZ];
    set(handles.edit_xpos,'string', posX)
    set(handles.edit_xpos,'userdata', posX)
    set(handles.edit_ypos,'string', posY)
    set(handles.edit_ypos,'userdata', posY)
    set(handles.edit_zpos,'string', posZ)
    set(handles.edit_zpos,'userdata', posZ)

    
% Set current stage position to 0, corresponding to new home position
function pushbutton_SetZero_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global defaultPosition, global positionVal
    [defaultX,defaultY]=StageAxis.GetPosition("µm");
    defaultPosition(1:2)=[defaultX,defaultY];
    defaultPosition(3)=FocusAxis.GetPosition("µm");
    posX=0;
    posY=0;
    posZ=0;
    positionVal=[posX posY posZ];
    set(handles.edit_xpos,'string', posX)
    set(handles.edit_xpos,'userdata', posX)
    set(handles.edit_ypos,'string', posY)
    set(handles.edit_ypos,'userdata', posY)
    set(handles.edit_zpos,'string', posZ)
    set(handles.edit_zpos,'userdata', posZ)
    
% Move stage and focus to home position
function pushbutton_MoveHome_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global defaultPosition, global positionVal
    
    StageAxis.SetPosition(defaultPosition(1),defaultPosition(2),"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
    FocusAxis.SetPosition(defaultPosition(3),"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
    
    pause(0.5)
    
    [posX,posY]=StageAxis.GetPosition("µm");
    posZ=FocusAxis.GetPosition("µm");
    posX=posX-defaultPosition(1);
    posY=posY-defaultPosition(2);
    posZ=posZ-defaultPosition(3);
    positionVal=[posX posY posZ];
    
    set(handles.edit_xpos,'string', posX)
    set(handles.edit_xpos,'userdata', posX)
    set(handles.edit_ypos,'string', posY)
    set(handles.edit_ypos,'userdata', posY)
    set(handles.edit_zpos,'string', posZ)
    set(handles.edit_zpos,'userdata', posZ)
    
% Adjust upper delta z position in µm referred to current position for automatic focal scan
function edit_deltaZmax_Callback(hObject, eventdata, handles)
    global deltaZmax
    
    deltaZmax = str2double(get(hObject,'String'));
    set(handles.edit_deltaZmax, 'userdata', deltaZmax)



% --- Executes during object creation, after setting all properties.
function edit_deltaZmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_deltaZmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Adjust lower delta z position in µm referred to current position for automatic focal scan
function edit_deltaZmin_Callback(hObject, eventdata, handles)
    global deltaZmin
    
    deltaZmin = str2double(get(hObject,'String'));
    set(handles.edit_deltaZmin, 'userdata', deltaZmin)


% --- Executes during object creation, after setting all properties.
function edit_deltaZmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_deltaZmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Adjust step size for automatic focal scan in µm
function edit_StepSize_Callback(hObject, eventdata, handles)
    global StepSize
    
    StepSize = str2double(get(hObject,'String'));
    set(handles.edit_StepSize, 'userdata', StepSize)


% --- Executes during object creation, after setting all properties.
function edit_StepSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit_StepSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% Start automatic focal scan acquisition including reference and sample interferograms
function pushbutton_ZStack_Callback(hObject, eventdata, handles)
    global StageAxis, global FocusAxis, global defaultPosition, global positionVal
    global FLAG_ZStack, global ItfPos, global RefPos,
    global StepSize, global deltaZmax, global deltaZmin, global zCount
    
    if isnan(StepSize)
        msgbox('NaN entered for StepSize')
        
    elseif isinf(StepSize)
        msgbox('Inf entered for StepSize')
        
    elseif isnan(deltaZmax)
        msgbox('NaN entered for deltaZmax')
        
    elseif isinf(deltaZmax)
        msgbox('Inf entered for deltaZmax')
        
    elseif isnan(deltaZmin)
        msgbox('Inf entered for deltaZmin')
        
    elseif isinf(deltaZmin)
        msgbox('Inf entered for deltaZmin')
        
    elseif isempty(ItfPos)
        msgbox('Set Itf Position')
        
    elseif isempty(RefPos)
        msgbox('Set Ref Position')
    
    elseif deltaZmax < deltaZmin
        msgbox('Upper Z boundary must be greater than lower boundary')
    else
        FLAG_ZStack = 1;
        
        % Itf loop
        
        zCount = 0;

        StartVal = ItfPos(3) + deltaZmin;
        StopVal = ItfPos(3) + deltaZmax;

        FocusAxis.SetPosition(StartVal,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
        FocusState = FocusAxis.IsBusy;
        StageAxis.SetPosition(ItfPos(1),ItfPos(2),"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
        StageState = StageAxis.IsBusy;
        
        while (StageState == 1) || (FocusState == 1) % Wait until AxisFinishedJob
            StageState = StageAxis.IsBusy;
            FocusState = FocusAxis.IsBusy;
        end
        
        pushbutton_AquireItf_Callback(hObject, eventdata, handles);

        CurrentZPos = FocusAxis.GetPosition("µm");
        posZ=CurrentZPos-defaultPosition(3);
        set(handles.edit_zpos,'string', posZ)
        set(handles.edit_zpos,'userdata', posZ)

        while CurrentZPos < StopVal
            zCount = zCount + 1;
            FocusAxis.SetPosition(CurrentZPos + StepSize,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
            
            FocusState = FocusAxis.IsBusy;
            StageState = StageAxis.IsBusy;
            while (StageState == 1) || (FocusState == 1) % Wait until AxisFinishedJob
                StageState = StageAxis.IsBusy;
                FocusState = FocusAxis.IsBusy;
            end

            pushbutton_AquireItf_Callback(hObject, eventdata, handles);

            CurrentZPos = FocusAxis.GetPosition("µm");
            posZ=CurrentZPos-defaultPosition(3);
            set(handles.edit_zpos,'string', posZ)
            set(handles.edit_zpos,'userdata', posZ)
        end
        
        % Reference Loop
        zCount = 0;
        
        FocusAxis.SetPosition(StartVal,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
        FocusState = FocusAxis.IsBusy;
        StageAxis.SetPosition(RefPos(1),RefPos(2),"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
        StageState = StageAxis.IsBusy;
        
        while (StageState == 1) || (FocusState == 1) % Wait until AxisFinishedJob
            StageState = StageAxis.IsBusy;
            FocusState = FocusAxis.IsBusy;
        end

        pushbutton_AquireRef_Callback(hObject, eventdata, handles);
        
        CurrentZPos = FocusAxis.GetPosition("µm");
        posZ=CurrentZPos-defaultPosition(3);
        set(handles.edit_zpos,'string', posZ)
        set(handles.edit_zpos,'userdata', posZ)
        
        while CurrentZPos < StopVal
            zCount = zCount + 1;
            
            FocusAxis.SetPosition(CurrentZPos + StepSize,"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
            FocusState = FocusAxis.IsBusy;
            StageState = StageAxis.IsBusy;
            
            while (StageState == 1) || (FocusState == 1) % Wait until AxisFinishedJob
                StageState = StageAxis.IsBusy;
                FocusState = FocusAxis.IsBusy;
            end

            pushbutton_AquireRef_Callback(hObject, eventdata, handles);

            CurrentZPos = FocusAxis.GetPosition("µm");
            posZ=CurrentZPos-defaultPosition(3);
            set(handles.edit_zpos,'string', posZ)
            set(handles.edit_zpos,'userdata', posZ)
        end
        
        
        % Bring Stage Back to ItfFocalPosition
        
        StageAxis.SetPosition(ItfPos(1),ItfPos(2),"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
        FocusAxis.SetPosition(ItfPos(3),"µm",ZEISS.MTB.Api.MTBCmdSetModes.Default);
        
        FocusState = FocusAxis.IsBusy;
        StageState = StageAxis.IsBusy;

        while (StageState == 1) || (FocusState == 1) % Wait until AxisFinishedJob
            StageState = StageAxis.IsBusy;
            FocusState = FocusAxis.IsBusy;
        end

        [posX,posY]=StageAxis.GetPosition("µm");
        posZ=FocusAxis.GetPosition("µm");
        posX=posX-defaultPosition(1);
        posY=posY-defaultPosition(2);
        posZ=posZ-defaultPosition(3);
        positionVal=[posX posY posZ];

        set(handles.edit_xpos,'string', posX)
        set(handles.edit_xpos,'userdata', posX)
        set(handles.edit_ypos,'string', posY)
        set(handles.edit_ypos,'userdata', posY)
        set(handles.edit_zpos,'string', posZ)
        set(handles.edit_zpos,'userdata', posZ)

        FLAG_ZStack = 0;
    end
   

% --- Executes during object deletion, before destroying properties.

function text_status_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text_status (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function text_status_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to text_status (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% Set current position as reference position for automatic z scan
function pushbutton_RefPos_Callback(hObject, eventdata, handles)
    global RefPos, global StageAxis, global FocusAxis
    
    [posX,posY]=StageAxis.GetPosition("µm");
    posZ=FocusAxis.GetPosition("µm");
    RefPos = [posX posY posZ];
    
    pushbutton_GetPositions_Callback(hObject, eventdata, handles)
    
% Set current position as sample position for automatic z scan
function pushbutton_ItfPos_Callback(hObject, eventdata, handles)
    global ItfPos, global StageAxis, global FocusAxis
    
    [posX,posY]=StageAxis.GetPosition("µm");
    posZ=FocusAxis.GetPosition("µm");
    ItfPos = [posX posY posZ];
        
    pushbutton_GetPositions_Callback(hObject, eventdata, handles)
