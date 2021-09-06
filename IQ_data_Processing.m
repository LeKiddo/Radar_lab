%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DESCRIPTION:
% Performs fft on raw I and Q radar data to compute the velocity the velocity and direction of travel of a target.      
% ANS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
close all; 
clear all;

%% Loading saved workspace data
load Workspaces/towards_128samples_workspace.mat
%load Workspaces/away_128samples_workspace.mat

%% Boards details (outputted by extract_raw_data.m) 
disp('---------------------------------------------------------------------------')
disp('Boards details (outputted by extract_raw_data.m) see param2 variable in Workspace ') 
disp('---------------------------------------------------------------------------')

%  rf_frequency_khz: 24050000 hz
%f0= 24.05e9 % operating frequency 
f0=23.976e9

% signal's wavelength= Speed of light in vacuum / operating frequency(f0)
%wavelength = physconst('LightSpeed')/f0 meters
wavelength = 300000000/f0

% sampling_freq_hz: 2000 hz
Fe=2000

%number_of_samples: 128 samples
num_of_samples=num_of_samples


%% Defined constants
% Scaling factor for signal's power
IF_scale = 10; 
%threshold to detect a motion with a defined direction 
motion_direction_threshold= 20 ;



%% Retrieving the raw I & Q data outputted by extract_raw_data.m 

