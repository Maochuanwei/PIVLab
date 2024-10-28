function [OutputError,ima,frame_nr_display] = PIVlab_capture_OPTRONIS_calibration_image(img_amount,exposure_time,ROI_OPTRONIS)
OutputError=0;
hgui=getappdata(0,'hgui');
%% Prepare camera
try
	delete(imaqfind); %clears all previous videoinputs
	warning off
	hwinf = imaqhwinfo;
	warning on
	%imaqreset
catch
	errordlg('Error: Image Acquisition Toolbox not available! This camera needs the image acquisition toolbox.','Error!','modal')
	disp('Error: Image Acquisition Toolbox not available! This camera needs the image acquisition toolbox.')
end
info = imaqhwinfo(hwinf.InstalledAdaptors{1});
if strcmp(info.AdaptorName,'gentl')
	disp('gentl adaptor found.')
else
	disp('ERROR: gentl adaptor not found. Please install the GenICam / GenTL support package from here:')
	disp('https://de.mathworks.com/matlabcentral/fileexchange/45180')
	errordlg({'ERROR: gentl adaptor not found. Please got to Matlab file exchange and search for "GenICam Interface " to install it.' 'Link: https://de.mathworks.com/matlabcentral/fileexchange/45180'},'Error, support package missing','modal')
end

try
	OPTRONIS_name = info.DeviceInfo.DeviceName;
catch
	errordlg('Error: Camera not found! Is it connected?','Error!','modal')
end

if contains(OPTRONIS_name,'Cyclone-2-2000-M')
	disp(['Found camera: ' 'Cyclone-2-2000-M'])
elseif contains (OPTRONIS_name,'Cyclone-1HS-3500-M')
	disp(['Found camera: ' 'Cyclone-1HS-3500-M'])
elseif contains (OPTRONIS_name,'Cyclone-25-150-M')
	disp(['Found camera: ' 'Cyclone-25-150-M'])
else
	disp('camera type unknown!')
end
warning('off','imaq:gentl:hardwareTriggerTriggerModeOff'); %trigger property of OPTRONIS cannot be set in Matlab.
warning('off','MATLAB:JavaEDTAutoDelegation'); %strange warning

OPTRONIS_supported_formats = info.DeviceInfo.SupportedFormats;
% select bitmode (some support 8, 10, 12 bits)

bitmode =8; %in calibration mode: 10 bit would make sense, but in Matlab, all data that is returned from OPTRONIS is 8 bit...
OPTRONIS_vid = videoinput(info.AdaptorName,info.DeviceInfo.DeviceID,['Mono' sprintf('%0.0d',bitmode)]);

OPTRONIS_settings = get(OPTRONIS_vid);
OPTRONIS_settings.PreviewFullBitDepth='On';
OPTRONIS_vid.PreviewFullBitDepth='On';

%OPTRONIS trigger source cannot be set in Matlab. Therefore always set to
%external. Synchronizer must always run.
triggerconfig(OPTRONIS_vid, 'hardware','DeviceSpecific','DeviceSpecific');
OPTRONIS_settings.TriggerSource = 'SingleFrame';
%OPTRONIS_settings.Source.ExposureMode = 'Timed';
OPTRONIS_settings.TriggerMode ='On';
OPTRONIS_src=getselectedsource(OPTRONIS_vid);


ROI_OPTRONIS=[ROI_OPTRONIS(1)-1,ROI_OPTRONIS(2)-1,ROI_OPTRONIS(3),ROI_OPTRONIS(4)];
OPTRONIS_vid.ROIPosition=ROI_OPTRONIS;


%the synchronizer of the optronis must also generate a trigger signal in
%calibration mode, because the optronis cannot be set to internal
%triggering in matlab.
%The signal from the synchronizer must be slower than the min frame rate of
%the optronis. It is currently set to 12.5 Hz in the synchronizer
preview_framerate=20;
OPTRONIS_src.AcquisitionFrameRate = preview_framerate; %min framerate that the OPTRONIS can do

if contains(OPTRONIS_name,'Cyclone-2-2000-M')
	exposure_gap=2;
elseif contains (OPTRONIS_name,'Cyclone-1HS-3500-M')
	exposure_gap=2;
elseif contains (OPTRONIS_name,'Cyclone-25-150-M')
	exposure_gap=24;
else
	exposure_gap=111;
end

