%% Instruction
% the purpose of this code is to sync EEG and E4 such that synced EEG has equal data
% length as E4 (because E4 always starts latest and ends earliest and EEG runs the longest time)

% Note EEG data is segmented that each EEG file contains one task condition recording
% for each individual, but E4 is continuous for the entire study (~2hour long)

% Thus we use tags from E4 (tags.csv) to annotate the start and end of each task
addpath '/home/maxinehe/Documents/MATLAB/eeglab2023.1'
eeglab
%% close previous windows and clear previous datasets
close all
clear all

%Loading dataset

eeglab             
s.subj_data_path = '/home/maxinehe/Downloads/EEG'; % --> replace with your directory in which the EEG data was saved

fname = 'WEAR_day1_p30_standing_stroop'; % --> replace file name here
subj = 'p30'; % --> replace participant ID here

% note you will need .vhdr, .eeg and vmrk of each condition in the same folder
% EEG channels (1:64), channel 65 is Aux 1 for GSR sensor
EEG = pop_loadbv(s.subj_data_path, 'WEAR_day1_p30_standing_stroop.vhdr', [], [1:65]); % --> change the file name to read vhdr file


ALLEEG=[]
[ALLEEG EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',fname,'gui','off'); 
eeglab redraw
%% read the EEG start time from vhdr file
start_time = '';
% Open the file
% Used vhdr file previously, but I noticed some of files does not have the
% time stamp in that file, and it only has HH:MM:SS information that requires 
% to read E4 BVP file to get the date information. 
% Instead, vmrk provides a more precise time in
% milliseconds level, so here vmrk will be used, and the interpolation from
% E4 BVP is no longer required.
fileID = fopen('/home/maxinehe/Downloads/EEG/WEAR_day1_p30_standing_stroop.vmrk'); % --> Replace with file name
% Loop through each line of the file
while ~feof(fileID)
    currentLine = fgetl(fileID);
    
    % Check if the line contains start time
    if contains(currentLine, 'Mk1=New Segment,,1,1,0,')
        start_time = currentLine;
        break;
    end
end

% Extract the date and time part from the string
% Assuming the format is consistent and the date-time part is always at the end
dateTimeStr = regexp(start_time, '\d{17}', 'match');
dateTimeStr = dateTimeStr{1};

% Convert the string to datetime format
% Format: 'yyyyMMddHHmmssSSS' (Year, Month, Day, Hour, Minute, Second, Millisecond)
dateTimeObj = datetime(dateTimeStr, 'InputFormat', 'yyyyMMddHHmmssSSS', 'TimeZone', 'America/Chicago');

% Convert datetime to Unix time in seconds since 01-Jan-1970 00:00:00
eeg_start_time = posixtime(dateTimeObj);

%% now read E4 BVP file and get unix time
% since EEG start time only has H:M:S, need to convert BVP unix time back
% to world time to extract Year, Month and Date. Then concatenate Year,
% Month and Date information with EEG start time, and convert back to unix
% time

% import E4 tags to truncate EEG data in next section
e4_tags = readmatrix('/home/maxinehe/Downloads/tags.csv');

%% convert E4 and EEG data to struct to add the timesamp for each data point

% start creating an eeg_time array to stroe interpolated timestamp
eeg_time = linspace(0, length(EEG.data)-1, length(EEG.data));
for i = 1 : length(EEG.data)
    eeg_time(i) = eeg_time(i)/1000+eeg_start_time;
end

% transpose so it is a column vector
EEG.Timestamp = eeg_time';
%% Use the tags.csv file to extract the start and end time of each task

% order of conditions: meditaiton --> cold pressor --> EC --> EO --> Social Stress --> Seated stroop --> Walking stroop
% for SfN submission, ignore the Walking stroop test

% during the data collection, the start and end time of each condition is taged and recorded in tags.csv --> at least of 14 tags (7 conditions*2)
% although in some cases we taged more than once for the start/end --> look up the tags_note.boxnote in the box folder to see which tags should be ignored

% Take WEAR p13 for example here which has 16 tags in original tags.csv --> check file 'Tags note.boxnote', which said to ignore the fifth and last tags
% (because we accidentally taged twice for some conditions)
% so the tags.csv is interpereted like this:
% 1680367718.98 --> meditation start
% 1680368025.92 --> meditation end
% 1680368295.25 --> cold pressor start
% 1680368363.77 --> cold pressor end
% 1680368380.12 --> ignore
% 1680368525.91 --> eye close start
% 1680368594.19 --> eye close end
% 1680368672.09 --> eye open start
% 1680368739.86 --> eye open end
% 1680368972.58 --> trier social stress start
% 1680370049.55 --> trier social stress end
% 1680371030.75 --> seated stroop start
% 1680371697.41 --> seated stroop end
% 1680373057.73 --> walking stroop start
% 1680373698.77 --> walking stroop end
% 1680373727.42 --> ignore

% for tasks that have a known fixed lenght (e.g., meditation (5min/300s), and Cold pressor/EC/EO (1min/60s)):
% use the tag for task start time, then add the duration to the task end time rather than using the tags
% take trier social stress for example:
% e4_start = e4_tags(1); --> read the first tag from tags.csv file as the meditation start time
% e4_end = e4_tags(1)+5*60; --> instead of reading e4_tags(2), add the meditation start time by 300 seconds (5 minutes) to get the end time

% for tasks that have flexible duration (e.g., social stress test, and seated stroop test), use the e4 tags for both start and end time
% take social stress test for example:
% e4_start = e4_tags(10); --> read 10th tag from the file (note even though I said ignore for 5th and last tags, these 2 tags are not removed from
% tags.csv, so you still count from the first tag all the way down to see which one is trier social stress start time)
% e4_end = e4_tags(11); --> read 11th tag from the file as trier social stress end

e4_start = e4_tags(13); % --> change the number in () for corresponding tag; note matlab starts counting from 1 ,so e4_tags(1) read the 1st line and so on
e4_end = e4_tags(14); % --> change for each condition

%% Truncate the EEG data based on the E4 start and end time of each condition
% make sure sync_offset.m is in the same folder as this script

% run this section only ONCE --> always check the data size in the GUI
% window (the data size should be around 80MB for short tasks and around
% 200 MB for longer tasks)

[offset_eeg_data, offset_eeg_time, offset_eeg_time_relative] = sync_offset(EEG,e4_start, e4_end);
% transpose data back to the stucure (channel by data)
EEG.data = offset_eeg_data';

% transpose time data back to the row vector and store timestamp
EEG.times = offset_eeg_time_relative;
EEG.Timestamp = offset_eeg_time';

ALLEEG=[];
[ALLEEG EEG, CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'setname',fname,'gui','off'); 

EEG = eeg_checkset(EEG); %Again check for consistency
[ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
pop_saveset(EEG); % --> save_dataset as WEAR_day1_p#_synced_condition.set (WEAR_day1_p33_sync_meditaiton.set, for example) and upload to EEG synced data folder in box
eeglab redraw