% The field index of the frame to process (see fields # of the wanted frame off the processed_data variable )
frame_index=  21  


% I and Q data of the frame to process
I=real(IQ_rawdata(frame_index).sample_data(:,1))*IF_scale; %I raw data with a scaling factor of 10
Q= imag(IQ_rawdata(frame_index).sample_data(:,1))*IF_scale; %Q raw data with a scaling factor of 10

% Complex signal = I + jQ 
signal=IQ_rawdata(frame_index).sample_data(:,1)*IF_scale; % with *10 scaling factor


%% visualization of I and Q data
t= 1:length(I); % Time vector 

figure(1)
plot(t, I); hold on;
plot(t,Q); hold off; 

xlim([1,num_of_samples+5]);
xlabel(['Samples (out of ',num2str(num_of_samples),')']);
ylabel('I and Q wave forms ');
legend("I", "Q") ;
title('I and Q waveforms') 


%% FFT processing of the raw signal 

%% Prerequisites for FFT processing 

% 1- Chebychev window
%a Chebyshev window is applied to attenuate the sidelobs and make sure that the data is limited.
    
window = chebwin(num_of_samples,60); % Chebychev window with 60 dB relative sidelobe attenuation instead of 100db default attenuation
% Showcase FFT of the signal I+jQ
N=length(signal); % 128 (default)
Sfft=fftshift(fft(signal.*window));  %% FFT
f= Fe*((N/2): -1 : -((N/2)-1))/N;    % frequency vector for the FFT signal

% visualization of the I+jQ FFT signal's (Sfft) magnitude
figure(2)
plot(f,abs(Sfft))
ylabel('Spectrum of the complex I+jQ signal ');
xlabel('frequencies ');
title('showcase FFT of the complex I+jQ signal') 

% Note: There is a DC component at the central frequency which corresponds to the velocity 0m/s 

%windowed FFT of a signal with DC offset will produce the shape of the FFT of the window function around DC offset bins,
%which in turn can mask the interested signals at those bins. We therefore
%have to remove the DC component before performing FFT


% 2- removal of the signal's DC component before windowing 

%Computation of mean values for the removal of the signal's DC component 
I_mean=mean(I);
Q_mean=mean(Q);
S_mean=mean(signal);


% removal of the signal's DC component before windowing 

I_prefft=((I- I_mean) .* window );
Q_prefft=((Q- Q_mean) .* window);
S_prefft=((signal-S_mean) .* window); %length of S_prefft= length of signal =128 


% The windowed data is zero-padded to have a length of 256 (instead of 128) in order to enhance the received signal characteristics.
% we add zeros so that the total number of samples is equal to the next
% higher power of two after 128
% Note: 256 is also the infineon radar's maximum number of samples 

% 3- Zero padding the data to 256 points or samples
FFT_size=256; 

if(num_of_samples < FFT_size) 
    I_prefft((num_of_samples+1):FFT_size)=0;
    Q_prefft((num_of_samples+1):FFT_size)=0;
    S_prefft((num_of_samples+1):FFT_size)=0;
end

%% FFT processing of the windowed and zero-padded raw signal 

Ifft= fftshift(fft(I_prefft,FFT_size)); 
Qfft= fftshift(fft(Q_prefft,FFT_size)); 
Sfft= fftshift(fft(S_prefft,FFT_size)); 

% Frequency bins vector for the FFT signal. 
% All possible frequency bin numbers for a sampling frequency of Fe=2khz & 256 FFT size
    
% f= 127, 126... 2, 1  0 0  -1, 2 ... -126, -127 
%[ 127 bins for positive frequencies (appraoching target) and 127 bins for negative frequencies (departing target) 
   
frequency_resolution= Fe/FFT_size;
f=[( (FFT_size/2)-1 : -1 : 0)  ( 0  :-1: - ((FFT_size/2)-1) )]* frequency_resolution;

% Visualization of FFT of the windowed and zero-padded raw signals

figure(3)
subplot(3,1,1)
plot(f, abs(Ifft))
xlabel('f');
ylabel('fft I ');
grid
title('Visualization of fft spectrum for I data ')

subplot(3,1,2)
plot(f, abs(Qfft))
xlabel('f');
ylabel('fft q ');
grid
title('Visualization of fft spectrum for Q data ')

subplot(3,1,3)
plot(f, abs(Sfft))
xlabel('f');
ylabel('fft signal ');
grid
title('Visualization of fft spectrum for complex I+Qj data ')


% Visualization of the FFT spectrum in dB 
figure(4)
subplot(3,1,1)
plot(f,mag2db(abs(Ifft)));
xlabel('Frequency (in hertz)');
ylabel('Ifft Amplitude in dB');

subplot(3,1,2)

plot(f,mag2db(abs(Qfft)));
xlabel('Frequency (in hertz)');
ylabel('Qfft Amplitude in dB');

subplot(3,1,3)
plot(f,mag2db(abs(Sfft)));
xlabel('Frequency (in hertz)');
ylabel('Sfft Amplitude in dB');


%% Finding the peak in the Frequency domain to determine the doppler frequency 

%Finding the peak of the complex signal's FFT spectrum  
[peaks_values,frequency_shifts] = findpeaks(abs(Sfft));

[peak_value,peak_Bin] = maxk(peaks_values,1); % Only the maximum value is interesting as the doppler frequency lies at the frequency for which the amplitude is the highest 

maxBin= frequency_shifts(peak_Bin) %maxBin is the bin index of the highest peak 

    
%% Corresponding doppler frequency for the bin index (maxBin) 
doppler_frequency =f(maxBin); 
disp('Doppler frequency = ')
disp(doppler_frequency)
    
%% Velocity of the target
% remark we divide the velocity by 2 since it's a two way propagation
% (from radar to target and from target back to radar's Rx antennas)
disp(' Velocity of the target')
velocity= (doppler_frequency * wavelength)/2;
disp(velocity)  

%% Determination of the direction of motion 
    
% Target's direction code
% -1 -> departing target 
%  1 -> approaching target
%  0 -> either no motion or no clear direction for the motion

% initialization
target_direction=0;


% The peak at the doppler frequency has to be higher than a defined 
% for it to be considered as a motion with a known direction
motion_direction_threshold= 20 ;


%% Using doppler frequency's sign to determine motion direction

if peak_value > motion_direction_threshold
    if doppler_frequency  < 0       % ( maxBin > num_of_samples(128) )
        disp('Target is departing')
        target_direction = -1 ;
         
    elseif doppler_frequency > 0    % ( maxBin < num_of_samples(128) ) 
        disp('Target is approaching')
        target_direction = 1 ;
    end 
    
else
      target_direction = 0 ;

end


% Recap
if(target_direction ~= 0) % only create figure for visualization when there is a target approaching or departing

    figure(5)
    plot(f, abs(Sfft), doppler_frequency ,peak_value,'pg')
    grid
    xlabel('f');
    ylabel('fft signal ');
    title('FFT of the complex radar signal (I +jQ) with its max peak ')

    if target_direction == -1  
        info = sprintf('peak value = %.3f , doppler frequency = %0.3f.\nTarget is departing (Vr=%0.3f m/s)',peak_value,doppler_frequency ,velocity);
    else
        info = sprintf('peak value = %.3f , doppler frequency = %0.3f.\nTarget is approaching (Vr=%0.3f m/s)',peak_value,doppler_frequency ,velocity);
    end

    legend(info)

% writing some variables into an excel sheet 
reminder='Do not forget to close the excel file before running the program again'
save('variables.mat','info','maxBin','f');excel_writing;
end




%%clearing the workspace off 'useless' variables
clearvars -except ftest IQ_rawdata processed_data num_of_samples param2 f doppler_frequency  FFT_size frame_index maxBin peak_value signal Sfft velocity wavelenght target_direction target_direction_v2 maxBin_approach maxBin_approach_v2 possible_freq_bins % I Q Ifft Qfft Sfft % f0 Fe window frequency_shifts

