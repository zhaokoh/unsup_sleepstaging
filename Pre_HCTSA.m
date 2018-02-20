%% Preprocessing of polysomnographic data and generate time-series matrix for HCTSA
homedir = pwd;
edffile = 'ccshs-trec-1800001.edf'; 
datadir = '/Volumes/Seagate Expansion Drive/ccshs/polysomnography/edfs/';
edf_data = strcat(datadir,edffile); 
%load(edf_data)
cd(homedir)
%% Load data using blockEdfLoad
% https://sleepdata.org/tools/dennisdean-block-edf-loader
addpath(genpath('C:\Users\Piengkwan\Documents\MATLAB\unsup_sleep_staging\blockEdfLoad'));
[header, signalHeader, signalCell] = blockEdfLoad(edf_data);

%% Extract channel names, sampling frequency for 1 EEG re-ref channel
% channel = strcat(signalHeader(1).signal_labels,'-',signalHeader(4).signal_labels);
% fs = [signalHeader(1).samples_in_record, signalHeader(4).samples_in_record]; % Sampling rate of the C3 channel
% recordtime = header.num_data_records; % Total recording time (seconds)
% nchannels = 1; % Only 1 EEG channel
% % Check if the bipolar re-reference pair is valid
% if fs(1)~=fs(2)
%     valid = 0;
% else
%     valid = 1;
%     fs = fs(1);
% end
%% Extract channel names, sampling frequency for 1 EEG, 1 EOG, 1 EMG
selectedSignal(1).raw = signalCell{1}-signalCell{4};
selectedHeader(1).signal_labels = 'C3-A2';
selectedHeader(1).signal_type = 'EEG';
selectedHeader(1).sampling_rate = signalHeader(1).samples_in_record;

% selectedSignal{2} = signalCell{2}-signalCell{3};
% selectedHeader(2).signal_labels = 'C4-A1';
% selectedHeader(2).signal_type = 'EEG';
% selectedHeader(2).sampling_rate = signalHeader(2).samples_in_record;
% 
selectedSignal(2).raw = signalCell{5}-signalCell{4};
selectedHeader(2).signal_labels = 'LOC-A2';
selectedHeader(2).signal_type = 'EOG';
selectedHeader(2).sampling_rate = signalHeader(5).samples_in_record;
%  
% selectedSignal{4} = signalCell{6}-signalCell{3};
% selectedHeader(4).signal_labels = 'ROC-A1';
% selectedHeader(4).signal_type = 'EOG';
% selectedHeader(4).sampling_rate = signalHeader(6).samples_in_record;
%  
selectedSignal(3).raw = signalCell{13}-signalCell{14};
selectedHeader(3).signal_labels = 'EMG1-EMG2';
selectedHeader(3).signal_type = 'EMG';
selectedHeader(3).sampling_rate = signalHeader(13).samples_in_record;
%% For single channel EEG
%% (Additional part)Pre-processing
% % Bipolar re-reference C3-A2 (Channel derivation from CCSHS protocol)
% data = transpose(signalCell{1}-signalCell{4});
% %% Read data and segment into specified length 
% % 25-second epoch - For comparison with human performance)
% % 5-second epoch - For detection substages
% interval = 30;
% timeSeriesData = read_edf_segment(data,fs,interval,nchannels);% Change function name
% 
% % Number of time segment/epoch
% n_seg = recordtime; % Record time (second)
% [n_ts,~] = size(timeSeriesData);
% %% Time segment name
% for i=1:n_ts
%     name = sprintf('timeseg_%d',i)
%     timelabel{i}=name;
% end
% %%
% [labels,keywords] = labelgen(n_ts,1,timelabel);
% 
% %% Save in HCTSA input format
% hctsafile = sprintf(['TS_',edffile(1:length(edffile)-4)]);
% % mkdir 041017_KJ_N2
% % cd ./041017_KJ_N2
% save(hctsafile,'timeSeriesData','labels','keywords')
%% End - uncomment above section for single channel
%% For 3 channels EEG -> 
% Sampling rate is not the same for all channel
% Perform read_edf_segment() for each channel separately

%% Downsample EMG channel
selectedSignal(3).raw = downsample(selectedSignal(3).raw,2);
selectedHeader(3).sampling_rate = selectedHeader(3).sampling_rate/2; 
%% Segmentation
interval = 30;
for i = 1:length(selectedSignal)
    selectedSignal(i).chopped = read_edf_segment(selectedSignal(i).raw',...
                                selectedHeader(i).sampling_rate,interval,1);
    % Generate time label
    [n_ts,~] = size(selectedSignal(i).chopped);
    for t = 1:n_ts
        name = sprintf('timeseg_%d',t);
        timelabel{t} = name;
    end
    
    % Combine 3 channel into single matrix
    timeSeriesData(n_ts*(i-1)+1:n_ts*i,:) = selectedSignal(i).chopped;
    [labels(n_ts*(i-1)+1:n_ts*i),keywords(n_ts*(i-1)+1:n_ts*i)] = labelgen(n_ts,2,{selectedHeader(i).signal_labels},timelabel);
end
 %% Save HCTSA
 hctsafile = strcat('TS_',edffile(1:length(edffile)-4));
 save(hctsafile,'timeSeriesData','labels','keywords')
 

    
