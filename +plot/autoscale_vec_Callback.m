function autoscale_vec_Callback(~, ~, ~)
handles=gui.gethand;
if get(handles.autoscale_vec, 'value')==1
	set(handles.vectorscale,'enable', 'off');
else
	set(handles.vectorscale,'enable', 'on');
end

