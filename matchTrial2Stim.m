function [maxCorrValues] = matchTrial2Stim(stim_track, audFiles)
% MATCHTRIAL2STIM Compute maximum cross-correlation between a stimulus track and audio files.
%
%   maxCorrValues = matchTrial2Stim(stim_track, audFiles)
%
%   This function computes the maximum normalized cross-correlation between a stimulus track
%   (e.g., extracted from an EEG trial) and a set of candidate audio files.
%
%   Inputs:
%       stim_track - A vector containing the stimulus track data. It is expected to be
%                    sampled at 500 Hz and preprocessed (mean removed and normalized).
%       audFiles   - A cell array or array of strings with the file paths of the audio files.
%
%   Output:
%       maxCorrValues - An array containing the maximum cross-correlation value for each audio file.
%
%   The function resamples the audio files to match the sampling rate of the stim_track (500 Hz),
%   normalizes both signals, and computes the maximum cross-correlation over sliding windows.
%
%   Example:
%       maxCorrValues = matchTrial2Stim(stim_track, {'audio1.wav', 'audio2.wav'});
%
%   Notes:
%       - The audio files are expected to be in a format readable by audioread.
%       - The function assumes that the original sampling rate of the audio files is 44.1 kHz.
%       - The cross-correlation is computed using the Pearson correlation coefficient.
%
%   See also audioread, corrcoef, resample.

% Error Check
if nargin ~= 2
    error('matchTrial2Stim requires two input arguments: stim_track and audFiles.');
end

    % preallocate output
    maxCorrValues = nan(1, length(audFiles));

    for i = 1:length(audFiles)
        

        % Read current candidate audio file
        curr_filename = audFiles(i);
        wav = audioread(curr_filename);

        % Preprocess audio data
        wav_t = wav';
        wav_resampled = resample(wav_t, 500, 44100);              % Resample to 500 Hz
        wav_resampled = wav_resampled - mean(wav_resampled);      % Remove mean
        wav_resampled = wav_resampled / max(abs(wav_resampled));  % Normalize

        % Compare lengths of signals
        len_wav  = length(wav_resampled);
        len_stim = length(stim_track);

        % Initialize maximum correlation for this file
        maxCorr = -Inf;
        
        % Perform sliding window cross-correlation
        if len_wav > len_stim
            % If audio is longer than stim track
            for j = 1:(len_wav - len_stim + 1)
                segment = wav_resampled(j:(j + len_stim - 1));
                % Compute normalized cross-correlation
                corrCoeff = corrcoef(segment, stim_track);
                corrValue = corrCoeff(1, 2);
                if corrValue > maxCorr
                    maxCorr = corrValue;
                end
            end
        else
            % If stim track is longer than audio
            for j = 1:(len_stim - len_wav + 1)
                segment = stim_track(j:(j + len_wav - 1));
                % Compute normalized cross-correlation
                corrCoeff = corrcoef(segment, wav_resampled);
                corrValue = corrCoeff(1, 2);
                if corrValue > maxCorr
                    maxCorr = corrValue;
                end
            end
        end
        
        % Store maximum correlation value for this candidate
        maxCorrValues(i) = maxCorr;
    end

end
