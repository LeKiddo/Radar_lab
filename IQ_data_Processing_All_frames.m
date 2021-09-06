%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DESCRIPTION:
% Performs fft on raw I and Q radar data to compute the velocity and direction of travel of a target. 

% Processing is done for every frame which has a spectrum peak amplitude value higher than infineon's threshold.
% i.e only frames for which either a target is approaching or departing are processed. 
% This is done to make comparisons with Infineon's results easier as -
% Infineon's code doesn't send processing info for frames with signal energy below threshold. 
%ANS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clc
close all; 
clear all;

%% Loading saved workspace data
%load Workspaces/towards_128samples_workspace.mat
load Workspaces/away_128samples_workspace.mat

%% Boards details (outputted by extract_raw_data.m) 
disp('---------------------------------------------------------------------------')
disp('Boards details (outputted by extract_raw_data.m) see parameters variable in Workspace ') 
disp('---------------------------------------------------------------------------')

% rf_frequency_khz: 24050000 hz
% f0= 24.05e9 % operating frequency 
f0=23.976e9


% Signal's wavelength= Speed of light in vacuum/ operating frequency(f0)
%wavelength = physconst('LightSpeed')/f0
wavelength = 300000000/f0

% sampling_freq_hz: 2000 hz
Fe = 2000

%number_of_samples: 128 samples (default)
num_of_samples = num_of_samples


%% Defined constant
% Scaling factor for signal's power
IF_scale = 10; 
% Threshold to detect a motion with a defined direction 
motion_direction_threshold= 20 


%% Loop to process every frame
for frame_index=1:length(processed_data)
    
% only the frames which have a spectrum amplitude value higher than infineon's threshold are processed again 
% The following if condition (as well as it's corresponding END keyword)
% can be commented to use OUR defined threshold (motion_direction_threshold= 20)

  %% Retrieving the raw I & Q data outputted by extract_raw_data.m 
  if(processed_data(frame_index).velocity_mps ~= 0) 
    
    % I and Q data of the frame to process
      I=real(IQ_rawdata(frame_index).sample_data(:,1))*IF_scale;  %I raw data with a scaling factor of 10
      Q= imag(IQ_rawdata(frame_index).sample_data(:,1))*IF_scale; %Q raw data with a scaling factor of 10
    % Complex signal = I + jQ 
      signal=IQ_rawdata(frame_index).sample_data(:,1)*IF_scale;   % complex signal with *10 scaling factor


    %% Prerequisites for FFT processing 

    % 1- Chebychev window
    % a Chebyshev window is applied to attenuate the sidelobs and make sure that the data is limited.
    
    window = chebwin(num_of_samples,60); % Chebychev window with 60 dB relative sidelobe attenuation instead of 100db default attenuation


    % 2- removal of the signal's DC component before windowing 

    %Computation of mean values for the removal of the signal's DC component 
    I_mean=mean(I);
    Q_mean=mean(Q);
    S_mean=mean(signal);

    % removal of the signal's DC component and windowing 
    I_prefft=((I- I_mean) .* window );
    Q_prefft=((Q- Q_mean) .* window);
    S_prefft=((signal-S_mean) .* window); %length of S_prefft = length of signal =128 


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

    % frequency bins vector for the FFT signal. 
    % All possible doppler bins for a sampling frequency of Fe=2khz & 256 FFT size
    
    % f= 127, 126... 2, 1  0 0  -1, 2 ... -126, -127 
    %[ 127 bins for positive frequencies (appraoching target) and 127 bins for negative
    % frequencies (departing target) 
    
    frequency_resolution= Fe/FFT_size;
    f=[( (FFT_size/2)-1 : -1 : 0)  ( 0  :-1: - ((FFT_size/2)-1) )]* frequency_resolution;

    %% Finding the peak in the Frequency domain to determine the doppler frequency 

    %Finding the peak of the complex signal's FFT spectrum  
    [peaks_values,frequency_shifts] = findpeaks(abs(Sfft));

    [peak_value,peak_Bin] = maxk(peaks_values,1); % Only the maximum value is interesting as the doppler frequency lies at the frequency for which the amplitude is the highest 

    maxBin= frequency_shifts(peak_Bin) %maxBin is the bin index of the highest peak 

    
    %% Corresponding doppler frequency for the bin index (maxBin) 
    doppler_frequency =f(maxBin); 
    
    
    %% Velocity of the target
    % remark we divide the velocity by 2 since it's a two way propagation
    % (from radar to target and from target back to radar's Rx antennas)
    velocity= (doppler_frequency * wavelength)/2;
 
    
    %% Determination of the direction of motion 
    
    % Target's direction code
    % -1 -> departing target 
    %  1 -> approaching target
    %  0 -> either no motion or no clear direction for the motion
    target_direction= 0 % initialization
    
    
    % The peak at the doppler frequency has to be higher than a defined
    % threshold for it to be considered as a motion with a known direction
    motion_direction_threshold= 20 

    %% Using the doppler frequency's sign to determine motion direction

    if peak_value > motion_direction_threshold  
        
        if doppler_frequency  < 0 
            disp('Target is departing')
            target_direction= -1 ;

        elseif doppler_frequency  > 0 
            disp('Target is approaching')
            target_direction= 1 ;
        end 

    else
          target_direction= 0 ;

    end

    %% Adding the processing results to the processed_data data structure for comparison with Infineon's results 
    processed_data(frame_index).Matlab_dopplerFreq = doppler_frequency;
    processed_data(frame_index).Matlab_velocity= velocity;
    processed_data(frame_index).Matlab_targetDirection = target_direction;


    
    %% Visualisation of I and Q data and spectrum of complex I + jQ signal
    if(target_direction ~= 0) % only create figure for visualization when there is a target approaching or departing

     figure(1)

        % I and Q wave forms visualization
        subplot(2,1,1)
        t= 1:length(I); % time vector 
        plot(t, I); hold on;
        plot(t,Q); hold off; 
        xlim([1,num_of_samples+5]);
        xlabel(['Samples (out of ',num2str(num_of_samples),')']);
        ylabel('I and Q wave forms ');
        legend("I", "Q") ;
        title('I and Q waveforms') 

        % FFT of I + Qj (signal)
        subplot(2,1,2)
        plot(f, abs(Sfft), doppler_frequency ,peak_value,'pg')
        grid
        xlabel('f');
        ylabel('fft signal ');
        title('FFT of the complex radar signal (I +jQ) with its max peak ')

        if target_direction == -1  
            info = sprintf('Target is departing \n(Vr=%0.3f m/s)',velocity);
        else
            info = sprintf('Target is approaching \n(Vr=%0.3f m/s)',velocity);
        end

        legend(info)
        
    end
    
 
 end
end


%%clearing the workspace off 'useless' variables
clearvars -except IQ_rawdata processed_data num_of_samples parameters f FFT_size wavelenght f0 Fe