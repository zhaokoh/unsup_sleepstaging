%% Preprocessing of polysomnographic data and generate time-series matrix for HCTSA
% Before submitting data for features extraction,
% 1. Read data in EDF format into matrix/cell array of 30-second epochs
% 2. Generate labels and keywords to identify time-series
% 3. Save data in the format suitable for HCTSA
% #########################################################################
%
whichData = WHICH_DATA;
edfname = strcat('ccshs-trec-1800',num2str(whichData,'%03d'),'.edf'); % 'ccshs-trec-1800001.edf'; 
edffile = strcat(DATA_DIR,edfname);
%% Specify case (How many channel?)
nChannel = NUM_CHANNELS; % Number of channels to be used:[1,2,3] 
% Read data and segment into specified length 
% 25-second epoch - For comparison with human performance)
% 5-second epoch - For detection substages
interval = 30; % unit: second
%% Load data using blockEdfLoad
% https://sleepdata.org/tools/dennisdean-block-edf-loader 
addpath(genpath(BLOCKEDFLOAD_DIR));
[header, signalHeader, signalCell] = blockEdfLoad(edffile);

%% Extract channel names, sampling frequency for different cases
switch (nChannel)
    case 1 %1 EEG re-ref channel
        channel = strcat(signalHeader(1).signal_labels,'-',signalHeader(4).signal_labels);
        fs = [signalHeader(1).samples_in_record, signalHeader(4).samples_in_record]; % Sampling rate of the C3 channel
        recordtime = header.num_data_records; % Total recording time (seconds)
        % Check if the bipolar re-reference pair is valid
        if fs(1)~=fs(2)
            error('Sampling frequency of the 2 channels must match');
        end
        %% Pre-processing
        % Bipolar re-reference C3-A2 (Channel derivation from CCSHS protocol)
        data = transpose(signalCell{1}-signalCell{4});
        
        % Segmentation
        timeSeriesData = read_edf_segment(data,fs,interval,nchannels);% Change function name
    
        % Number of epochs
        [n_ts,~] = size(timeSeriesData);
        %% Generate time segment name labels
        for t=1:n_ts
            name = sprintf('timeseg_%d',t);
            timelabel{t}=name;
        end
        [labels,keywords] = labelgen(n_ts,1,timelabel);
    case {2,3} %  3 channels (EEG,EOG,EMG)
        % Can include more pairs of channels**
        firstChanIndex = [1,5,13];
        secondChanIndex = [4,4,14];
        % Select channels
        for n=1:nChannel
            selectedSignal(n).raw = signalCell{firstChanIndex(n)}-signalCell{secondChanIndex(n)};
            selectedHeader(n).signal_labels = strcat(signalHeader(firstChanIndex(n)).signal_labels,'-',signalHeader(secondChanIndex(n)).signal_labels);
            % selectedHeader(n).signal_type = ;
            selectedHeader(n).sampling_rate = signalHeader(firstChanIndex(n)).samples_in_record;
        end
        % Downsample EMG channel
        selectedSignal(3).raw = downsample(selectedSignal().raw,2); % Downsampled by factor of 2
        selectedHeader(3).sampling_rate = selectedHeader(3).sampling_rate/2;
        % Segmentation
        for m = 1:nChannel
            selectedSignal(m).chopped = read_edf_segment(selectedSignal(m).raw',...
                selectedHeader(m).sampling_rate,interval,1);
            % Generate time labels
            [n_ts,~]  = size(selectedSignal(m).chopped);
            for t = 1:n_ts
                name = sprint('timeseg_%d',t);
                timelabel{t} = name;
            end
            
            % Combine 2/3 channels into single timeSeriesData matrix
            timeSeriesData(n_ts*(m-1)+1:n_ts*m,:) = selectedSignal(m).chopped;
            [labels(n_ts*(m-1)+1:n_ts*m),keywords(n_ts*(m-1)+1:n_ts*m)] = labelgen(n_ts,2,{selectedHeader(m).signal_labels},timelabel);            
        end
end
        
%% Save in HCTSA input format
hctsafile = strcat('TS_',edfname(1:length(edffile)-4),'_',num2str(nChannel),'chan');
save(hctsafile,'timeSeriesData','labels','keywords')