if exposure_time > 1/preview_framerate*1000^2-exposure_gap % max exposure time allowed for
	exposure_time = 1/preview_framerate*1000^2-exposure_gap;
	disp(['Exposure time adjusted to ' num2str(exposure_time) ' µs (' num2str(exposure_time/1000) ' ms)'])
end
if exposure_time < 500 % min exposure time allowed for
	exposure_time = 500;
	disp(['Exposure time adjusted to ' num2str(exposure_time) ' µs (' num2str(exposure_time/1000) ' ms)'])
end
OPTRONIS_src.ExposureTime =exposure_time;


%% prepare axis

crosshair_enabled = getappdata(hgui,'crosshair_enabled');
sharpness_enabled = getappdata(hgui,'sharpness_enabled');
PIVlab_axis = findobj(hgui,'Type','Axes');

image_handle_OPTRONIS=imagesc(zeros(ROI_OPTRONIS(4),ROI_OPTRONIS(3)),'Parent',PIVlab_axis,[0 2^bitmode]);

setappdata(hgui,'image_handle_OPTRONIS',image_handle_OPTRONIS);

frame_nr_display=text(100,100,'Initializing...','Color',[1 1 0]);
colormap default %reset colormap steps
new_map=colormap('gray');
new_map(1:3,:)=[0 0.2 0;0 0.2 0;0 0.2 0];
new_map(end-2:end,:)=[1 0.7 0.7;1 0.7 0.7;1 0.7 0.7];
colormap(new_map);axis image;
set(gca,'ytick',[])
set(gca,'xtick',[])
colorbar


%% get images
OPTRONIS_vid.FramesPerTrigger = 1;
set(frame_nr_display,'String','');
warning('off','imaq:gentl:hardwareTriggerTriggerModeOff'); %trigger property of OPTRONIS cannot be set in Matlab.
warning('off','MATLAB:JavaEDTAutoDelegation'); %strange warning
preview(OPTRONIS_vid,image_handle_OPTRONIS)


OPTRONIS_src.AcquisitionFrameRate = 20; % needs to be set again on the optronis after starting preview or acquisition
OPTRONIS_src.ExposureTime =exposure_time;

