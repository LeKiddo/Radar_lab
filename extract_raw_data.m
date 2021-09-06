%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function out = extract_raw_data (in)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 

% Copyright (c) 2014-2020, Infineon Technologies AG
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without modification,are permitted provided that the
% following conditions are met:
%
% Redistributions of source code must retain the above copyright notice, this list of conditions and the following
% disclaimer.
%
% Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
% disclaimer in the documentation and/or other materials provided with the distribution.
%
% Neither the name of the copyright holders nor the names of its contributors may be used to endorse or promote
% products derived from this software without specific prior written permission.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
% INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
% DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE  FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
% SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
% WHETHER IN CONTRACT, STRICT LIABILITY,OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
% OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DESCRIPTION:
% This simple example demos the acquisition of data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 

%% Cleanup and init
% Before starting any kind of device the workspace must be cleared and the
% MATLAB Interface must be included into the code. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

 

clc;
clear all;
close all;

 

disp('******************************************************************');
addpath('..\..\RadarSystemImplementation'); % add Matlab API
resetRS; % close and delete ports
% 1. Create radar system object
szPort = findRSPort; % find the right COM Port
oRS = RadarSystem(szPort); % creates the Radarsystem API object

 

disp('Connected RadarSystem:');
oRS %#ok<*NOPTS>

 

% 2. Customize radar parameters
%%% Display device information
oRS.oEPRadarTJBA.major_version
oRS.oEPRadarTJBA.minor_version
oRS.oEPRadarTJBA.rf_shield_type_id
oRS.oEPRadarTJBA.description

 

oRS.oEPRadarTJBA.consumption_def
oRS.oEPRadarTJBA.consumption

 

oRS.oEPRadarTJBA.reset_parameters

 

oRS.oEPRadarTJPU.get_parameters_def
oRS.oEPRadarTJPU.get_shield_info

 

%%% Get and display default parameters
param1 = oRS.oEPRadarTJPU.get_parameters;
param1

%num_of_samples=256 %% original value
num_of_samples=128
%%% Change parameters in memory
oRS.oEPRadarTJPU.parameters.frame_time_sec = 0.1500;
oRS.oEPRadarTJPU.parameters.number_of_samples = num_of_samples;
oRS.oEPRadarTJPU.parameters.min_speed_mps = 0.3;

 

%%% Send parameters to device
oRS.oEPRadarTJPU.apply_parameters;

 

%%% Get and display used parameters
parameters = oRS.oEPRadarTJPU.get_parameters;
parameters 

 

% 3. Get exemplary data set
oRS.oEPRadarTJPU.get_result_data

 

oRS.oEPRadarTJPU.get_raw_data

 

oRS.oEPRadarTJBA.get_consumption

 

% 4. Collect data
disp('Start data acquisition...');
i = 0;
hFig = figure;
while ishandle(hFig)
    drawnow;
    i = i + 1;
    fprintf('.');
    [processed_data(i), IQ_rawdata(i)] = oRS.oEPRadarTJPU.get_result_and_raw_data;
end
fprintf('\n');

 

% 5. Plot velocity of collected data
figure;
plot([processed_data.velocity_mps]);
xlim([1,i]);
title('Raw Data');
xlabel('Frame');
ylabel('Velocity (m/s)');

 

% 6. Clear radar system object
disp('Clear radar object...');
clearSP;
disp('Done!');



%User's code 

%% removing unecessary fields from the IQ_rawdata and processed_data fields
fields_to_remove_IQ = {'num_chirps','num_rx_antennas','rx_mask','interleaved_rx'};
IQ_rawdata= rmfield(IQ_rawdata,fields_to_remove_IQ);

[processed_data.frame_number] = deal(processed_data.frame_count) 
fields_to_remove_processedData = {'result_cnt','frame_count'};
processed_data =rmfield(processed_data,fields_to_remove_processedData);


% re-ordering the remaining fields
processed_data = orderfields(processed_data,[7,5,3,4,2,6,1]);
%% clearing " useless " variables from the workspace except for those explicitly mentionned
clearvars -except IQ_rawdata processed_data num_of_samples parameters
