%% GUI for FitDiffractionData

%% handles structure
% Descriptions of each variable saved in the handles structure.

%% Initialization
function varargout = FDGUI(varargin)
	% FDGUI MATLAB code for FDGUI.fig
	
	% Last Modified by GUIDE v2.5 06-Sep-2016 19:41:14
	
	% Begin initialization code - DO NOT EDIT
	gui_Singleton = 1;
	gui_State = struct('gui_Name',       mfilename, ...
		'gui_Singleton',  gui_Singleton, ...
		'gui_OpeningFcn', @FDGUI_OpeningFcn, ...
		'gui_OutputFcn',  @FDGUI_OutputFcn, ...
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
	
% Executes just before FDGUI is made visible.
function FDGUI_OpeningFcn(hObject, eventdata, handles, varargin)
	import javax.swing.*
	import javax.swing.BorderFactory
	//import javax.swing.BorderFactory.Ethe
	import java.awt.*
	
	dbstop if error
	
	handles = call.initGUI(hObject, eventdata, handles, varargin);
	
	% Choose default command line output for FDGUI
	handles.output = hObject;
	
	handles.figure1.WindowButtonMotionFcn = @(obj, evt)FDGUI('WindowButtonMotionFcn',obj, evt,guidata(obj));
	
	assignin('base','handles',handles)	
	% Update handles structure
	guidata(hObject, handles)
	
% Outputs from this function are returned to the command line.
function varargout = FDGUI_OutputFcn(hObject, eventdata, handles)
	% Get default command line output from handles structure
	varargout{1} = handles.output;
	
	
% If it is not empty, display the TooltipString for an object in statusbarObj even when it's
% disabled. 
function WindowButtonMotionFcn(hObject, evt, handles)
% 	handles.statusbarObj.setText(['Current point: ', num2str(hObject.CurrentPoint)]);
	
	obj = hittest(hObject);
	try
		if  ~isempty(obj.TooltipString)
			handles.statusbarObj.setText(obj.TooltipString);
		end
	catch
		try
			if strcmpi(class(obj), class(handles.axes1))
				handles.statusbarObj.setText(['<html>Current 2&theta; value: ', num2str(obj.CurrentPoint(1, 1))])
			else
				handles.statusbarObj.setText(handles.xrd.Status);
			end
		catch
			handles.statusbarObj.setText('');
		end
	end
	
				
%% Pushbutton callback functions
	
%  Executes on button press in button_browse.
function button_browse_Callback(hObject, eventdata, handles)
	handles.xrd.Status='Browsing for dataset... ';
	handles = call.importData(hObject, eventdata, handles);
		
	assignin('base','handles',handles)
	guidata(hObject, handles)
	
	
% 
function edit_min2t_Callback(hObject, eventdata, handles)
	handles.xrd.Status = ['<html>Editing Min2&theta;... '];
	call.setProfileRange(hObject, handles);
	handles.xrd.Status=['<html>Min2&theta; was set to ', get(hObject,'String'),'.'];
	
% 
function edit_max2t_Callback(hObject, eventdata, handles)
	handles.xrd.Status = '<html>Editing Max2&theta;...';
	call.setProfileRange(hObject, handles);
	handles.xrd.Status = ['<html>Max2&theta; was set to ', get(hObject,'String'),'.'];
	
function edit_bkgdpoints_Callback(hObject, eventdata, handles)
	set(hObject, 'UserData', get(hObject,'value'));
	handles.xrd.Status=['Number of background points changed to ',get(hObject,'String'),'.'];
	guidata(hObject,handles)
	
	
% Executes on button press in push_addprofile.
function push_addprofile_Callback(hObject, eventdata, handles)
	handles = call.addProfile(handles);
	assignin('base','handles',handles)
	guidata(hObject, handles)
	



function menu_clearfit_Callback(hObject, eventdata, handles)
	
	
% Executes on button press in push_removeprofile.
function push_removeprofile_Callback(hObject, eventdata, handles)
	
	
	
	
% Executes on  'Update' button press.
function push_update_Callback(hObject, eventdata, handles)
	handles.xrd.Status = 'Updating fit parameters... ';
	% If data has already been fitted, ask to continue
	try call.overwriteExistingFit(handles);
	catch return
	end
	
	handles.xrd.Fmodel=[];
	if strcmpi(hObject.String, 'Edit')
		set(hObject,'string','Update');
	else
		set(hObject,'string','Edit');
	end
	
	% get new parameters
	fcnNames = handles.table_paramselection.Data(:, 1)'; % function names to use
	assert(length(fcnNames) >= length(handles.xrd.PeakPositions));
	
	constraints = handles.panel_constraints.UserData; % constraints
	coeff = handles.xrd.getCoeff(fcnNames, constraints);
	
		% Set parameters into xrd
	handles.xrd.PSfxn = fcnNames;
	handles.xrd.Constrains = constraints;
	
	set(handles.table_coeffvals,'RowName', coeff);
	handles.table_coeffvals.Data = cell(length(coeff), 3);
	
	objs = findobj(handles.tab_peak.Children);
	for i=1:length(objs)
		if isprop(objs(i), 'Enable')
			set(objs(i), 'Enable', 'off');
		end
	end
	
	set(handles.push_update,'enable','on');
	set(handles.panel_coeffs,'visible','on');
 	set(handles.panel_coeffs.Children,'visible','on', 'enable', 'on');
	set(handles.push_fitdata, 'enable', 'off');
% 	set(handles.push_editfcns, 'visible', 'on', 'enable', 'on');
	
	handles.xrd.Status = [handles.xrd.Status, 'Done.'];
	
	try 
		assert(length(handles.xrd.PeakPositions) == length(fcnNames));
	catch
		return
	end
	
	[SP,LB,UB] = handles.xrd.getDefaultStartingBounds(fcnNames, handles.xrd.PeakPositions);
	
	% Fill in table with default values if cell is empty
	for i=1:length(coeff)
		if isempty(handles.table_coeffvals.Data{i,1})
			handles.table_coeffvals.Data{i,1} = SP(i);
		end
		if isempty(handles.table_coeffvals.Data{i,2})
			handles.table_coeffvals.Data{i,2}  =LB(i);
		end
		if isempty(handles.table_coeffvals.Data{i,3})
			handles.table_coeffvals.Data{i,3} = UB(i);
		end
	end
	
	if strcmpi(handles.uitoggletool5.State,'on')
		legend(handles.xrd.DisplayName,'box','off')
	end
	
	call.plotX(handles);
	
	assignin('base','handles',handles)
	guidata(hObject,handles)
	
	
% Executes on button press in push_newbkgd.
function push_newbkgd_Callback(hObject, eventdata, handles)
	numpoints = str2num(handles.edit_bkgdpoints.String);
	polyorder = str2num(handles.edit_polyorder.String);
	handles.xrd.resetBackground(numpoints,polyorder);
	
	set(handles.tab_peak.Children, 'visible', 'off');
	
	if ~isempty(handles.xrd.bkgd2th)
		set(handles.tab_peak,'ForegroundColor',[0 0 0]);
		handles.tabgroup.SelectedTab= handles.tab_peak;
	end
	
	t12 = findobj(handles.tab_peak, 'tag', 'text12');
	set([t12, handles.edit_numpeaks], 'visible', 'on', 'enable', 'on');
	
	
	call.plotX(handles);
	
% Stop Least Squares radio button.
function radio_stopleastsquares_Callback(hObject, eventdata, handles)
	% hObject    handle to radio_stopleastsquares (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	% Hint: get(hObject,'Value') returns toggle state of radio_stopleastsquares
	
	
function uitoggletool4_ClickedCallback(hObject, eventdata, handles)
	
		
function edit_numpeaks_Callback(hObject, evt, handles)
	str = get(hObject, 'string');
	num = str2double(str);
	
	if isempty(str) || isnan(num) || num < 1
		set(handles.tab_peak.Children, 'visible', 'off');	
% 		set(hObject, 'String', '1-10', ...
% 				'FontAngle', 'italic', ...
% 				'ForegroundColor', [0.8 0.8 0.8], ...
% 				'Enable', 'inactive');
		t12 = findobj(handles.tab_peak, 'tag', 'text12');
		set([t12, handles.edit_numpeaks], 'visible', 'on');
		
	else
		handles.xrd.Status=['Number of peaks set to ',num2str(num),'.'];
		set(handles.tab_peak.Children, 'visible', 'on');
		set(handles.push_editfcns, 'visible','off');
		set(handles.panel_coeffs, 'visible', 'off');
		set(handles.panel_constraints.Children, 'enable', 'off', 'value', 0);
		set(handles.table_paramselection, ...
				'enable', 'on', ...
				'ColumnName', {'Peak function'}, ...
				'Data', cell(num, 1));
		
		set(handles.table_paramselection, 'ColumnWidth', {250});
			
	end
	
	guidata(hObject, handles)
	
	
% function edit_numpeaks_ButtonDownFcn(hObject, evt, handles)
% 	set(hObject, 'String', '', ...
% 			'FontAngle', 'normal', ...
% 			'ForegroundColor',[0 0 0], ...
% 			'Enable', 'on');
% 	uicontrol(hObject);

	
	function menu_edit_Callback(hObject, eventdata, handles)
	
	
	
function edit_lambda_Callback(hObject, eventdata, handles)
	
	% Hints: get(hObject,'String') returns contents of edit_lambda as text
	%        str2double(get(hObject,'String')) returns contents of edit_lambda as a double
	lambda=str2double(get(hObject,'String'));
	handles.xrd.lambda=lambda;
	
% Executes on button press in push_fitdata.
function push_fitdata_Callback(hObject, eventdata, handles)
	handles.xrd.Status='Fitting dataset...';
	handles = call.fitdata(hObject, eventdata, handles);
	
	handles.xrd.Status = 'Fitting dataset... Done.';
	set(handles.menu_save,'Enable','on');
	handles.tabgroup.SelectedTab = handles.tab_results;
	set(handles.tab_results,'ForegroundColor',[0 0 0]);
	set(handles.tab_results.Children,'visible', 'on');
	
	call.fillResultsTable(handles);
	
	assignin('base','handles',handles)
	guidata(hObject, handles)
	
	
% Executes on button press in push_prevprofile.
function push_prevprofile_Callback(hObject, eventdata, handles)
	i = find(handles.uipanel3==handles.profiles, 1) - 1;
	handles = call.changeProfile(i, handles);
	handles.xrd.Status = ['<html>Now editing <b>Profile ', num2str(i), '.</b></html>'];
	
	assignin('base','handles',handles)
	guidata(hObject,handles)
	
	
% Executes on button press in push_nextprofile.
function push_nextprofile_Callback(hObject, eventdata, handles)
	i = find(handles.uipanel3==handles.profiles, 1) + 1;
	handles = call.changeProfile(i, handles);
	handles.xrd.Status = ['<html>Now editing <b>Profile ', num2str(i), '.</b></html>'];
	
	assignin('base','handles',handles)
	guidata(hObject,handles)
	
function btngroup_plotresults_SelectionChangedFcn(hObject, evt, handles)
	switch hObject.SelectedObject
		case handles.radio_peakeqn
			set(handles.table_results, ...
					'ColumnName', {handles.xrd.Filename{2:end}}, ...
					'Data', handles.table_results.Data(2:end), ...
					'ColumnFormat', {'numeric'}, ...
					'ColumnWidth', {'auto'}, ...
					'ColumnEditable',0);
			
			cla(handles.axes1)
			
			
		case handles.radio_coeff
			rlen = length(handles.xrd.Fcoeff{1});
			set(handles.table_results, ...
					'ColumnName', {'', handles.xrd.Filename{:}}, ...
					'Data', [num2cell(zeros(rlen,1)), handles.table_results.Data], ...
					'ColumnFormat', {'logical', 'numeric'}, ...
					'ColumnWidth', {30, 'auto'}, ...
					'ColumnEditable',[1, handles.table_results.ColumnEditable]);
			
			handles.table_results.Data{1, 1} = true;
			
			
		otherwise
			
			
		
			
			
	end
	
	
function table_results_CellEditCallback(hObject,evt,handles)
	cla(handles.axes1)
	
	
	
% Executes on button press in push_viewall.
function push_viewall_Callback(hObject, eventdata, handles)
	handles.xrd.plotFit('all')
	
% Executes on button press in push_default.
function push_default_Callback(hObject, eventdata, handles)
	status='Clearing the table... ';
	handles.xrd.Status=status;
	
	try call.overwriteExistingFit(handles);
	catch return
	end
	
	handles.xrd.Fmodel=[];
	len = size(handles.table_coeffvals.Data,1);
	handles.table_coeffvals.Data = cell(len,4);
	set(hObject.Parent.Children,'Enable','off');
	set(handles.push_selectpeak,'Enable','on', 'string', 'Select Peak(s)');
	set(handles.table_coeffvals,'Enable','on');
	handles.xrd.plotData(get(handles.popup_filename,'Value'));
	
	if strcmpi(handles.uitoggletool5.State,'on')
		legend(handles.xrd.DisplayName,'box','off')
	end
	
	set(handles.axes2,'Visible','off');
	set(handles.axes2.Children,'Visible','off');
	handles.xrd.Status=[status,'Done.'];
	
	guidata(hObject,handles)
	
% Executes on button press of 'Select Peak(s)'.
function push_selectpeak_Callback(hObject, eventdata, handles)
	handles.xrd.Status='Selecting peak positions(s)... ';
	
	try call.overwriteExistingFit(handles);
	catch return
	end
	
	call.selectPeaks(handles);
	
	handles.xrd.Status=[handles.xrd.Status, 'Done.'];
	
	
%% Toggle Button callback functions
	
% Executes on button press in togglebutton_showbkgd.
function togglebutton_showbkgd_Callback(hObject, eventdata, handles)
	filenum=get(handles.popup_filename,'value');
	
	axes(handles.axes1)
	call.plotx(handles);
	
	if hObject.Value
		[pos,indX]=handles.xrd.getBackground;
		hold on
		plot(pos,handles.xrd.data_fit(filenum,indX),'r*')
	end
	
	
%% Checkbox callback functions
	
% Executes on button press in checkbox_lambda.
function checkbox_lambda_Callback(hObject, eventdata, handles)
	if get(hObject,'Value')
		set(handles.edit_lambda,'Enable','on');
		handles.xrd.CuKa=true;
	else
		set(handles.edit_lambda,'Enable','off');
		handles.xrd.CuKa=false;
	end
	
% Executes on button press of any checkbox in panel_constraints.
function checkboxN_Callback(hObject, eventdata, handles)
	call.constraintValueChanged(hObject, handles);
	
% Superimpose raw data.
function checkbox_superimpose_Callback(hObject, eventdata, handles)
	handles.xrd.Status='Superimposing raw data...';
	axes(handles.axes1)
	filenum=get(handles.popup_filename,'Value');
	cla
	% If box is checked, turn on hold in axes1
	if get(hObject,'Value')
		handles.xrd.DisplayName = {};
		handles.xrd.plotData(filenum,'superimpose');
		set(handles.axes2,'Visible','off');
		set(handles.axes2.Children,'Visible','off');
% 		handles.uitoggletool5.UserData=handles.uitoggletool5.State;
		uitoggletool5_OnCallback(handles.uitoggletool5, eventdata, handles)
	else
		hold off
		call.plotX(handles);
		
	end
	handles.xrd.Status='Superimposing raw data... Done.';
	
	
%% Popup callback functions
	
% Executes on selection change in popup_filename.
function popup_filename_Callback(hObject, eventdata, handles)
	% hObject.UserData: table_coeffvals values for each separate file
	filenum = get(hObject, 'Value');
	set(handles.text_filenum,'String',[num2str(filenum),' of ',num2str(length(hObject.String))]);
	set(hObject,'UserData',handles.table_coeffvals.Data);
	set(handles.listbox_files,'Value',filenum);
	
	axes(handles.axes1)
	% If superimpose box is checked, plot any subsequent data sets together
	if get(handles.checkbox_superimpose,'Value')==1
		% If there is only one dataset plotted
		if length(handles.xrd.DisplayName)==1
			% If the same dataset is chosen
			if strcmp(handles.xrd.Filename(filenum),handles.xrd.DisplayName)
				% Do nothing and exit out of the function
				return
			end
		end
		handles.xrd.plotData(filenum,'superimpose');
	else
		cla
		hold off
		handles.xrd.Status=['File changed to ',handles.xrd.Filename{filenum},'.'];
		call.plotX(handles);
	end
	
	guidata(hObject, handles)
	
function listbox_files_Callback(hObject,evt, handles)
	if length(hObject.Value)==1
		set(handles.popup_filename,'value',hObject.Value(1));
		FDGUI('popup_filename_Callback',handles.popup_filename,[],guidata(hObject));
	end
	
	
% Executes on selection change in popup_functionX where X is 1-6.
% Enables/disables checkboxes in handles.panel_constraints based on what function(s)
% are already chosen.
function popup_function1_Callback(hObject, eventdata, handles)
	contents = cellstr(get(hObject,'String'));
	tag=get(hObject,'Tag');
	selection=contents{get(hObject,'Value')};
	
	if get(hObject,'Value') > 1
		handles.xrd.Status=['Function ',tag(end),' set to ', selection,'.'];
	end
	
	call.setAvailableConstraints(handles);
	
	call.setEnableUpdateButton(handles); % enables/disables 'Update' button and panel_coeffs
	
	
% Executes on selection change in popup_numpeaks.
% Sets visibility of uipanel6 and panel_constraints.
% Sets visibility of popup_functionX in uipanel6.
% Calls popup_function1 which enables/disables panel_constraints (constraints).
% TOREMOVE
function popup_numpeaks_Callback(hObject, eventdata, handles)
	call.setFuncPopupVisibility(handles);
	
	
%% Edit box callback functions
	
% Profile Range edit box callback function.
function edit_fitrange_Callback(hObject, eventdata, handles)
	% hObject    handle to edit_fitrange (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	% Hints: get(hObject,'String') returns contents of edit_fitrange as text
	%        str2double(get(hObject,'String')) returns contents of edit_fitrange as a double
	handles.xrd.fitrange=str2double(get(hObject,'String'));
	set(hObject,'UserData',get(hObject,'value'));
	
% 
function edit_polyorder_Callback(hObject, eventdata, handles)
	set(hObject,'UserData',get(hObject,'value'));
	handles.xrd.PolyOrder=str2double(hObject.String);
	handles.xrd.Status=['Polynomial order changed to ',get(hObject,'String'),'.'];
	
	
%% uitable callback functions
	
% Executes when entered data in editable cell(s) in table_coeffvals.
function table_coeffvals_CellEditCallback(hObject, eventdata, handles)
	% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
	%	Indices: row and column indices of the cell(s) edited
	%	PreviousData: previous data for the cell(s) edited
	%	EditData: string(s) entered by the user
	%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
	%	Error: error string when failed to convert EditData to appropriate value for Data
	handles.xrd.Status=['Editing table...'];
	numpeaks=get(handles.popup_numpeaks,'Value')-1;
	r=eventdata.Indices(1);
	c=eventdata.Indices(2);
	
	if ~isa(eventdata.NewData, 'double')
		try
			num = str2double(eventdata.NewData);
			hObject.Data{r, c} = num;
		catch
			hObject.Data{r,c} = [];
			cla
			call.plotx(handles);
			return
		end
	else
		num = eventdata.NewData;
	end
	
	% If NewData is empty or was not changed
	if isnan(num)
		hObject.Data{r,c} = [];
		handles.xrd.Status=[handles.table_coeffvals.ColumnName{c},...
			' value of coefficient ',hObject.RowName{r}, ' is now empty.'];
		call.checktable_coeffvals(handles);
		cla
		call.plotx(handles);
		return
		
	else
		
		if strcmpi(hObject.RowName{r}(1), 'x') && c == 1
			ipk = str2double(hObject.RowName{r}(2));
			hObject.UserData{ipk} = num;
		end
		
		% Check if SP, LB, and UB are within bounds
		switch c
			case 1 % If first column, SP
				if num < hObject.Data{r,2}
					hObject.Data{r,2} = num;
				end
				if num > hObject.Data{r,3}
					hObject.Data{r,3} = num;
				end
			case 2 % If second column, LB
				if num > hObject.Data{r,1}
					hObject.Data{r,1} = num;
				end
				if num > hObject.Data{r,3}
					hObject.Data{r,3} = num;
				end
			case 3 % If third column, UB
				if num < hObject.Data{r,1}
					hObject.Data{r,1} = num;
				end
				if num < hObject.Data{r,2}
					hObject.Data{r,2} = num;
				end
		end
	end
	
	% Enable/disable 'Clear' button
% 	call.checktable_coeffvals(handles);
	
	if ~isempty(num)
		handles.xrd.Status=[handles.table_coeffvals.ColumnName{c},...
			' value of coefficient ',hObject.RowName{r}, ' was changed to ',num2str(num),'.'];
	end
	
	handles = call.plotSampleFit(handles);
	guidata(hObject,handles)
	
	
	
	
function table_paramselection_CellEditCallback(hObject, evt, handles)
	try
		fcnNames = hObject.Data(:, 1)';
	catch
		fcnNames=hObject.Data';
	end
	peakHasFunc = ~cellfun(@isempty, fcnNames);
	
	% Enable push_update if all peaks have a fit function selected
	if isempty(find(~peakHasFunc, 1))
		set(handles.push_update, 'enable', 'on');
	else
		set(handles.push_update, 'enable', 'off');
	end
	
	% if there is more than 1 peak with a function, enable N and f constraints
	if length(find(peakHasFunc>0)) > 1
		set(handles.checkboxN, 'Enable', 'on');
		set(handles.checkboxf, 'Enable', 'on');
	else
		set(handles.checkboxN, 'Enable', 'off');
		set(handles.checkboxf, 'Enable', 'off');
	end
	
	if length(find(strcmpi(fcnNames, 'Pearson VII') | ...
			strcmpi(fcnNames, 'Asymmetric Pearson VII'))) > 1
		set(handles.checkboxm, 'enable', 'on');
	else
		set(handles.checkboxm, 'enable', 'off');
	end
	
	if length(find(strcmpi(fcnNames, 'Psuedo Voigt'))) > 1
		set(handles.checkboxw, 'enable', 'on');
	else
		set(handles.checkboxw, 'enable', 'off');
	end
	
	
	
function table_paramselection_CellSelectionCallback(hObject, evt, handles)
	set(hObject,'ForegroundColor','white');
		
	
	
	%% Toobar callback functions
	
% Import new file(s) to fit.
function uipushtoolnew_ClickedCallback(hObject, eventdata, handles)
	menu_new_Callback(hObject, eventdata, handles);
	guidata(hObject,handles);
	
% Toggles the legend.
function uitoggletool5_ClickedCallback(hObject, eventdata, handles)
	% hObject    handle to uitoggletool5 (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    structure with handles and user data (see GUIDATA)
	
	if strcmpi(hObject.State,'on')
		handles.xrd.Status='Legend was turned on.';
		uitoggletool5_OnCallback(hObject, eventdata, handles)
	else
		handles.xrd.Status='Legend was turned off.';
		uitoggletool5_OffCallback(hObject, eventdata, handles)
	end
	
% Turns off the legend.
function uitoggletool5_OffCallback(hObject, eventdata, handles)
	set(hObject,'State','off');
	legend('hide')
	
% Turns on the legend.
function uitoggletool5_OnCallback(hObject, eventdata, handles)
	set(hObject,'State','on');
	legend(handles.xrd.DisplayName,'Box','off')
	
	%% Menu callback functions
	
function menu_new_Callback(hObject, eventdata, handles)
	handles.xrd.Status='Loading data... ';
	
	call.importData(hObject, eventdata, handles);
	
function menu_save_Callback(hObject, eventdata, handles)
	handles.xrd.Status='Saving results...';
	handles.xrd.outputError;
	handles.xrd.Status='Saving results... Done.';
	
	% ---
function menu_parameter_Callback(hObject, eventdata, handles)
	handles.xrd.Status='Loading parameter file... ';
	
	% Check if there is already a fit
	try call.overwriteExistingFit(guidata(hObject));
	catch return
	end
	
	try 
		call.loadParameterFile(handles);
	catch
	end
	
	handles.xrd.Status='Parameter file successfully loaded.';
	guidata(hObject, handles)
	
	
function menu_help_Callback(hObject, eventdata, handles)
	

function Untitled_10_Callback(hObject, eventdata, handles)
	
	
function menuHelp_fxns_Callback(hObject, eventdata, handles)
	
	
	
function edit8_Callback(hObject, eventdata, handles)
	

	
	
function menu_savefig_Callback(hObject, eventdata, handles)
	profile = find(handles.uipanel3==handles.profiles,1);
	fitOutputPath =strcat(handles.xrd.DataPath,'FitOutputs/Fit_Figure/');
	if ~exist(fitOutputPath,'dir')
		mkdir(fitOutputPath);
	end
	
	tot=handles.text_numprofile.String(end);
	
	for s=1:length(handles.xrd.Filename)
		f_new=figure;
		a1=copyobj(handles.axes1,f_new);
		a2=copyobj(handles.axes2,f_new);
		
		filename=['Profile ',num2str(profile),' of ',tot,' - ',handles.xrd.Filename{s}];
		set(gcf,'name',filename,'numbertitle','off');
		set(a1.Title,'String',filename);
		saveas(gcf,[fitOutputPath,filename,'-plotFit.png'])
		delete(gcf)
	end
	
	handles.xrd.plotFit('all')
	saveas(figure(5),strcat(fitOutputPath,'Profile ',num2str(profile), 'of ',tot,' - ',strcat('Master','-','plotFit')));
	delete(gcf);
	
	
function menu_clearall_Callback(hObject, eventdata, handles)
	
	% If there is data loaded, confirm
	ans=questdlg('This will reset the figure and your data will be lost.','Warning','Continue','Cancel','Cancel');
	if strcmp(ans,'Continue')
		handles.xrd = PackageFitDiffractionData;
		handles.xrdContainer = handles.xrd;
		set(handles.panel_rightside,'Visible','off');
		set(handles.edit8,...
			'String', 'Upload new file(s)...',...
			'FontAngle', 'italic',...
			'ForegroundColor', [0.5 0.5 0.5]);
	end
	
	
function menu_close_Callback(hObject, eventdata, handles)
	ans=questdlg('Are you sure you want to quit?','Warning','Yes','No','Yes');
	if strcmp(ans,'Yes')
		delete(gcf)
	end
	
function menu_bkgdpoints_Callback(hObject, eventdata, handles)
	
	
% Menu: File -> Save As callback function
function Untitled_7_Callback(hObject, eventdata, handles)
	
% Menu option callback to Import Workspace.
function Untitled_9_Callback(hObject, eventdata, handles)
	
%% Custom helper functions
	
% Executes when the active tab changes to/from 'Setup' and 'Peak Selection'.
function tabgroup_SelectionChangedFcn(hObject, eventdata, handles)	
	% If user switches to 'Peak Selection' tab from 'Setup' tab and there is no
	% background, issue warning
	if hObject.SelectedTab ~= handles.tab_setup && isempty(handles.xrd.bkgd2th)
		hObject.SelectedTab = eventdata.OldValue;
		uiwait(warndlg('Please select background points first.','No Background Points'));
		return
	end
	
	if strcmpi(hObject.SelectedTab.Tag, handles.tab_results.Tag) && isempty(handles.xrd.Fmodel)
		hObject.SelectedTab = eventdata.OldValue;
		uiwait(warndlg('No results available - dataset has not yet been fitted.','No Results Available'));
		return
	end
	
	
%% CreateFcns and Unused Callbacks

% Executes during object creation, after setting all properties.
function edit_min2t_CreateFcn(hObject, eventdata, handles)
	% hObject    handle to edit_min2t (see GCBO)
	% eventdata  reserved - to be defined in a future version of MATLAB
	% handles    empty - handles not created until after all CreateFcns called
	
	% Hint: edit controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	% --- Executes during object creation, after setting all properties.
function edit_max2t_CreateFcn(hObject, eventdata, handles)
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	% Hint: popupmenu controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	% --- Executes during object creation, after setting all properties.
function edit_bkgdpoints_CreateFcn(hObject, eventdata, handles)
	
	% Hint: edit controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
% Executes during object creation, after setting all properties.
function edit_polyorder_CreateFcn(hObject, eventdata, handles)
	
	% Hint: edit controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	
% Executes during object creation, after setting all properties.
function popup_filename_CreateFcn(hObject, eventdata, handles)
	handles.n=1;
	% Hint: popupmenu controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
% Executes during object creation, after setting all properties.
function popup_numpeaks_CreateFcn(hObject, eventdata, handles)
	
	% Hint: popupmenu controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
function menu_file_Callback(hObject, eventdata, handles)
	
% Executes during object creation, after setting all properties.
function edit_fitrange_CreateFcn(hObject, eventdata, handles)
	
	% Hint: edit controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	
% Executes during object creation, after setting all properties.
function popup_function1_CreateFcn(hObject, eventdata, handles)
	
	% Hint: popupmenu controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
% Executes during object creation, after setting all properties.
function popup_function2_CreateFcn(hObject, eventdata, handles)
	
	% Hint: popupmenu controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
% Executes during object creation, after setting all properties.
function popup_function3_CreateFcn(hObject, eventdata, handles)
	
	% Hint: popupmenu controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
% Executes during object creation, after setting all properties.
function popup_function4_CreateFcn(hObject, eventdata, handles)
	
	% Hint: popupmenu controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
% Executes during object creation, after setting all properties.
function popup_function5_CreateFcn(hObject, eventdata, handles)
	
	% Hint: popupmenu controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
% Executes during object creation, after setting all properties.
function popup_function6_CreateFcn(hObject, eventdata, handles)
	
	% Hint: popupmenu controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	
% Executes when selected object is changed in uibuttongroup2.
function uibuttongroup2_SelectionChangedFcn(hObject, eventdata, handles)
	

% Executes on mouse press over axes background.
function axes2_ButtonDownFcn(hObject, eventdata, handles)
	


	
% Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
	
	% Hint: edit controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	

	
% Executes during object creation, after setting all properties.
function edit_lambda_CreateFcn(hObject, eventdata, handles)
	
	% Hint: edit controls usually have a white background on Windows.
	%       See ISPC and COMPUTER.
	if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
		set(hObject,'BackgroundColor','white');
	end
	
	
