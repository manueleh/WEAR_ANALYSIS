%% Step 1: Clear workspace and load EEG dataset
clear all;
close all;
eeglab; % Start EEGLAB

% Step 1: Load files
s.subj_data_path = '/home/maxinehe/Downloads/EEG clean data/WEAR p71'; % replace with your directory where you saved EEG data
fname = 'WEAR_p71_tsst_interview'; % 
subj = 'WEAR_p71'; % 
s.elocs_file = ['/home/maxinehe/Downloads/MFPRL_UPDATED_V2.sfp'];
EEG = pop_loadset('/home/maxinehe/Downloads/TSST/p71/WEAR_day1_p71_synced_trier_social_stress_interview.set', [], [1:64]);
ALLEEG = [];
EEG.subject = subj;
[ALLEEG, EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',fname,'gui','off'); 
eeglab redraw
%% Step 2: Load channel locations
EEG = pop_chanedit(EEG,'changefield',{1 'labels' 'Fp1'},'changefield',{2 'labels' 'Fz'},...
        'changefield',{3 'labels' 'F3'},'changefield',{4 'labels' 'F7'},...
        'changefield',{5 'labels' 'LHEye'},'changefield',{6 'labels' 'FC5'},...
        'changefield',{7 'labels' 'FC1'},'changefield',{8 'labels' 'C3'},...
        'changefield',{9 'labels' 'T7'},'changefield',{10 'labels' 'GND'},... % GND is switched with FPz
        'changefield',{11 'labels' 'CP5'},'changefield',{12 'labels' 'CP1'},...                
        'changefield',{13 'labels' 'Pz'},'changefield',{14 'labels' 'P3'},...
        'changefield',{15 'labels' 'P7'},'changefield',{16 'labels' 'O1'},...
        'changefield',{17 'labels' 'Oz'},'changefield',{18 'labels' 'O2'},...
        'changefield',{19 'labels' 'P4'},'changefield',{20 'labels' 'P8'},...
        'changefield',{21 'labels' 'Rmastoid'},'changefield',{22 'labels' 'CP6'},...
        'changefield',{23 'labels' 'CP2'},'changefield',{24 'labels' 'Cz'},...
        'changefield',{25 'labels' 'C4'},'changefield',{26 'labels' 'T8'},...
        'changefield',{27 'labels' 'RHEye'},'changefield',{28 'labels' 'FC6'},...
        'changefield',{29 'labels' 'FC2'},'changefield',{30 'labels' 'F4'},...
        'changefield',{31 'labels' 'F8'},'changefield',{32 'labels' 'Fp2'},...
        'changefield',{33 'labels' 'AF7'},'changefield',{34 'labels' 'AF3'},...
        'changefield',{35 'labels' 'AFz'},'changefield',{36 'labels' 'F1'},...
        'changefield',{37 'labels' 'F5'},'changefield',{38 'labels' 'FT7'},...
        'changefield',{39 'labels' 'FC3'},'changefield',{40 'labels' 'FCz'},...
        'changefield',{41 'labels' 'C1'},'changefield',{42 'labels' 'C5'},...
        'changefield',{43 'labels' 'TP7'},'changefield',{44 'labels' 'CP3'},...
        'changefield',{45 'labels' 'P1'},'changefield',{46 'labels' 'P5'},...
        'changefield',{47 'labels' 'Lneck'},'changefield',{48 'labels' 'PO3'},...
        'changefield',{49 'labels' 'POz'},'changefield',{50 'labels' 'PO4'},...
        'changefield',{51 'labels' 'Rneck'},'changefield',{52 'labels' 'P6'},...
        'changefield',{53 'labels' 'P2'},'changefield',{54 'labels' 'CPz'},...
        'changefield',{55 'labels' 'CP4'},'changefield',{56 'labels' 'TP8'},...
        'changefield',{57 'labels' 'C6'},'changefield',{58 'labels' 'C2'},...
        'changefield',{59 'labels' 'FC4'},'changefield',{60 'labels' 'FT8'},...
        'changefield',{61 'labels' 'F6'},'changefield',{62 'labels' 'F2'},...
        'changefield',{63 'labels' 'AF4'}, 'changefield',{64 'labels' 'RVEye'});
    % Changing channel location structure in EEG dataset using the file <MFPRL_default.sfp>
EEG = pop_chanedit(EEG, 'lookup', s.elocs_file);
chanlocs = EEG.chanlocs;
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); %Storing
%% Step 3: high-pass filter (>1Hz) and check the data rank
EEG = pop_eegfiltnew(EEG, 1, []);  % High-pass filter above 1Hz
sum(eig(cov(double(EEG.data'))) > 1E-7)==EEG.nbchan % check if the data is full ranked
EEG.oldevent = EEG.event;
EEG.event = [];
%% Step 4: Use ASR and cleanline to remove noise
EEG = pop_clean_rawdata(EEG, 'FlatlineCriterion',5,'ChannelCriterion',0.8, ...
    'LineNoiseCriterion',4,'Highpass','off','BurstCriterion',20, ...
    'WindowCriterion','off','BurstRejection','off','Distance','Euclidian', ...
    'channels_ignore',{'GND','Rmastoid','Lneck','Rneck'}, ...
    'WindowCriterionTolerances',[-Inf 7] );
EEG = pop_eegfilt(EEG,0,55,[],0,0,0,'fir1',0); %then low-past
EEG = pop_cleanline(EEG, 'bandwidth',2 ,'computepower',1,'linefreqs',60, ...
        'normSpectrum',0,'p',0.01,'pad',2,'plotfigures',0,'scanforlines',1, ...
        'sigtype','Channels','tau',100,'verb',1,'winsize',1,'winstep',1);
EEG = eeg_checkset(EEG); %Checking consistency
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); %Storing
eeglab redraw
%% Step 5: Rereference to average
EEG = pop_reref(EEG,[],'interpchan',[]);
%% Step 6: Run CUDA ICA
name = [subj 'tsst_interview_runica'];
EEG = pop_runica(EEG, 'extended',1, 'icatype', 'cudaica', 'verbose', 'matlab', 'concatcond','on','options',{'pca',-1});
pop_saveset(EEG); % --> save the dataset as WEAR_day1_p#_condition_runica.set;

% Plotting the independent components
pop_topoplot(EEG,0, 1:size(EEG.icawinv,2) ,name,[3 10] ,0,'electrodes','on');

IClocations = '/home/maxinehe/Downloads/EEG clean data/WEAR p71';
%IClocations= [s.subj_data_path '/' subj 'IC_Photos_tsst_interview'];
for i = size(EEG.icawinv,2):-1:1
    pop_prop( EEG, 0, i, NaN, {'freqrange' [2 65],'electrodes','on' });
    set(gcf, 'Position', [48 480 500 500]);
    IC = sprintf('WEAR_day1_p71_tsst_interview_IC #%d', i);
    saveas(gcf,fullfile(IClocations,IC),'png')
end
%close;
close all
fullfile(IClocations,'rejected.mat');

%% Step 7: ICLabel for component classification:
%s.elocs_file = ['/home/maxinehe/Downloads/MFPRL_UPDATED_V2.sfp']; % -->change the path here to run components classification
% Manual Selection of good Independent Components
%by eyeballing: (1) topographies, and (2) component specs
%good   = [7,8,11,13,16,29,51];                
%eyes   = [];

% ICLabel to classify components (brain, muscle, eye, etc.)
EEG = pop_iclabel(EEG, 'default');
pop_viewprops(EEG,0);
% Use threshold to retain brain components only
EEG = pop_icflag(EEG, [0 0.8;1 1;1 1;1 1;1 1;1 1;1 1]);  % Keep only brain components (ICLabel >= 80%)
%% Step 8: Reject bad components and retain good components
rejected_comps = find(EEG.reject.gcompreject > 0);
%Incorporating good and bad componenets inside EEG data 
EEG.good = setdiff(1:length(EEG.icawinv),rejected_comps);  
EEG.bad  = rejected_comps;
eye_comps = find(EEG.reject.gcompreject > 0);
EEG.eyes = eye_comps;
%%
EEG.good = [12, 16, 23, 24, 27, 35];
EEG.bad = setdiff(1:length(EEG.icawinv), EEG.good);
%EEG.bad = setdiff(rejected_comps, EEG.good);
rejected_comps = EEG.bad;
%%
%plot the good components-this step save good ICs figures in working
%directory
name = [subj 'tsst_interview_backproject'];
pop_topoplot(EEG, 0, EEG.good ,sprintf('%s good ICs %s', name, date),[3 8] ,0,'electrodes','on');
print(1, '-dpng', fullfile(IClocations, [name '_all_ic'])); % Prints Figure

%% Step 9: Export ICA data
icaact = EEG.icaact;
icawinv = EEG.icawinv;
icasphere = EEG.icasphere;
icaweights = EEG.icaweights;
icachansind = EEG.icachansind;
good = EEG.good;
bad = EEG.bad;
eyes = EEG.eyes;
pathname= [s.subj_data_path, '/' name , '_IC.mat' ];

save(pathname,'icaact','icawinv','icasphere','icaweights','icachansind','good','eyes','bad');

%% Step 10: Backproject
EEG = pop_subcomp(EEG, rejected_comps);
%pop_saveset(EEG); 
%% Step 11: Interpolate bad channels after ASR

EEG = pop_interp(EEG, chanlocs, 'spherical');
EEG = eeg_checkset(EEG);
pop_saveset(EEG);
%% Step 12: Epoch and bad epoch rejection

epoch_no = floor(EEG.pnts/EEG.srate); %Latency rate/Sampling rate
eventRecAll = [];

% Looping through EC trials
for event_i = 1:(epoch_no-1)
    eventRecTemp = [1 event_i-1 (event_i-1)*500];
    %eventRecTemp = [2 event_i-1 (event_i-1)*500];
    eventRecAll = [eventRecAll; eventRecTemp]; %Matrix with 3 columns, all 1s, Event No., Latency 
end

% New Event Structure values as matrix 'eventRecAll' values 
 for nx = 1:length(eventRecAll)
      EEG.newevent(nx) = struct('latency',eventRecAll(nx,3),'type',eventRecAll(nx,1),'viztick',eventRecAll(nx,2));
 end

%Saving new event
%EEG.oldevent = EEG.event;
EEG.event = [];
EEG.event = EEG.newevent;
% for channel 21 which is zeroed out, use GND channel 10
EEG.data(21,:) = EEG.data(10,:);
%Epoching
name = [subj 'tsst_interview_epoch'];
codes = {'1'};
epochend = 1.0; %Time window = 0 to 1 sec = 1000 millisec
EEG = pop_epoch( EEG, codes, [0  epochend],'newname', name, 'epochinfo', 'yes');
[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'savenew',[s.subj_data_path '/' name '.set'],'gui','off'); 
EEG = eeg_checkset( EEG ); %Checking consistency
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); %Storing
EEG = eeg_checkset( EEG ); %Again check for consistency
eeglab redraw

% Epoch rejection 
REJECTION_CRITERION = 6;    % 6 standard deviations, both within and across channels
REJECTION_CHANNELS  = 1:64; % only EEG data channels, not viztick!
EEG = pop_jointprob(EEG,1,REJECTION_CHANNELS, REJECTION_CRITERION, REJECTION_CRITERION, 1, 0);
%Rejects artifacts based on Joint probability of component activities at each time point
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
%Stores EEG dataset to ALLEEG variable containg all current datasets after checking consistency
EEG = pop_rejkurt(EEG,1,REJECTION_CHANNELS , REJECTION_CRITERION, REJECTION_CRITERION, 1, 0);
%Rejects Outliers using Kurtosis
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
%pop_saveset(EEG);%save_dataset;                                            
eeglab redraw

%MANUAL EPOCH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MANUAL EPOCH REJECTION
%       GUI: tools --> Reject data epochs --> reject data (all methods)
%       Run.subj_data_path the manual rejection (Mark trials by appearance: Scroll data)
%       --> Close ([1:4, 5:9,11:20,22:26,28:46,48:50, 52:63]keep marks)
% be sure to delete last few epochs if noisy.
%Yang's notes
%       GUI: tools [1:4, 5:9,11:20,22:26,28:46,48:50, 52:63] --> Inspect/rehecr data by eye --
%       -->reject data (all methods)
%       Run the manual rejection (Mark trials by appearance: Scroll data)
%       --> Close (keep marks)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Collecting all 3 Epoch rejections and sorting in one
rejected.kurtos = find(EEG.reject.rejkurt    ~= 0); %Kurtosis Rejections
rejected.prob   = find(EEG.reject.rejjp      ~= 0); %Joint Probability Rejections
rejected.manual = find(EEG.reject.rejmanual  ~= 0); %Manual Rejections
rejected.all = sort([rejected.kurtos, rejected.manual, rejected.prob],'ascend');
EEG.rejected = rejected;
save(fullfile(s.subj_data_path,[subj 'tsst_interview_epoch_rejected.mat']),'rejected')
%str = ['save' s.subj_data_path 'rejected.mat rejected'];           
%eval(str);                                                             

EEG = eeg_checkset( EEG ); %Checking consistency of dataset
EEG.comments = pop_comments('', '', strvcat(['Parent dataset: ' name], 'epochs selected', ' '));
%EEG = pop_saveset( EEG, 'savemode', 'resave');
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
%pop_saveset(EEG);%save_dataset;

%Removing all rejected componenets and saving the dataset as Pre ICA
%dataset, this step saved two files in the working directory-yang
EEG = eeg_rejsuperpose( EEG, 1, 1, 1, 1, 1, 1, 1, 1);
% Superpose rejections of dataset using all parameters
EEG = pop_rejepoch( EEG, EEG.rejected.all ,0);
% Reject pre labelled trails (i.e the sorted array of all rejected components)
name = [subj 'tsst_interview_epoch_rejected'];
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
pop_saveset(EEG);
eeglab redraw

%% This example code compares PSD in dB (left) vs. uV^2/Hz (right) rendered as scalp topography (setfile must be loaded.) adapted from Makoto's website
EEG = pop_loadset('/home/maxinehe/Downloads/EEG clean data/WEAR p71/WEAR_day1_p71_meditation_backproject_epoched.set');
channels_to_remove = {'GND', 'LHEye', 'RHEye', 'Rmastoid', 'RVEye', 'Lneck', 'Rneck'};

% Remove the specified channels
EEG = pop_select(EEG, 'nochannel', channels_to_remove);

% Check the dataset for consistency
EEG = eeg_checkset(EEG);

lowerFreq  = 8; % Hz
higherFreq = 13; % Hz
meanPowerDb     = zeros(EEG.nbchan,1);
meanPowerMicroV = zeros(EEG.nbchan,1);
for channelIdx = 1:EEG.nbchan
        [psdOutDb(channelIdx,:), freq] = spectopo(EEG.data(channelIdx, :), 0, EEG.srate, 'plot', 'off');
        lowerFreqIdx    = find(freq==lowerFreq);
        higherFreqIdx   = find(freq==higherFreq);
        meanPowerDb(channelIdx) = mean(psdOutDb(channelIdx, lowerFreqIdx:higherFreqIdx));
        meanPowerMicroV(channelIdx) = mean(10.^((psdOutDb(channelIdx, lowerFreqIdx:higherFreqIdx))/10), 2);
end
figure
subplot(1,2,1)
topoplot(meanPowerDb, EEG.chanlocs)
title('Theta band (4-8Hz) power distribution')
cbarHandle = colorbar;
set(get(cbarHandle, 'title'), 'string', '(dB)')
 
subplot(1,2,2)
topoplot(meanPowerMicroV, EEG.chanlocs)
title('Theta band (4-8Hz) power distribution')
cbarHandle = colorbar;
set(get(cbarHandle, 'title'), 'string', '(uV^2/Hz)')
%% This example code compares PSD in dB (left) vs. uV^2/Hz (right) rendered as scalp topography (setfile must be loaded.)
EEG = pop_loadset('/home/maxinehe/Downloads/EEG clean data/meditation clean data/WEAR_day1_p71_meditation_backproject.set');
channels_to_remove = {'GND', 'LHEye', 'RHEye', 'Rmastoid', 'RVEye', 'Lneck', 'Rneck'};

% Remove the specified channels
EEG = pop_select(EEG, 'nochannel', channels_to_remove);

% Check the dataset for consistency
EEG = eeg_checkset(EEG);

lowerFreq  = 8; % Hz
higherFreq = 13; % Hz
meanPowerDb     = zeros(EEG.nbchan,1);
meanPowerMicroV = zeros(EEG.nbchan,1);
for channelIdx = 1:EEG.nbchan
    [psdOutDb(channelIdx,:), freq] = spectopo(EEG.data(channelIdx, :), 0, EEG.srate, 'plot', 'off');
    lowerFreqIdx    = find(freq==lowerFreq);
    higherFreqIdx   = find(freq==higherFreq);
    meanPowerDb(channelIdx) = mean(psdOutDb(channelIdx, lowerFreqIdx:higherFreqIdx));
    meanPowerMicroV(channelIdx) = mean(10.^((psdOutDb(channelIdx, lowerFreqIdx:higherFreqIdx))/10), 2);

end
figure
subplot(1,2,1)
topoplot(meanPowerDb, EEG.chanlocs)
title('Theta band (4-8Hz) power distribution')
cbarHandle = colorbar;
set(get(cbarHandle, 'title'), 'string', '(dB)')
 
subplot(1,2,2)
topoplot(meanPowerMicroV, EEG.chanlocs)
title('Theta band (4-8Hz) power distribution')
cbarHandle = colorbar;
set(get(cbarHandle, 'title'), 'string', '(uV^2/Hz)')

%% Other sample visualization code
% Load the EEG dataset and remove unnecessary channels
EEG = pop_loadset('/home/maxinehe/Downloads/EEG clean data/meditation clean data/WEAR_day1_p71_meditation_backproject.set');
channels_to_remove = {'GND', 'LHEye', 'RHEye', 'Rmastoid', 'RVEye', 'Lneck', 'Rneck'};

% Check the dataset for consistency
EEG = eeg_checkset(EEG);

% Frequency bands: [bandName, lowerFreq, higherFreq]
freqBands = {
    'Delta', 0.5, 4;
    'Theta', 4, 8;
    'Alpha', 8, 13;
    'Beta', 13, 30;
    'Gamma', 30, 45;
};

% Preallocate matrices for power calculations
meanPowerDb = zeros(EEG.nbchan, length(freqBands));
meanPowerMicroV = zeros(EEG.nbchan, length(freqBands));

% Loop through each frequency band
for bandIdx = 1:length(freqBands)
    bandName = freqBands{bandIdx, 1};
    lowerFreq = freqBands{bandIdx, 2};
    higherFreq = freqBands{bandIdx, 3};

    % Loop through each channel to compute power
    for channelIdx = 1:EEG.nbchan
        [psdOutDb(channelIdx, :), freq] = spectopo(EEG.data(channelIdx, :), 0, EEG.srate, 'plot', 'off');
        
        % Find the indices for the current frequency band
        lowerFreqIdx = find(freq >= lowerFreq, 1, 'first');
        higherFreqIdx = find(freq <= higherFreq, 1, 'last');
        
        % Compute the mean power in dB and µV^2/Hz for the current band
        meanPowerDb(channelIdx, bandIdx) = mean(psdOutDb(channelIdx, lowerFreqIdx:higherFreqIdx));
        meanPowerMicroV(channelIdx, bandIdx) = mean(10.^((psdOutDb(channelIdx, lowerFreqIdx:higherFreqIdx))/10), 2);
    end
end

% Plot the power distribution for each frequency band
figure

% Delta band
subplot(1,5,1)
topoplot(meanPowerDb(:,1), EEG.chanlocs);
title('Delta (0.5-4 Hz) Power (dB)');
colorbar;

% Theta band
subplot(1,5,2)
topoplot(meanPowerDb(:,2), EEG.chanlocs);
title('Theta (4-8 Hz) Power (dB)');
colorbar;

% Alpha band
subplot(1,5,3)
topoplot(meanPowerDb(:,3), EEG.chanlocs);
title('Alpha (8-13 Hz) Power (dB)');
colorbar;

% Beta band
subplot(1,5,4)
topoplot(meanPowerDb(:,4), EEG.chanlocs);
title('Beta (13-30 Hz) Power (dB)');
colorbar;

% Gamma band
subplot(1,5,5)
topoplot(meanPowerDb(:,5), EEG.chanlocs);
title('Gamma (30-45 Hz) Power (dB)');
colorbar;

% Adjust the figure to fit all subplots neatly
set(gcf, 'Position', [100, 100, 1200, 400]);  % Adjust the size as needed

