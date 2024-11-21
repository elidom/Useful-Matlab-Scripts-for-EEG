function [epoched_data] = epoch_eeg_variable_durations(set_name, minDistance2Bound, onset_marker, offset_marker)

% EPOCH_EEG_VARIABLE_DURATIONS Epoch EEG data with variable trial durations.
%
%   epoched_data = epoch_eeg_variable_durations(set_name, minDistance2Bound, onset_marker, offset_marker)
%
%   This function processes EEG data by extracting epochs corresponding to
%   trials with variable durations. It only includes trials that are complete
%   (i.e., have both specified onset and offset events) and are sufficiently far from
%   boundary events, ensuring a buffer before onset and after offset.
%
%   Inputs:
%       set_name            - Filename of the EEG dataset (.set file).
%       minDistance2Bound   - Minimum distance (in samples) to a boundary event
%                             required to consider a trial valid.
%       onset_marker        - Character array or string specifying part of the onset event label.
%       offset_marker       - Character array or string specifying part of the offset event label.
%
%   Outputs:
%       epoched_data        - Cell array where each row contains:
%                               {epoch_data, trial_type}
%                             epoch_data is a matrix of EEG data for the trial,
%                             and trial_type is the type of the trial (string).
%
%   Example:
%       epoched_data = epoch_eeg_variable_durations('subject1.set', 500, 'StimOn', 'StimOff');
%
%   Notes:
%       The function assumes that the EEG dataset contains event markers with
%       specified onset and offset labels indicating the start and end of trials,
%       and 'boundary' labels indicating discontinuities in the data.
%
%       If the onset label is, e.g., "study_aa_StimOn", it is sufficient to
%       write "StimOn" as thrid argument.
%
%       Why did the EEG trial get rejected?
%       Because it crossed a boundary!
%

% Input Checks
if ~ischar(set_name) && ~isstring(set_name)
    error('The input ''set_name'' must be a character array or string representing the filename.');
end

if ~exist(set_name, 'file')
    error(['The file ', char(set_name), ' does not exist in the current directory or MATLAB path.']);
end

if ~isnumeric(minDistance2Bound) || ~isscalar(minDistance2Bound) || minDistance2Bound <= 0
    error('The input ''minDistance2Bound'' must be a positive scalar numeric value.');
end
    
% Load the EEG dataset
EEG = pop_loadset('filename', set_name);

% List of substrings to match for removal
keep_substrings = {onset_marker, offset_marker};

% Get all codelabels from EEG.event
codelabels = {EEG.event.codelabel};

% Initialize logical array to mark events for removal
keep_indices = false(1, length(codelabels));

% Loop over each substring and find matching events
for i = 1:2
    substring = keep_substrings{i};
    % For MATLAB R2016b and newer, use 'contains'
    
    matches = contains(codelabels, substring);
    
    % Update the indices of events to remove
    keep_indices = keep_indices | matches;
end


% Keep only the desired events in EEG.event
EEG.event = EEG.event(keep_indices);

% {EEG.event.codelabel}' % sanity check

% If urevent field exists, update it as well
if ~isempty(EEG.urevent)
    EEG.urevent = EEG.urevent(keep_indices);
end

% Get the number of events
n_events = length(EEG.event);

% Initialize the output cell array and counters
epoched_data = {};
w = 1;
trials_added = 0;
trials_invalid = 0;
trials_too_close = 0;

% Loop through events, starting from the third event to avoid indexing issues
for i = 3:n_events-1

    % Current, previous, and neighboring events
    curr_event = EEG.event(i);
    prev_event = EEG.event(i-1);
    prevBound  = EEG.event(i-2);
    afterBound = EEG.event(i+1);
    
    % Event types (labels)
    curr_type = curr_event.codelabel;
    prev_type = prev_event.codelabel;
    
    % Check if previous and next events are boundary events
    isBoundPre  = contains(prevBound.codelabel, 'boundary');
    isBoundPost = contains(afterBound.codelabel, 'boundary');
    
    % Assume the trial is far enough from boundaries
    farEnough = 1;
    
    % Check if the current and previous events form a complete trial
    if contains(curr_type, offset_marker) && contains(prev_type, onset_marker) 
    
        % Check distance to previous boundary event
        if isBoundPre
            dist2bound = prev_event.latency - prevBound.latency; % distance in samples between onset and boundary
            farEnough = dist2bound > minDistance2Bound;
        end
        
        % Check distance to next boundary event
        if isBoundPost
            dist2bound =  afterBound.latency - curr_event.latency; % distance in samples between onset and boundary
            farEnough = dist2bound > minDistance2Bound;
        end
        
        % If the trial is too close to a boundary, skip it
        if ~farEnough
            trials_too_close = trials_too_close + 1;
            continue
        end
        
        % Define the start and end of the epoch, adding a 200-sample buffer
        trial_start = prev_event.latency - 200;
        trial_end   = curr_event.latency + 200;
        
        % Extract the epoch data from the EEG
        epoch = EEG.data(:, trial_start:trial_end); 
        
        % Store the epoch data and trial type in the output cell array
        epoched_data{w, 1} = epoch;
        epoched_data{w, 2} = prev_type;
        
        % Increment the counter
        w = w + 1;
        trials_added = trials_added + 1;
        
    else
    
        trials_invalid = trials_invalid + 1;
    
    end
end

% Display the summary of trials processed
disp(['Total trials added: ', num2str(trials_added)]);
disp(['Total invalid trials: ', num2str(trials_invalid)]);
disp(['Total trials rejected due to proximity to boundary: ', num2str(trials_too_close)]);

end