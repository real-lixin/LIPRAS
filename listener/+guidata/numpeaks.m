% This function runs when edit_numpeaks UserData changes
function numpeaks(~, ~, handles)
if strcmpi(handles.edit_numpeaks.Visible, 'off')
		return
end

set(handles.btns2, 'visible', 'on');
set(handles.panel_constraints, 'visible', 'off');
set(handles.tab2_panel1, 'visible', 'off');

num = handles.edit_numpeaks.UserData;
if isempty(num)
		return
		
elseif num == 1
		set(handles.tab2_panel1, 'visible', 'on');
		
elseif num > 1
		set(handles.panel_constraints, 'visible', 'on');
		set(handles.tab2_panel1, 'visible', 'on');
end