caxis([0 2^bitmode]); %seems to be a workaround to force preview to show full data range...
displayed_img_amount=0;
while getappdata(hgui,'cancel_capture') ~=1 && displayed_img_amount < img_amount
	ima = image_handle_OPTRONIS.CData;%*16; %stretch 12 bit to 16 bit
	%% sharpness indicator
	sharpness_enabled = getappdata(hgui,'sharpness_enabled');
	if sharpness_enabled == 1 % sharpness indicator
		textx=1240;
		texty=950;
		[~,~] = PIVlab_capture_sharpness_indicator (ima,textx,texty);
	else
		delete(findobj('tag','sharpness_display_text'));
	end
	crosshair_enabled = getappdata(hgui,'crosshair_enabled');
	if crosshair_enabled == 1 %cross-hair
		%% cross-hair
		locations=[0.15 0.5 0.85];
		half_thickness=1;
		brightness_incr=101;
		ima_ed=ima;
		old_max=max(ima(:));
		for loca=locations
			%vertical
			ima_ed(:,round(size(ima,2)*loca)-half_thickness:round(size(ima,2)*loca)+half_thickness)=ima_ed(:,round(size(ima,2)*loca)-half_thickness:round(size(ima,2)*loca)+half_thickness)+brightness_incr;
			%horizontal
			ima_ed(round(size(ima,1)*loca)-half_thickness:round(size(ima,1)*loca)+half_thickness,:)=ima_ed(round(size(ima,1)*loca)-half_thickness:round(size(ima,1)*loca)+half_thickness,:)+brightness_incr;
		end
		ima_ed(ima_ed>old_max)=old_max;
		set(image_handle_OPTRONIS,'CData',ima_ed);
	end
	%% HISTOGRAM
	if getappdata(hgui,'hist_enabled')==1
		if isvalid(image_handle_OPTRONIS)
			hist_fig=findobj('tag','hist_fig');
			if isempty(hist_fig)
				hist_fig=figure('numbertitle','off','MenuBar','none','DockControls','off','Name','Live histogram','Toolbar','none','tag','hist_fig','CloseRequestFcn', @HistWindow_CloseRequestFcn);
			end
			if ~exist ('old_hist_y_limits','var')
				old_hist_y_limits =[0 35000];
			else
				if isvalid(hist_obj)
					old_hist_y_limits=get(hist_obj.Parent,'YLim');
				end
			end
			hist_obj=histogram(ima(1:2:end,1:2:end),'Parent',hist_fig,'binlimits',[0 2^bitmode]);
		end
		%lowpass hist y limits for better visibility
		if ~exist ('new_hist_y_limits','var')
			new_hist_y_limits =[0 35000];
		end
		new_hist_y_limits=get(hist_obj.Parent,'YLim');
		set(hist_obj.Parent,'YLim',(new_hist_y_limits*0.5 + old_hist_y_limits*0.5))
	else
		hist_fig=findobj('tag','hist_fig');
		if ~isempty(hist_fig)
			close(hist_fig)
		end
	end
	%drawnow limitrate;
	drawnow limitrate
	%% Autofocus
	%% Lens control
	%Sowieso machen: Nicht lineare schritte für die anzufahrenden fokuspositionen. Diese Liste vorher ausrechnen und dann nur index anspringen

	autofocus_enabled = getappdata(hgui,'autofocus_enabled');

	if autofocus_enabled == 1
		delaycounter=delaycounter+1;
	else
		delaycounter=0;
		delaycounter2=0;
		delay_time_1=tic;
	end
	%immer mehrere Bilder abfragen nachdem fokus verstellt wurde.... nicht nur eins, sondern z.B. drei Davon nur das letzte per sharpness beurteilen

	delay_time= 0.5; %1 seconds delay between measurements %350000 / exposure_time;
	if autofocus_enabled == 1
		if delaycounter>10 %wait 10 images before starting autofocus. Needed so that servo can reach target position
			focus_start = getappdata(hgui,'focus_servo_lower_limit');
			focus_end = getappdata(hgui,'focus_servo_upper_limit');
			amount_of_raw_steps=20;
			fine_step_resolution_increase = 8;
			focus_step_raw=round(abs(focus_end - focus_start)/amount_of_raw_steps);% in microseconds)
			focus_step_fine=round(1/fine_step_resolution_increase*(abs(focus_end - focus_start)/amount_of_raw_steps));% in microseconds)
			if ~exist('sharpness_focus_table','var') || isempty(sharpness_focus_table) || isempty(sharp_loop_cnt)
				sharpness_focus_table=zeros(1,2);
				sharp_loop_cnt=0;
				focus=focus_start;
				raw_finished=0;
				aperture=getappdata(hgui,'aperture');
				lighting=getappdata(hgui,'lighting');
				PIVlab_capture_lensctrl(focus,aperture,lighting)
			end
			if raw_finished==0
				if focus < focus_end % maxialer focus = endanschlag. Bis zu dem wert wird von null gefahren
					if toc(delay_time_1)>=delay_time %only every second image is taken for analysis. This gives more time to the servo to reach position
						delay_time_1=tic;
						sharp_loop_cnt=sharp_loop_cnt+1;
						[sharpness,~] = PIVlab_capture_sharpness_indicator (ima,[],[]);
						sharpness_focus_table(sharp_loop_cnt,1)=focus;
						sharpness_focus_table(sharp_loop_cnt,2)=sharpness;
						focus=focus+focus_step_raw;
						PIVlab_capture_lensctrl(focus,aperture,lighting)		%kann steuern und aktuelle position ausgeben
						autofocus_notification(1)
					else
						%do nothing
					end
				else
					%assignin('base','sharpness_focus_table',sharpness_focus_table)
					%find best focus
					[r,~]=find(sharpness_focus_table == max(sharpness_focus_table(:,2)));
					focus_peak=sharpness_focus_table(r(1),1);
					disp(['Best raw focus: ' num2str(focus_peak)])
					raw_finished=1;
					%focus vs. distance is not linear!
					focus_start_fine=focus_peak-6*focus_step_raw; %start of finer focussearch
					focus_end_fine=focus_peak+3*focus_step_raw;
					if focus_start_fine < focus_start
						focus_start_fine = focus_start;
					end
					if focus_end_fine > focus_end
						focus_end_fine = focus_end;
					end
					%original focus=focus_end_fine;
					focus=focus_start_fine;
					PIVlab_capture_lensctrl(focus,aperture,lighting)
					sharp_loop_cnt=0;
					raw_data=[sharpness_focus_table(:,1),normalize(sharpness_focus_table(:,2),'range')];
					sharpness_focus_table=zeros(1,2);
				end
			end

			if raw_finished == 1
				delaycounter2=delaycounter2+1;
			else
				delaycounter2=0;
			end


			if raw_finished == 1
				delay_time= 0.35;
				if delaycounter2>10
					%repeat with finer steps
					%original if focus > focus_start_fine % maxialer focus = endanschlag. Bis zu dem wert wird von null gefahren
					if focus < focus_end_fine % maxialer focus = endanschlag. Bis zu dem wert wird von null gefahren
						if toc(delay_time_1)>=delay_time %only every second image is taken for analysis. This gives more time to the servo to reach position
							delay_time_1=tic;
							sharp_loop_cnt=sharp_loop_cnt+1;
							[sharpness,~] = PIVlab_capture_sharpness_indicator (ima,[],[]);
							sharpness_focus_table(sharp_loop_cnt,1)=focus;
							sharpness_focus_table(sharp_loop_cnt,2)=sharpness;
							%original focus=focus-focus_step_fine;
							focus=focus+focus_step_fine;
							PIVlab_capture_lensctrl(focus,aperture,lighting)		%kann steuern und aktuelle position ausgeben
							autofocus_notification(1)
						else
							%do nothing
						end
					else %fine focus search finished
						%assignin('base','sharpness_focus_table',sharpness_focus_table)
						%find best focus
						[r,~]=find(sharpness_focus_table == max(sharpness_focus_table(:,2)));
						focus_peak=sharpness_focus_table(r(1),1);
						disp(['Best fine focus: ' num2str(focus_peak)])
						PIVlab_capture_lensctrl(focus_end_fine,aperture,lighting)%backlash compensation
						pause(0.5)
						PIVlab_capture_lensctrl(focus_start_fine,aperture,lighting) %backlash compensation
						pause(0.5)
						PIVlab_capture_lensctrl(focus_peak,aperture,lighting) %set to best focus

						setappdata(hgui,'autofocus_enabled',0); %autofocus am ende ausschalten

						lens_control_window = getappdata(0,'hlens');
						focus_edit_field=getappdata(lens_control_window,'handle_to_focus_edit_field');
						set(focus_edit_field,'String',num2str(focus_peak)); %update
						%setappdata(hgui,'cancel_capture',1); %stop recording....?
						figure;plot(raw_data(:,1),raw_data(:,2))
						hold on;plot(sharpness_focus_table(:,1),normalize(sharpness_focus_table(:,2),'range'));hold off
						title('Focus search')
						xlabel('Pulsewidth us')
						ylabel('Sharpness')
						legend('Coarse search','Fine search')
						grid on

					end
				end
			end
		end
	else
		autofocus_notification(0)
		sharpness_focus_table=[];
		sharp_loop_cnt=[];
	end



	if img_amount == 1
		if sum(ima(1:10,1,1)) ~=10 %check if the display was updated, if there is real camera data. I didnt find a more elegant way...
			displayed_img_amount=displayed_img_amount+1;
		end
	end


