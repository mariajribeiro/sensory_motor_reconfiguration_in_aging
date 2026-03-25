% analyses pupil data 
% Maria Ribeiro 17 May 2019
% edf files converted to ascii using the SR Research edf converter
clear; close all;

parentFolder = fileparts(pwd);
parentFolder_2 = fileparts(parentFolder);

data_dir_all = [parentFolder_2, '\data\ET_data\'];

addpath(parentFolder);
group = participants_included;
participants = [group{1}, group{2}];
numb_participants = length(participants);
save_dir=[parentFolder, '\pupil\preprocessed_pupil_files'];
% already_processed = dir(save_dir);
already_processed.name = {'process_all'};

% open eeglab
[ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
% edit memory options
pop_editoptions( 'option_storedisk', 0, 'option_savetwofiles', 0, 'option_saveversion6', 1, 'option_single', 1, 'option_memmapdata', 0, 'option_eegobject', 0, 'option_computeica', 0, 'option_scaleicarms', 1, 'option_rememberfolder', 0, 'option_donotusetoolboxes', 0, 'option_checkversion', 1);


for p = 1:numb_participants
    subject = participants{p};


    % each subject has at least one session outside the scanner (sessions 1 and 2) and one inside
    % the scanner (session 3). In session 4, we run the inference task only outside the scanner 
    S = dir([data_dir_all, subject]);
    sessions = []; % sessions = sum([S(~ismember({S.name},{'.','..'})).isdir]);
    for f = 1:length(S)
        if contains(S(f).name, 'session')
            sessions = [sessions, str2num(S(f).name(8))];
        end
    end

    % clear eeglab
    STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
    for session = sessions
        folder_session = [data_dir_all, subject, '\session', num2str(session)];
        MyFolderInfo = dir(folder_session);
        runs = size(MyFolderInfo, 1)-2;
        for run = 1:runs
            a = 0; % find if subject data has already been preprocessed
            for f = 1:length(already_processed)
                if contains(already_processed(f).name, [subject, '_',num2str(session), '_', num2str(run)])
                    a = 1;
                end
            end
    
            if a == 0 % run if subject run data has not been preprocessed yet!
            
            
            if strcmp(subject, 'AB057') && session == 1 && run == 1
                continue
            elseif strcmp(subject, 'AB127') && session == 4 && run == 4
                continue
            elseif strcmp(subject, 'AB132') && session == 3
                continue
            elseif strcmp(subject, 'AB144') && session == 1 && run == 3 % did not remember task instructions - had to repeat training
                continue
            elseif strcmp(subject, 'AB144') && session == 3 % could not see stimulus in the scanner - not feeling well
                continue
            elseif strcmp(subject, 'AB148') && session == 1 % had not understood task instructions properly
                continue
            elseif strcmp(subject, 'AB150') && session == 3 % ET not capturing the eye
                continue
            elseif strcmp(subject, 'AB152') && session == 1 && run  == 3 % mistake with rule setting
                continue
            elseif strcmp(subject, 'AB156') % did not understand the task
                continue
            elseif strcmp(subject, 'AB157') && session == 1 && run  == 2 % ET data not saved
                continue
            elseif strcmp(subject, 'AB174') && session == 1 && run  == 1 % could not see stimulus properly - used reading glasses from then on
                continue
            elseif strcmp(subject, 'AB176') && session == 1 && run  == 1 % was applying the rule wrongly, asked to restart
                continue
            elseif strcmp(subject, 'AB178') && session == 3 && run  == 1 % aborted run
                continue
            elseif strcmp(subject, 'AB181') && session == 3 && run  == 1 % aborted run
                continue
            end
            data_dir = [folder_session,'\run', num2str(run)];
            if strcmp(subject, 'AB97') && session == 1
                filename = [data_dir, filesep, subject, '.asc'];
            else
                filename = [data_dir, filesep, subject(3:end), 'S', num2str(session), 'R', num2str(run), '.asc'];
            end
            %script adapted from a1_PupilAnalysis.m -  Urai AE, Braun A, Donner THD (2016) Pupil-linked arousal is driven
            % by decision uncertainty and alters serial choice bias.

            % read in the asc EyeLink file
            asc = read_eyelink_ascNK_AU(filename);

            % create events and data structure, parse asc
            [data, event, blinksmp, saccsmp] = asc2dat(asc);

            % save
            % savefast(sprintf('P%02d_s%d_b%02d_eye.mat', sj, session, block), 'data', 'asc', 'event', 'blinksmp', 'saccsmp');

            % ==================================================================
            % blink interpolation
            % ==================================================================

            [pupil_interpolated, newblinksmp, nanIdx, dat] = blink_interpolate(data, blinksmp, 1);

%             % ==================================================================
%             % regress out pupil response to blinks and saccades
%             % ==================================================================
% 
%             % for this, use only EL-defined blinksamples
%             % dont add back slow drift for now - baseline doesn't make a lot of
%             % sense after this anymore...
%             addBackSlowDrift = 1; % add back slow drift as this might be important to study changes in tonic pupil size
%             pupil_regressed = blink_regressout(pupil_interpolated, data.fsample, blinksmp, saccsmp, 1, addBackSlowDrift);


            %% extract triggers from messages and create data 4 eeglab 
            pupil_data4eeglab = create_datastruct4eeglab(subject, session, pupil_interpolated, dat, event, blinksmp, saccsmp, nanIdx);

    %         ALLEEG = []; EEG = []; % clear EEGlab


    %         EEG = pop_importdata('dataformat','matlab','nbchan',5,'data', pupil_data4eeglab,'setname',pupil_data4eeglab,'srate',1000,'pnts',size(pupil_data4eeglab, 2));
    %         EEG = pop_importdata('dataformat','matlab','nbchan',5,'data', pupil_data4eeglab,'setname',pupil_data4eeglab,'srate',500); %,'pnts',size(pupil_data4eeglab, 2));
    %         [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 
    %         EEG = pop_chanevent(EEG, 5, 'edge', 'leading'); % channel with the triggers
    %         [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);

            EEG = pop_importdata('dataformat','array','nbchan',0,'data','pupil_data4eeglab','setname','pupil_data4eeglab','srate',500,'pnts',0,'xmin',0);
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 

            EEG = eeg_checkset( EEG );
            EEG = pop_chanevent(EEG, 7,'edge','leading','edgelen',0);
            [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
            interp_data = EEG.data(6, :);
            EEG = pop_eegfiltnew(EEG, 'locutoff',0.06,'hicutoff',6);
            EEG.data(6, :) = interp_data;
            filename = ['pupil_', subject, '_',num2str(session), '_', num2str(run), '.set'];

            EEG = pop_saveset( EEG, 'filename',filename,'filepath', save_dir);
            end
        end
    end
end

% eeglab redraw



%% functions

% extract triggers and create data structure for eeglab with pupil data
function pupil_data4eeglab = create_datastruct4eeglab(subject, session, pupil_interpolated, data, event, blinksmp, saccsmp, nanIdx)

    % trigers
    % 1 - samples
    % 2 - blinks
    % 3 - saccades
    % 4 - choice trials - onset of visual grating stimulus
    
    triggers=zeros(length(pupil_interpolated), 1);
    index = []; %index_sample = []; 
    for i=1:size(event, 1)
%         text{i, 1}=char(messages{i, 2});
%     end
        if strcmp(subject, 'AB97') && session == 1
          index_type = strfind(event(i).value,'type');
            if  strcmp(event(i).value(index_type+5), '0')
                triggers(event(i).sample) = 1;
                move_blink_sac_triggers;
            end
        elseif strcmp(event(i).type,'sample_onset')
            triggers(event(i).sample) = 1;
            move_blink_sac_triggers;
        elseif contains(event(i).type,'CHOICE_TRIAL_ONSET') %choice trials - onset of visual grating stimulus
            triggers(event(i).sample) = 4;
            move_blink_sac_triggers;
        end       
    end
    
    triggers(blinksmp(:, 2)) = 2; % blink offset
    triggers(saccsmp(:, 2)) = 3; % saccade offset
    
    pupil_data4eeglab(1, :) = (pupil_interpolated - mean(pupil_interpolated))/mean(pupil_interpolated); % before regressing out effect of blinks and saccades
    pupil_data4eeglab(2, :) = zscore(pupil_interpolated);
    pupil_data4eeglab(3, :) = pupil_interpolated;
    pupil_data4eeglab(4, :) = data.gazex-mean(data.gazex); % gaze data with blinks linearly interpolated - demeaned
    pupil_data4eeglab(5, :) = data.gazey-mean(data.gazey);
    
    interpolated_data = zeros(length(pupil_data4eeglab(1, :)), 1);
    interpolated_data(nanIdx) = 1;
    pupil_data4eeglab(6, :) = interpolated_data;
    pupil_data4eeglab(7, :) = triggers;
    
    
    function move_blink_sac_triggers
        % make sure blink and saccade triggers do not fall on stimuli triggers or just next to it
        if ~isempty(find(blinksmp(:, 2) == event(i).sample, 1)), index = [i; index]; 
        elseif ~isempty(find(blinksmp(:, 2) == event(i).sample)+1), index = [i; index]; 
        end
        blinksmp(blinksmp(:, 2) == event(i).sample, 2) = blinksmp(blinksmp(:, 2) == event(i).sample, 2)-5;
        blinksmp(blinksmp(:, 2) == event(i).sample-1, 2) = blinksmp(blinksmp(:, 2) == event(i).sample-1, 2)-5;
        saccsmp(saccsmp(:, 2) == event(i).sample, 2) = saccsmp(saccsmp(:, 2) == event(i).sample, 2)-5;
        saccsmp(saccsmp(:, 2) == event(i).sample-1, 2) = saccsmp(saccsmp(:, 2) == event(i).sample-1, 2)-5;
    end

end
    



% function to create figure comparing 2 conditions
function figure_2conditions(data_cond1, data_cond2, xaxis, title, xlabel, ylabel)

Mean_Condition1=[mean(pupil_unambiguous, 2)]';
SE_Condition1=[std(pupil_unambiguous, 0, 2)/sqrt(size(pupil_unambiguous, 2))]';

Mean_Condition2=[mean(pupil_ambiguous, 2)]';
SE_Condition2=[std(pupil_ambiguous, 0, 2)/sqrt(size(pupil_ambiguous, 2))]';


x_axis=[];
x_axis=-200:4999;
%detection corrects Older
figure;
plot(x_axis, Mean_Condition1,'color', [0 .5 0], 'LineWidth',1.5)
hold on
jbfill(x_axis,Mean_Condition1+SE_Condition1,Mean_Condition1-SE_Condition1, [0 .5 0],[0 .5 0], 0.1)
% detection corrects Older
hold on
plot(x_axis, Mean_Condition2,'color', [1 .5 0], 'LineWidth',1.5)
hold on
jbfill(x_axis,Mean_Condition2+SE_Condition2,Mean_Condition2-SE_Condition2, [1 .5 0], [1 .5 0], 0.1)
% zero line
hold on
plot(x_axis, zeros(length(x_axis)), 'k:');
hold off
ax = gca;
c = ax.Color;
% legend('Detection', 'GNG')
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';
axis([-200 2000 -inf inf])
xlabel('Time (ms)', 'FontSize', 24, 'FontWeight','normal')
ylabel({'Pupil dilation' '(% signal change)'}, 'FontSize', 24, 'FontWeight','normal')

end