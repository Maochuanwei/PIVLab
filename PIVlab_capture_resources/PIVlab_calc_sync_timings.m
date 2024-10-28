function timing_table = PIVlab_calc_sync_timings(camera_type,camera_sub_type,bitrate,framerate,exposure_time,interframe,laser_energy)

timing_table=[]; %zeilen: die verschiedenen pins; spalten:die zeiten

%output kommando ist dann vorläufig.
%sequence:frametime:useExt,extDelay:pin1time1,pin1time2,...:pin2time1,pin2time2,...

if strcmp(camera_type,'OPTOcam')

end

if strcmp(camera_type,'pco_pixelfly')

end

if strcmp(camera_type,'pco_panda')

end

if strcmp(camera_type,'chronos')

end

if strcmp(camera_type,'basler')

end

if strcmp(camera_type,'flir')

end

if strcmp(camera_type,'OPTOcam')

end

if strcmp(camera_type,'OPRONIS')
	switch camera_sub_type
		case 'Cyclone-2-2000-M'
		case 'Cyclone-1HS-3500-M'
		case 'Cyclone-25-150-M'
		otherwise
	end
end

PIVlab_plot_sync_timing_table(timing_table) %gleich Funktion schreiben die ergebnis korrekt plottet. Besser zum programieren wenn man direkt was sieht.




%{
   Freq_sgl = Freq                                          '/camera_scale
   Freq_sgl = 1 / Freq_sgl
   Freq_sgl = Freq_sgl * 1000000
   Period_sgl = Freq_sgl
   If Camera_bits = 8 Then
      Dead_time_sgl = 44                                    'Messen: zeit die die kamera zwischen den belichtungen blind ist
      Delay_trigger_to_exposure_sgl = 17                    'Messen: Delay der Kamera von triggereingang bis exposure anfang.
      Compensate_internal_delays_sgl = 0                    'Ausprobieren: extra delay caused by sync. use this to center the pulses around the exposure gap. Positive Werte schiebt es nach rechts.
   Elseif Camera_bits = 12 Then
      Dead_time_sgl = 96                                    'Messen: zeit die die kamera zwischen den belichtungen blind ist
      Delay_trigger_to_exposure_sgl = 32                    'Messen: Delay der Kamera von triggereingang bis exposure anfang.
      Compensate_internal_delays_sgl = 0                    'Ausprobieren: extra delay caused by sync. use this to center the pulses around the exposure gap. Positive Werte schiebt es nach rechts.
   End If

   Half_dead_time_sgl = Dead_time_sgl / 2



   Minimum_interframe_sgl = Dead_time_sgl + Delay_trigger_to_exposure_sgl       'this is the minimum allowed interframe time (respecting the dead time)
   Cam_on_sgl = Period_sgl - Dead_time_sgl                  ' 9995
   'wenn belichtung kuerzer soll, dann muss auch pulsabstand größer!
   Interframe_sgl = Interframe_us                           '500

     'jetzt erst aus ener_percent eine richtige pulslänge berechnen

   Pulselength_sgl = Ener_percent_single / 100
   Pulselength_sgl = Pulselength_sgl * Interframe_sgl



   ''(
   '____________________
   'pulselength und interframe:
   'pulselength muss kleiner sein als interframe minus (period-cam_on)

   Temp1_sgl = Period_sgl - Cam_on_sgl
   Temp1_sgl = Interframe_sgl - Temp1_sgl
   'Temp1_sgl = Temp1_sgl - Delay_trigger_to_exposure_sgl

   Temp1_sgl = Temp1_sgl + Compensate_internal_delays_sgl

   If Pulselength_sgl > Temp1_sgl Then
      Pulselength_sgl = Temp1_sgl
   End If


   Dutycycle = Pulselength_sgl * 1                          '*2
   Dutycycle = Dutycycle / Period_sgl

   'Print #1 , "pulselength: " ; Pulselength_sgl ; "period:" ; Period_sgl ; "duty:" ; Dutycycle
   'must not be more than 0.2.. falls doch --> pulselength reduzieren
   If Dutycycle > 0.5 Then

   'period ist periode in us
   '/10 ist 10% (*2) also 20%
   '/4 ist 25% (*2) also 50%
      'Pulselength_sgl = Period_sgl / 4                      '0.5*period/2 = pulselength
      Pulselength_sgl = Period_sgl / 2
   End If

'')
   '________________________________


   'update duty cycle calculation
   Dutycycle = Pulselength_sgl * 2
   Dutycycle = Dutycycle / Period_sgl
   Duty_cycle_ld = Dutycycle

   Duty_percent = Dutycycle * 100
   Duty_percent = Round(duty_percent)
   Duty_percent_integer = Duty_percent

   Temp1_sgl = Interframe_sgl / 2
   Temp2_sgl = Pulselength_sgl / 2

   Delay_pulse_1_sgl = Period_sgl - Temp1_sgl
   Delay_pulse_1_sgl = Delay_pulse_1_sgl - Temp2_sgl

   Delay_pulse_1_sgl = Delay_pulse_1_sgl - Half_dead_time_sgl
   Delay_pulse_1_sgl = Delay_pulse_1_sgl + Delay_trigger_to_exposure_sgl       'hiermit noch leichtes verschieben der laserpulse relativ zu exposure möglich. positive werte schieben die laserpulse nach hinten.
   Delay_pulse_1_sgl = Delay_pulse_1_sgl + Compensate_internal_delays_sgl

   Delay_pulse_2_sgl = Delay_pulse_1_sgl + Interframe_sgl

%}