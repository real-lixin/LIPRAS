% Initialize GUI controls
function handles = initGUI(handles)    
    addToExecPath();
    
    initAxes1();
    
    createJavaStatusBar();
    
    createUserData();
    
    handles = resetGuiData(handles);
    
    addControlListeners();

    reparentTabPanels();
    
    addLastCallbacks();

% ==============================================================================
    
    
    %% helper functions
    function addToExecPath()
        addpath(genpath('callbacks'));
        addpath(genpath('dialog'));
        addpath(genpath('listener'));
        % addpath(genpath('Resources'));
        % addpath('test-path/');
    end
    % ==========================================================================
    
    function initAxes1()
        hold(handles.axes1, 'on');
        
        % Default color order for plotting data series
        set(get(handles.axes1, 'Parent'), 'DefaultAxesColorOrder', ...
            [0 0 0; % black
            1 0 0; % red
            1 0.4 0; % orange
            0.2 0.2 0; % olive green
            0 0 0.502; % navy blue
            0.502 0 0.502; % violet
            0 0 1; % royal blue
            0.502 0.502 0]); % dark yellow
        
    end
    % ==========================================================================
    
    function createUserData()
        handles.profiles(7) = handles.uipanel3;
        handles.profiles(7).UserData = 0; % delete
        handles.xrd = PackageFitDiffractionData;
        handles.xrdContainer(7) = handles.xrd;
        
    end
    % ==========================================================================
    
    function addControlListeners()
        addlistener(handles.xrdContainer(7), 'Status', ...
            'PostSet', @(o,e)statusChange(o,e,handles,7));
    end
    % ==========================================================================
    
    % Creates the Java status bar, used for updating the user on GUI actions. Throws
    % an exception if the Java object could not be created.
    function createJavaStatusBar()
        import javax.swing.*
        import java.awt.*
        
        try
            % Turn off JavaFrame obsolete warning
            warning off MATLAB:HandleGraphics:ObsoletedProperty:JavaFrame;
            jFrame=get(handles.figure1,'JavaFrame');
            try
                jRootPane = jFrame.fFigureClient.getWindow;  % This works up to R2011a
            catch
                try
                    jRootPane = jFrame.fHG1Client.getWindow;  % This works from R2008b-R2014a
                catch
                    jRootPane = jFrame.fHG2Client.getWindow;  % This works from R2014b and up
                end
            end
            
            
            % left status bar
            handles.statusbarObj = javaObjectEDT('com.mathworks.mwswing.MJStatusBar');
            jRootPane.setStatusBar(handles.statusbarObj);
            handles.statusbarObj.setText('<html>Please import file(s) containing data to fit.</html>');
            
            % right status bar
            handles.statusbarRight = javaObjectEDT('com.mathworks.mwswing.MJStatusBar');
            handles.statusbarObj.add(handles.statusbarRight, 'East');
            handles.statusbarRight.setText('');
            jRootPane.setStatusBarVisible(1);
            
        catch
            msgId = 'initGUI:JavaObjectCreation';
            msg = 'Could not create the Java status bar';
            MException(msgId, msg);
        end
    end
    % ==========================================================================
    
    % Set the parents of the 3 major panels for tab switching functionality.
    function reparentTabPanels()
        set(handles.panel_setup, 'parent', handles.profiles(7));
        set(handles.panel_parameters,'parent', handles.profiles(7));
        set(handles.panel_results, 'parent', handles.profiles(7)); 
    end
    % ==========================================================================
    
    % Adds callback functions to all other uicomponents. 
    % 
    % Assumes this is the last function called in the GUI initialization.
    % 
    % Throws an exception if the status bar is invalid.
    function addLastCallbacks()
        
        % Requires a Java status bar to exist
        if ~isa(handles.statusbarObj, 'com.mathworks.mwswing.MJStatusBar')
            msgId = 'initGUI:InvalidJavaStatusBar';
            msg = 'Could not add a callback function for updating the status bar.';
            MException(msgId, msg);
        end
        handles.figure1.WindowButtonMotionFcn = @(o, e)WindowButtonMotionFcn(o, e,guidata(o));
    end
    % ==========================================================================
end