end
stoppreview(OPTRONIS_vid)

function autofocus_notification(running)
auto_focus_active_hint=findobj('tag', 'auto_focus_active');
if running == 1

	hgui=getappdata(0,'hgui');
	PIVlab_axis = findobj(hgui,'Type','Axes');
	postix=get(PIVlab_axis,'XLim');
	postiy=get(PIVlab_axis,'YLim');
	bg_col=get(auto_focus_active_hint,'BackgroundColor'); % Toggle background color while autofocus is active

	if ~isempty(bg_col)
		if  sum(bg_col)==0.75 %hint is currently displayed
			bg_col = [0.05 0.05 0.05];
		else
			bg_col = [0.25 0.25 0.25];
		end
		set(auto_focus_active_hint,'BackgroundColor',bg_col);
	else
		bg_col= [0.25 0.25 0.25];
		axes(PIVlab_axis);
		text(postix(2)/2,postiy(2)/2,'Autofocus running, please wait...','HorizontalAlignment','center','VerticalAlignment','middle','color','y','fontsize',24, 'BackgroundColor', bg_col,'tag','auto_focus_active','margin',10,'Clipping','on');

	end
else
	delete(auto_focus_active_hint);
end

function HistWindow_CloseRequestFcn(hObject,~)
hgui=getappdata(0,'hgui');
setappdata(hgui,'hist_enabled',0);
try
	delete(hObject);
catch
	delete(gcf);
end
