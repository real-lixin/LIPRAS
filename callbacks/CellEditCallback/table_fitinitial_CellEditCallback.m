% Executes when entered data in editable cell(s) in table_coeffvals.
function table_fitinitial_CellEditCallback(hObject, eventdata, handles)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
profiledata = handles.cfit(handles.guidata.currentProfile);
numpeaks = profiledata.NumPeaks;
r=eventdata.Indices(1);
c=eventdata.Indices(2);
cp = handles.guidata.currentProfile;

if ~isa(eventdata.NewData, 'double')
    try
        num = str2double(eventdata.NewData);
        hObject.Data{r, c} = num;
    catch
        hObject.Data{r,c} = eventdata.PreviousData;
        %         cla
        plotX(handles);
        return
    end
else
    num = eventdata.NewData;
end

% If NewData is empty or was not changed
if isnan(num)
    hObject.Data{r,c} = eventdata.PreviousData;
    plotX(handles);
else
    
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

if ~isempty(num)
    handles.xrd.Status=[handles.table_fitinitial.ColumnName{c},...
        ' value of coefficient ',hObject.RowName{r}, ' was changed to ',num2str(num),'.'];
end

plotX(handles, 'sample');
emptyCell = find(cellfun(@isempty, handles.table_fitinitial.Data(:, 1:3)), 1);
if isempty(emptyCell)
    set(handles.push_fitdata, 'enable', 'on');
else
    set(handles.push_fitdata, 'enable', 'off');
end

assignin('base', 'handles', handles);
guidata(hObject,handles)