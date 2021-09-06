%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function out = PlotDemo (in)
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
% This simple example demos the usage of the Matlab Sensing Interface by 
% configuring the chip and acquiring and plotting raw data.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Cleanup and init
% Before starting any kind of device the workspace must be cleared and the
% Matlab Interface must be included into the code. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;
clear;
close all;

disp('******************************************************************');
addpath('..\..\RadarSystemImplementation'); % add Matlab API
%resetRS; % close and delete ports

% 1. Create radar system object
szPort = findRSPort; % find the right COM Port
oRS = RadarSystem(szPort); % creates the Radarsystem API object

% 2. Set radar parameters
NTS = 128;
oRS.oEPRadarTJPU.parameters.number_of_samples = NTS;

% 3. Get and plot raw data
disp('Plot raw data...');
hFig = figure;

% User's code
velocity=zeros(10000,1)
Doppler_frequency_hz=zeros(10000,1)
level=zeros(10000,1)
departing=zeros(10000,1)
approaching=zeros(10000,1)
xlimit=128;
% / User's code
i = 0;

while ishandle(hFig)
    i=i+1
    res = oRS.oEPRadarTJPU.get_result_data;
    velocity(i)= res.velocity_mps
    Doppler_frequency_hz(i)=res.doppler_frequency_hz
    level(i)=res.level %The level of the maximum in the sprectrum, where the velocity is calculated from
    departing(i)=res.is_target_departing
    approaching(i)=res.is_target_approaching
    if i< (xlimit)
    
    subplot(3,1,1)
    plot(velocity);
    xlim([1,xlimit]);
    xlabel('Frame');
    ylabel('Radial velocity (m/s)');
    
    subplot(3,1,2)
    plot(Doppler_frequency_hz);
    xlim([1,xlimit]);
    xlabel('Frame');
    ylabel('doppler freq (hz) '); %The Doppler frequency of the maximum in the spectrum (in Hz)
    
    subplot(3,1,3)
    plot(departing);
    hold on 
    plot(approaching);
    hold off
    xlim([1,xlimit]);
    xlabel('Frame');
    ylabel('Departing/ approaching ');
    legend('Departing','approching');

    end
    drawnow;
end

% 4. Clear radar system object
disp('Clear radar object...');
clearSP;
disp('Done!');

