function streamrake_Callback(~, ~, ~)
handles=gui.gethand;
toggler=gui.retr('toggler');
selected=2*floor(get(handles.fileselector, 'value'))-(1-toggler);
resultslist=gui.retr('resultslist');
currentframe=floor(get(handles.fileselector, 'value'));
if size(resultslist,2)>=currentframe && numel(resultslist{1,currentframe})>0
	gui.toolsavailable(0);
	x=resultslist{1,currentframe};
	y=resultslist{2,currentframe};
	typevector=resultslist{5,currentframe};
	if size(resultslist,1)>6 %filtered exists
		if size(resultslist,1)>10 && numel(resultslist{10,currentframe}) > 0 %smoothed exists
			u=resultslist{10,currentframe};
			v=resultslist{11,currentframe};
			typevector=resultslist{9,currentframe}; %von smoothed
		else
			u=resultslist{7,currentframe};
			if size(u,1)>1
				v=resultslist{8,currentframe};
				typevector=resultslist{9,currentframe}; %von smoothed
			else
				u=resultslist{3,currentframe};
				v=resultslist{4,currentframe};
				typevector=resultslist{5,currentframe};
			end
		end
	else
		u=resultslist{3,currentframe};
		v=resultslist{4,currentframe};
	end
	ismean=gui.retr('ismean');
	if    numel(ismean)>0
		if ismean(currentframe)==1 %if current frame is a mean frame, typevector is stored at pos 5
			typevector=resultslist{5,currentframe};
		end
	end
	calu=gui.retr('calu');calv=gui.retr('calv');
	ustream=u-(gui.retr('subtr_u')/gui.retr('calu'));
	vstream=v-(gui.retr('subtr_v')/gui.retr('calv'));
	ustream(typevector==0)=nan;
	vstream(typevector==0)=nan;
	calxy=gui.retr('calxy');
	button=1;
	streamlinesX=gui.retr('streamlinesX');
	streamlinesY=  gui.retr('streamlinesY');
	if get(handles.holdstream,'value')==1
		if numel(streamlinesX)>0
			i=size(streamlinesX,2)+1;
			xposition=streamlinesX;
			yposition=streamlinesY;
		else
			i=1;
		end
	else
		i=1;
		gui.put('streamlinesX',[]);
		gui.put('streamlinesY',[]);
		xposition=[];
		yposition=[];
		delete(findobj('tag','streamline'));
	end
	[rawx,rawy,~] = ginput(1);
	hold on; scatter(rawx,rawy,'y*','tag','streammarker');hold off;
	[rawx(2),rawy(2),~] = ginput(1);
	delete(findobj('tag','streammarker'))
	rawx=linspace(rawx(1),rawx(2),str2num(get(handles.streamlamount,'string')));
	rawy=linspace(rawy(1),rawy(2),str2num(get(handles.streamlamount,'string')));

	xposition(i:i+str2num(get(handles.streamlamount,'string'))-1)=rawx;
	yposition(i:i+str2num(get(handles.streamlamount,'string'))-1)=rawy;
	h=streamline(plot.mmstream2(x,y,ustream,vstream,xposition(i),yposition(i),'on'));
	set (h,'tag','streamline');
	i=i+1;
end
if size(resultslist,2)>=currentframe && numel(resultslist{1,currentframe})>0
	delete(findobj('tag','streamline'));
	h=streamline(plot.mmstream2(x,y,ustream,vstream,xposition,yposition,'on'));
	contents = get(handles.streamlcolor,'String');
	set(h,'LineWidth',get(handles.streamlwidth,'value'),'Color', contents{get(handles.streamlcolor,'Value')});
	set (h,'tag','streamline');
	gui.put('streamlinesX',xposition);
	gui.put('streamlinesY',yposition);
end
gui.toolsavailable(1);

