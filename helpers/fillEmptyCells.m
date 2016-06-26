
% --- 
function isFilled = fillEmptyCells(handles)
% --- Fills empty cells in uitable1 with their default values only if the
% initial peak positions are in the table. 
profile=find(handles.uipanel3==handles.profiles);

param = getUpdatedParam(handles);
fxns = param.fcnNames;
rowname = handles.uitable1.RowName;
pos = param.peakPositions;
isFilled = false;

% If not enough peak positions for each function, only fill in the cells
% for the available peak positions
if length(pos) < length(fxns)
	for i=1:length(rowname)
		if rowname{i}(1) == 'x'
			peaknum = str2double(rowname{i}(2));
			if peaknum > length(pos)
				return
			end
			
			handles.uitable1.Data{i} = pos(peaknum);
		end
	end
end

[SP,LB,UB] = handles.xrd.getDefaultStartingBounds(fxns, pos);

% Fill in table with default values if cell is empty
for i=1:length(param.coeff)
	if isempty(handles.uitable1.Data{i,1})
		handles.uitable1.Data{i,1} = SP(i);
	end
	if isempty(handles.uitable1.Data{i,2})
		handles.uitable1.Data{i,2}  =LB(i);
	end
	if isempty(handles.uitable1.Data{i,3})
		handles.uitable1.Data{i,3} = UB(i);
	end
end

isFilled = true;

if strcmpi(handles.uitoggletool5.State,'on')
	legend(handles.xrd.DisplayName,'box','off')
end

plotSampleFit(handles);

guidata(handles.uitable1,handles)
