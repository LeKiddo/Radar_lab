%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DESCRIPTION:
% Performs fft on raw I and Q radar data to compute the velocity of a target. 

% Processing is done for every frame which have a spectrum amplitude value higher than infineon's threshold are processed again
% i.e the frames for which either a target is approaching or departing
%(all the other frames are not processed by infineon so no comparison is possible)     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
close all; 
clear all;

%% saved workspace data
%load towards_128samples_workspace.mat
load away_128samples_workspace.mat

%% Boards details (outputted by extract_raw_data.m) 
disp('---------------------------------------------------------------------------')
disp('Boards details (outputted by extract_raw_data.m) see param2 variable in Workspace ') 
disp('---------------------------------------------------------------------------')

%  rf_frequency_khz: 24050000 
%f0= 24.05e9 % operating frequency 
f0=23.978e9

% signal's wavelength= Speed of light (299792458) / operating frequency(f0)
%wavelength = physconst('LightSpeed')/f0
wavelength = 300000000/f0

% sampling_freq_hz: 2000
Fe=2000

%number_of_samples: 128
num_of_samples=num_of_samples


%% other constants 
% Scaling factor for signal's power
IF_scale = 10; 



%% Retrieving the raw I & Q data outputted by extract_raw_data.m 

% Chose the frame to process by referencing its index number
frame_index=21;                                              % The field index of the frame that we want to process (see fields # of the wanted frame off processed_data variable )


%To process every frame, uncomment the following 2 lines as well as the corresponding delimitimers  (end)
%for frame_index=1:length(processed_data)
%if(processed_data(frame_index).velocity_mps ~= 0)  % only the frames which have a spectrum amplitude value  higher than infineon's threshold are processed again     
   

% I and Q values of the frame to process
I=real(IQ_rawdata(frame_index).sample_data(:,1))*IF_scale;  %I raw data with a scaling factor of 10
Q= imag(IQ_rawdata(frame_index).sample_data(:,1))*IF_scale;  %Q raw data with a scaling factor of 10
%Raw complex signal = I + jQ 
signal=IQ_rawdata(frame_index).sample_data(:,1)*IF_scale;   % with *10 scaling factor


%% visualization of I and Q data
t= 1:length(I); % Form time vector 

figure(1)
plot(t, I); hold on;
plot(t,Q); hold off; 

xlim([1,num_of_samples+5]);
xlabel(['Samples (out of ',num2str(num_of_samples),')']);
ylabel('I and Q wave forms ');
legend("I", "Q") ;
title('I and Q waveforms') 

