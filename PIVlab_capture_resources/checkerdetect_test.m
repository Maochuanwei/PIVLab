%% Live image rectification of a checkerboard in the FOV of the optocam


clear variables
close all

exposure_time = 2000;
imaq_error=0;
try
	delete(imaqfind); %clears all previous videoinputs
	warning off
	hwinf = imaqhwinfo;
	warning on
	%imaqreset
catch
	imaq_error=1;
end
if imaq_error==0
	if isempty(hwinf.InstalledAdaptors)
		imaq_error=2;
	end
end
if imaq_error==0
	info = imaqhwinfo(hwinf.InstalledAdaptors{1});
	if strcmp(info.AdaptorName,'gentl')
		disp('gentl adaptor found.')
	else
		imaq_error=2;
	end
end
if imaq_error==0
	try
		OPTOcam_name = info.DeviceInfo.DeviceName;
	catch
		imaq_error=3;
	end
end
if imaq_error==1
	errordlg('Error: Image Acquisition Toolbox not available! This camera needs the image acquisition toolbox.','Error!','modal')
	disp('Error: Image Acquisition Toolbox not available! This camera needs the image acquisition toolbox.')
elseif imaq_error==2
	disp('ERROR: gentl adaptor not found. Please install the GenICam / GenTL support package from here:')
	disp('https://de.mathworks.com/matlabcentral/fileexchange/45180')
	errordlg({'ERROR: gentl adaptor not found. Please got to Matlab file exchange and search for "GenICam Interface " to install it.' 'Link: https://de.mathworks.com/matlabcentral/fileexchange/45180'},'Error, support package missing','modal')
elseif imaq_error==3
	errordlg('Error: Camera not found! Is it connected?','Error!','modal')
end

disp(['Found camera: ' OPTOcam_name])

OPTOcam_supported_formats = info.DeviceInfo.SupportedFormats;
OPTOcam_vid = videoinput(info.AdaptorName,info.DeviceInfo.DeviceID,'Mono8'); %calibration image in 12 bit always.

OPTOcam_settings = get(OPTOcam_vid);
OPTOcam_settings.Source.DeviceLinkThroughputLimitMode = 'off';
OPTOcam_settings.PreviewFullBitDepth='On';
OPTOcam_vid.PreviewFullBitDepth='On';

triggerconfig(OPTOcam_vid, 'manual');
OPTOcam_settings.TriggerMode ='manual';
OPTOcam_settings.Source.TriggerMode ='Off';
OPTOcam_settings.Source.ExposureMode ='Timed';
OPTOcam_settings.Source.ExposureTime =exposure_time;


OPTOcam_settings.Source.ReverseX = 'True';
OPTOcam_settings.Source.ReverseY = 'True';
    OPTOcam_gain=0;
OPTOcam_settings.Source.Gain = OPTOcam_gain;

%% prapare axis

image_handle_OPTOcam=imagesc(zeros(1216,1936),[0 2^8]);


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
OPTOcam_vid.FramesPerTrigger = 1;
set(frame_nr_display,'String','');
preview(OPTOcam_vid,image_handle_OPTOcam)
caxis([0 2^8]); %seems to be a workaround to force preview to show full data range...
displayed_img_amount=0;
hold on
plot_overlay=plot([1,1],[1,1],'ro');
hold off
while true
    ima = image_handle_OPTOcam.CData;%*16; %stretch 12 bit to 16 bit
    
[imagePoints,boardSize] = detectCheckerboardPoints(ima);

if ~isempty(imagePoints)
plot_overlay.XData = imagePoints(:,1);
plot_overlay.YData = imagePoints(:,2);


	%if isempty(find(isnan(imagePoints)))

%kann man herausfinden aus den detektierten checkerpoints (imagepoints). dann gleiche zahl verwenden --> ergibt gleich grosses bild.
		%punkteorder stimmt hier nicht wenn bild schief.
oldimagePoints=imagePoints;
diffx=diff(oldimagePoints(:,1));
diffy=diff(oldimagePoints(:,2));
diffx(diffx<=0)=[];
diffy(diffy<=0)=[];
mean_x_size=mean(diffx,'omitnan')
mean_y_size=mean(diffy,'omitnan')
squareSize=(mean_x_size+mean_y_size)/2;
		
		worldPoints = generateCheckerboardPoints(boardSize,squareSize);
		


worldPoints(any(isnan(imagePoints), 2), :) = [];

imagePoints(any(isnan(imagePoints), 2), :) = [];	



		tform = fitgeotform2d(imagePoints,worldPoints,'Projective');
		%% Here, and interpolated image will be interpolated a second time
		undistorted_rectified = imwarp(ima,tform);
		image_handle_OPTOcam.CData=undistorted_rectified;
	%end

end
	%% sharpness indicator
    drawnow limitrate;
 
end
stoppreview(OPTOcam_vid)
