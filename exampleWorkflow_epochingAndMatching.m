%% Example workflow 1
% The following is an example worflow to a) epoch an EEG data set into
% individual trials when the trials have varying durations, and b) use the
% StimTrack information to match each trial with its corresponding stimulus
% (i.e., the auditory stimulus that was presented to the participant in
% that trial).

% The necessary functions can be found here: https://github.com/elidom/Useful-Matlab-Scripts-for-EEG/tree/main

% % % 1. Epoch the EEG data with variable trial durations
epoched_data = epoch_eeg_variable_durations('eeg_sets_REST/sub01_REST_elist.set', 200, 'Onset', 'Offset');


% % % 2. Create list of audio files
dirTmp = dir('stims');
dirTmp = dirTmp(~[dirTmp.isdir]);
% audFiles = string({dirTmp.name})';
audFiles = string(fullfile('stims', {dirTmp.name}))';

% % % 3. Match EEG data to audio data trial-wise

% n = length(epoched_data);
n = 7; % replace for total number of trials

matched_trials = cell(n, 4); % preallocate output memory

st_chan = 65; % StimTrack channel

for t = 1:n 
    % Extract trial data and header
    trial = epoched_data{t, 1};
    hdr   = epoched_data{t, 2};

    % Extract Stim Track channel from trial data (channel 63)
    stim_track = trial(st_chan,:);
    stim_track = stim_track - mean(stim_track);                   % Remove mean
    stim_track = stim_track / max(abs(stim_track));               % Normalize

    % Main function call
    maxCorrValues = matchTrial2Stim(stim_track, audFiles);

    % Find the audio file with the highest correlation
    [value, bestFileIdx] = max(maxCorrValues);
    bestFileName = audFiles(bestFileIdx);
    
    % Store the matched trial information
    matched_trials{t,1} = trial;
    matched_trials{t,2} = hdr;
    matched_trials{t,3} = bestFileName;
    matched_trials{t,4} = value;

end

%% Alternative: 
% 3. Match EEG data to audio data trial-wise, but first sub-sample the set
% of candidate audio files.

n = 7; % replace for total number of trials

matched_trials = cell(n, 4); % preallocate output memory

st_chan = 65; % StimTrack channel

for t = 1:n 
    % Extract trial data and header
    trial = epoched_data{t, 1};
    hdr   = epoched_data{t, 2};
    
    trial_type = split(hdr, "_");

    % Map trial type to semantics and prosody codes
    if trial_type{1} == "Interesting"
        semantics = "int";
    else
        semantics = "bor";
    end

    if trial_type{2} == "Engaging"
        prosody = "eng";
    else
        prosody = "neu";
    end

    % Split filenames to extract semantics and prosody information
    stim_split = split(audFiles, "_");
    stim_semantics = stim_split(:,2);
    stim_prosodies = stim_split(:,4);

    % Find indices of audio files matching the trial semantics and prosody
    sm_idx = find(stim_semantics == semantics);
    pr_idx = find(stim_prosodies == prosody);
    candid_idx = intersect(sm_idx, pr_idx);
    candidates = audFiles(candid_idx);

    % Extract Stim Track channel from trial data (channel 63)
    stim_track = trial(st_chan,:);
    stim_track = stim_track - mean(stim_track);                   % Remove mean
    stim_track = stim_track / max(abs(stim_track));               % Normalize

    % Main function call
    maxCorrValues = matchTrial2Stim(stim_track, candidates);

    % Find the audio file with the highest correlation
    [value, bestFileIdx] = max(maxCorrValues);
    bestFileName = candidates(bestFileIdx);
    
    % Store the matched trial information
    matched_trials{t,1} = trial;
    matched_trials{t,2} = hdr;
    matched_trials{t,3} = bestFileName;
    matched_trials{t,4} = value;

end