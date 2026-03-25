% run on server  graphs on computer
clear; close all

addpath('D:\Project_LC_fMRI\analyses')
group = participants_included;

task_pupil_dir = [pwd, filesep, 'preprocessed_pupil_files'];
S = dir(task_pupil_dir);

% open eeglab
[ALLEEG EEG, CURRENTSET ALLCOM] = eeglab;
run('init_unfold.m') % start toolbox unfold

beta_choice = cell(2, 1);
beta_choice{1} = zeros(length(group{1}), 1000, 4);
beta_choice{2} = zeros(length(group{2}), 1000, 4);

beta_uncertainty = cell(2, 1); 
beta_uncertainty{1} = zeros(length(group{1}), 4);
beta_uncertainty{2} = zeros(length(group{2}), 4);

Corr_pupil_uncert = cell(2, 1); 
Corr_pupil_uncert{1} = zeros(length(group{1}), 4);
Corr_pupil_uncert{2} = zeros(length(group{2}), 4);

subj_id = cell(2, 1); 

for grp = 1:2
    for sbj = 1:length(group{grp})
        close all
        subject = char(group{grp}(sbj));
        subj_id{grp} = [subj_id{grp}; subject];

        % each subject has at least one session outside the scanner (sessions 1 and 2) and one inside
        % the scanner (session 3)
        % some participants also have outside the scanner four runs of
        % inference-only task saved as session 4
        S = dir(['D:\Project_LC_fMRI\data\ET_data', filesep, char(subject)]);
        sessions = []; % sessions = sum([S(~ismember({S.name},{'.','..'})).isdir]);
        for f = 1:length(S)
            if contains(S(f).name, 'session')
                sessions = [sessions, str2num(S(f).name(8))];
            end
        end

        b=0; condition = []; %cpp_ruleswitch_tmp = []; uncertainty_ruleswitch_tmp = []; number_highlowcpp_rs_tmp = [];
        clear sample_genside

        % clear eeglab
        STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
        processed_sets = []; uncertainty = [];
        for session = sessions
            % pupil preprocessed + gaze position
            % 1 - in the lab; 2 - in the MRI scanner; 3 -
            % inference-only task in the lab
            cond = [];
            if ismember(session, [1, 2]) % in the lab - hierarchical decisions task
                condition = [condition, 1];
                cond = 1;
            elseif session == 3 % in the scanner - hierarchical decisions task
                condition = [condition, 2];
                cond = 2;
            elseif session == 4 % inference only in the lab
                condition = [condition, 3];
                cond = 3;
                continue
            end
            
            folder_session = ['D:\Project_LC_fMRI\data\ET_data', filesep, char(subject), filesep, 'session', num2str(session)];
            MyFolderInfo = dir(folder_session);
            runs = size(MyFolderInfo, 1)-2;
            for run = 1:runs
%                 disp(['run', num2str(run)])
                if ismember(subject, {'AB057', 'AB101', 'AB067', 'AB112'}) && session == 1 && run == 1
%                  AB112 - did not understand the task until run2
%                  AB057, AB101,AB067 - first run stopped prematurely by mistake
                    continue
                elseif strcmp(subject, 'AB071') && session == 3 && run == 1
                    % eye tracking data with bad focus for S3R1
                    continue
                elseif strcmp(subject, 'AB110') && (session == 3 && run~=1)
                    % unstable eye tracking data - astigmatism correction
                    continue
                elseif strcmp(subject, 'AB132') && ((session == 1 && ismember(run, [1, 2, 3])) || session ==3)
                    % this participant did not understand the task up to
                    % the last run of session1
                    % in the scanner ET could not capture the eye due to
                    % glasses correcting for astigmatism
                    continue
                elseif strcmp(subject, 'AB134') && session == 3 && ismember(run, 1)
                    % problems with using the response boxes in the scanner
                    % during the first run
                    continue
                elseif strcmp(subject, 'AB136') && session == 1 && ismember(run, [1, 2])
                    % participant with vision fusion problems (strabism) -
                    % fist two runs of session one ET acquired with left
                    % eye that was not the dominant and was not following
                    % gaze
                    continue
                elseif strcmp(subject, 'AB127') && session == 4 && run == 4
                    % eye tracking data deleted by mistake for S4R1
                    continue
                elseif strcmp(subject, 'AB132') && session == 3 % ET could not capture the eye - eye not within site of camera
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
                b = b+1;
                sample_dir = [folder_session , filesep, 'run', num2str(run)];

                Files=dir(fullfile(sample_dir,'*.mat'));
                filename = [];
                for i=1:size(Files, 1)
                    if contains(Files(i).name, [subject])
                        filename = Files(i).name;
                    end
                end

                load([sample_dir filesep filename]);

                % determine samples where the rule switched
                a = 0; sample_genside = [];
                for i=1:size(p.out.log)
                     if strcmp(p.out.log{i}(2), 'GL_TRIAL_GENSIDE')
                         a = a+1;
                         sample_genside(a, 1) = cell2mat(p.out.log{i}(3));
                     end
                end
                
                % determine choice trials to delete from sample genside 
                a = 0; trial_type = [];
                for i=1:size(p.out.log)
                     if strcmp(p.out.log{i}(2), 'GL_TRIAL_TYPE')
                         a = a+1;
                         trial_type(a, 1) = cell2mat(p.out.log{i}(3));
                     end
                end

                sample_genside(trial_type == 1) = [];
                
                rule_switches = diff(sample_genside);
                rule_switch = find(abs(rule_switches) > 0)+1;
                
                a = 0; sample_location_blocks = [];
                for i=1:size(p.out.log)
                     if strcmp(p.out.log{i}(2), 'GL_TRIAL_LOCATION')
                         a = a+1;
                         sample_location_blocks(a, 1) = cell2mat(p.out.log{i}(3));
                     end
                end
                
                
                % calculate task parameters from inference model
                % function [CPP, prior, LLR] = change_point_probability(sample_location, H, mu, sd)
                mu = p.sequence.threshold; sd = p.sequence.sigma;
                [CPP, prior, LLR] = change_point_probability(sample_location_blocks, 1/70, mu, sd);
                
                

                % load pupil data
                EEG = pop_loadset('filename',['pupil_', char(subject), '_',num2str(session), '_', num2str(run), '.set'],'filepath', task_pupil_dir);
                [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);

                % create events for rule switches
                % eventstruct = importevent( event, oldevent, srate, 'key1', 'value1', ...);
                cues_latency = [];
                for evn = 1:length(EEG.event)
                    if EEG.event(evn).type == 1 %|| EEG.event(evn).type == 4
                        cues_latency = [cues_latency; EEG.event(evn).latency];
                    end
                end

                
                % downsample pupil to 50 Hz
                nanidx_chn = EEG.data(6, :);
                EEG = eeg_checkset( EEG );
                EEG = pop_resample( EEG, 50);
                EEG.data(6, :) = nanidx_chn(1:10:end);
                [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 

                evn_choicetrial_idx_50Hz = [];
                evn_cue_idx_50Hz = [];
                for e = 1:length(EEG.event)
                    if EEG.event(e).type == 4
                        evn_choicetrial_idx_50Hz = [evn_choicetrial_idx_50Hz; round(EEG.event(e).latency)];
                    elseif EEG.event(e).type == 1
                        evn_cue_idx_50Hz = [evn_cue_idx_50Hz; round(EEG.event(e).latency)];
                    end
                end

                % unfold requires events are strings
                for evn = 1:length(EEG.event)
                    EEG.event(evn).type = num2str(EEG.event(evn).type);
                end
                [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET, 'setname', ['run', num2str(run), 'session', num2str(session)],'gui','off'); 

                processed_sets = [processed_sets, CURRENTSET];


                % create vector with uncertainty value at each time point of Y (same size)
                % with uncertainty relating to current, or each of the
                % previous 3 samples (one per column)
                uncert_tmp = zeros(size(EEG.data, 2), 4);
                % current sample
                for cue_idx = 1:length(evn_cue_idx_50Hz(1:end))
                    uncert_tmp(evn_cue_idx_50Hz(cue_idx):evn_cue_idx_50Hz(cue_idx)+20, 1) = -abs(prior(cue_idx));
                end

                % one sample before
                for cue_idx = 2:length(evn_cue_idx_50Hz(1:end))
                    uncert_tmp(evn_cue_idx_50Hz(cue_idx):evn_cue_idx_50Hz(cue_idx)+20, 2) = -abs(prior(cue_idx-1));
                end


                % two samples before
                for cue_idx = 3:length(evn_cue_idx_50Hz(1:end))
                    uncert_tmp(evn_cue_idx_50Hz(cue_idx):evn_cue_idx_50Hz(cue_idx)+20, 3) = -abs(prior(cue_idx-2));
                end

                % three samples before
                for cue_idx = 4:length(evn_cue_idx_50Hz(1:end))
                    uncert_tmp(evn_cue_idx_50Hz(cue_idx):evn_cue_idx_50Hz(cue_idx)+20, 4) = -abs(prior(cue_idx-3));
                end


                % during choice trials fill uncertainty with the
                % uncertainty just before
                for del = 1:4
                    for rs_idx = 1:length(evn_choicetrial_idx_50Hz)
                        uncert_tmp(evn_choicetrial_idx_50Hz(rs_idx):evn_choicetrial_idx_50Hz(rs_idx)+100, del) = uncert_tmp(evn_choicetrial_idx_50Hz(rs_idx)-1, del);
                    end
                end

                uncertainty = [uncertainty; uncert_tmp]; 

            end
        end

        % merge datasets from different runs
        EEG = pop_mergeset( ALLEEG, processed_sets, 0);
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'gui','off'); 

        %% specify models for unfold
        % 4 - choice trial
        cfg = [];
        cfg.formula = {'y ~ 1'};
        cfg.eventtypes = {'4',};
        cfg.timelimits = [-5, 15]; % time window
        EEG = uf_designmat(EEG,cfg);
        
        % run model & plot results
        % run('init_unfold.m') % start toolbox
        EEG = uf_designmat(EEG,cfg); % create design matrix
        EEG = uf_timeexpandDesignmat(EEG,cfg); % time-expand design matrix
        
        X_designmat = EEG.unfold.Xdc;

        for del =1:4
            % add uncertainty predictor at the end of the design matrix
            EEG.unfold.Xdc = [X_designmat, uncertainty(:, del)];
    
            % blank out the design matrix when pupil was interpolated for
            % periods of over 1s
            pupil_interp = EEG.data(6, :);
            pupil_interp_regions = diff(pupil_interp);
    
            pinterp_start = find(pupil_interp_regions == 1);
            pinterp_end = find(pupil_interp_regions == -1);
    
            if pinterp_start(1) > pinterp_end(1)
                pinterp_start = [0, pinterp_start];
            end
    
            if pinterp_start(end) > pinterp_end(end)
                pinterp_end(end+1) = 0;
            end
    
            pinterp_length = pinterp_end-pinterp_start;
            long_interp = find(pinterp_length > 50);
    
            for art = long_interp
                EEG.unfold.Xdc(pinterp_start(art)+1:pinterp_end(art)+1, :) = 0;
            end
 
            % solve the linear model
            CHANNEL = 1;
            % EEG = uf_glmfit(EEG,'channel', CHANNEL);
            EEG = uf_glmfit_difftimelimits(EEG,'channel', CHANNEL); % changed to be able to define different time limits per predictor
            
            % ufresult = uf_condense(EEG);
            % 
            % 
            % figure; plot(EEG.unfold.times, EEG.unfold.beta_dc(1, 1:1000))
            % figure; plot(EEG.unfold.times, EEG.unfold.beta_dc(1, 1001:2000), 'k'); 
            % hold on
            % plot(EEG.unfold.times, EEG.unfold.beta_dc(1, 2001:3000), 'r');
    
            beta_choice{grp}(sbj, :, del) = squeeze(EEG.unfold.beta_dc(1, 1:1000));
            beta_uncertainty{grp}(sbj, del) = EEG.unfold.beta_dc(1, 1001);
    
    
            % calculate Pearson correlation coefficients between uncertainty and pupil
            % exclude interpolated data of more than 1 s and beginning and end
            % of recordings
            % exclude choice trials from onset to 5 s after
            pupil_data = EEG.data(1, :);
            uncertainty4corr = uncertainty(:, del);

            % find latencies for choice trials
            choice_latency = []; todelete = [];
            for evn = 1:length(EEG.event)
                if strcmp(EEG.event(evn).type, '4')
                    choice_latency = [choice_latency; round(EEG.event(evn).latency)];
                    todelete = [todelete, round(EEG.event(evn).latency):round(EEG.event(evn).latency)+EEG.srate*5];
                end
            end
 
            for art = long_interp
                todelete = [todelete, pinterp_start(art)+1:pinterp_end(art)+1];
            end
    
            pupil_data(todelete) = [];
            uncertainty4corr(todelete) = [];
    
            pupil_data(uncertainty4corr == 0) = [];
            uncertainty4corr(uncertainty4corr == 0) = [];
    
            R_corr_pupil = corrcoef(pupil_data, uncertainty4corr);
    
            Corr_pupil_uncert{grp}(sbj, del) = R_corr_pupil(2, 1);

        end                     
    end
end

save_dir = [pwd, filesep, 'pupil_deconv_unfold\choice_uncertainty_4lags'];
mkdir(save_dir)
cd(save_dir)

save beta_choice beta_choice
save beta_uncertainty beta_uncertainty
save Corr_pupil_uncert Corr_pupil_uncert


%% match with accuracy and global cognition score
% open cog data calculated in D:\Project_LC_fMRI\analyses\cognition\overall_cognitive_score.m
save_dir = [pwd, filesep, 'pupil_deconv_unfold\choice_uncertainty_4lags'];
cd(save_dir)
load beta_uncertainty; load Corr_pupil_uncert;

dir_cog = 'D:\Project_LC_fMRI\analyses\cognition\';
cog_data_file = 'overal_cog_score_visit1.xlsx';
Tcog = readtable([dir_cog, cog_data_file]);

Tcorr_uncert_cog = Tcog;

for ln = 1:length(Tcorr_uncert_cog.ParticipantID)
    for grp = 1:2
        for s = 1:length(group{grp})
            if strcmp(group{grp}(s), Tcorr_uncert_cog.ParticipantID(ln))

                Tcorr_uncert_cog.coefuncert1(ln) = beta_uncertainty{grp}(s, 1);
                Tcorr_uncert_cog.coefuncert2(ln) = beta_uncertainty{grp}(s, 2);
                Tcorr_uncert_cog.coefuncert3(ln) = beta_uncertainty{grp}(s, 3);
                Tcorr_uncert_cog.coefuncert4(ln) = beta_uncertainty{grp}(s, 4);

                Tcorr_uncert_cog.corruncert1(ln) = Corr_pupil_uncert{grp}(s, 1);
                Tcorr_uncert_cog.corruncert2(ln) = Corr_pupil_uncert{grp}(s, 2);
                Tcorr_uncert_cog.corruncert3(ln) = Corr_pupil_uncert{grp}(s, 3);
                Tcorr_uncert_cog.corruncert4(ln) = Corr_pupil_uncert{grp}(s, 4);
            end
        end
    end
end


[R, Pvalue] = corrcoef(Tcorr_uncert_cog.InfAccuracy(Tcorr_uncert_cog.Group == 1), Tcorr_uncert_cog.corruncert1(Tcorr_uncert_cog.Group == 1))

[R, Pvalue] = corrcoef(Tcorr_uncert_cog.InfAccuracy(Tcorr_uncert_cog.Group == 2), Tcorr_uncert_cog.corruncert1(Tcorr_uncert_cog.Group == 2))


[R, Pvalue] = corrcoef(Tcorr_uncert_cog.overall_cog_score(Tcorr_uncert_cog.Group == 1), Tcorr_uncert_cog.corruncert3(Tcorr_uncert_cog.Group == 1))
[R, Pvalue] = corrcoef(Tcorr_uncert_cog.overall_cog_score(Tcorr_uncert_cog.Group == 2), Tcorr_uncert_cog.corruncert3(Tcorr_uncert_cog.Group == 2))

% figure; plot(Tcorr_uncert_cog.overall_cog_score(Tcorr_uncert_cog.Group == 1), Tcorr_uncert_cog.corruncert1(Tcorr_uncert_cog.Group == 1), 'ok')
% figure; plot(Tcorr_uncert_cog.overall_cog_score(Tcorr_uncert_cog.Group == 2), Tcorr_uncert_cog.corruncert1(Tcorr_uncert_cog.Group == 2), 'dr'); lsline
% 
% figure; plot(Tcorr_uncert_cog.InfAccuracy, Tcorr_uncert_cog.corruncert1, 'o')


%% correlation between regression coefficient and cognitive score
figure;
plot(Tcorr_uncert_cog.overall_cog_score(Tcorr_uncert_cog.Group == 2), Tcorr_uncert_cog.coefuncert3(Tcorr_uncert_cog.Group == 2), 'd',...
    'MarkerEdgeColor',[.75 0.5 0.5],'MarkerFaceColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1); 

[R,P] = corrcoef(Tcorr_uncert_cog.overall_cog_score(Tcorr_uncert_cog.Group == 2), Tcorr_uncert_cog.coefuncert3(Tcorr_uncert_cog.Group == 2))
if P(1, 2) < .05
    h1 = lsline; set(h1(1),'color',[.5 0.25 0.25], 'LineWidth', 1); 
end

hold on
plot(Tcorr_uncert_cog.overall_cog_score(Tcorr_uncert_cog.Group == 1), Tcorr_uncert_cog.coefuncert3(Tcorr_uncert_cog.Group == 1), 'o',...
    'MarkerEdgeColor', 'k','MarkerFaceColor', 'k','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(Tcorr_uncert_cog.overall_cog_score(Tcorr_uncert_cog.Group == 1), Tcorr_uncert_cog.coefuncert3(Tcorr_uncert_cog.Group == 1))
if P(1, 2) < .05
    h2 = lsline; %set(h2(1),'color','k')
end

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'Global cognition score'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Beta coefficient', 'FontSize', 28, 'FontWeight','normal')


%% correlation between correlation r and cognitive score
figure;
plot(Tcorr_uncert_cog.overall_cog_score(Tcorr_uncert_cog.Group == 2), Tcorr_uncert_cog.corruncert3(Tcorr_uncert_cog.Group == 2), 'd',...
    'MarkerEdgeColor',[.75 0.5 0.5],'MarkerFaceColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1); 

[R,P] = corrcoef(Tcorr_uncert_cog.overall_cog_score(Tcorr_uncert_cog.Group == 2), Tcorr_uncert_cog.corruncert3(Tcorr_uncert_cog.Group == 2))
if P(1, 2) < .05
    h1 = lsline; set(h1(1),'color',[.5 0.25 0.25]); 
end

hold on
plot(Tcorr_uncert_cog.overall_cog_score(Tcorr_uncert_cog.Group == 1), Tcorr_uncert_cog.corruncert3(Tcorr_uncert_cog.Group == 1), 'o',...
    'MarkerEdgeColor', 'k','MarkerFaceColor', 'k','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(Tcorr_uncert_cog.overall_cog_score(Tcorr_uncert_cog.Group == 1), Tcorr_uncert_cog.corruncert3(Tcorr_uncert_cog.Group == 1))
if P(1, 2) < .05
    h2 = lsline; %set(h2(1),'color','k')
end

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'Global cognition (z-score)'}, 'FontSize', 28, 'FontWeight','normal')
ylabel({'Pupil-uncertainty', 'correlation {\it r}'}, 'FontSize', 28, 'FontWeight','normal')

%% save data in excel for repeated measures and match with accuracy
addpath('D:\Project_LC_fMRI\analyses')
group = participants_included;
% save_dir = [pwd, filesep, 'pupil_deconv_unfold\choice_uncertainty_4lags'];
% cd(save_dir)
load beta_uncertainty; load Corr_pupil_uncert

beh_dir = 'D:\Project_LC_fMRI\analyses\behaviour\';
load([beh_dir, 'AccuracyTable.mat']); %D:\Project_LC_fMRI\analyses\behaviour\accuracy_from_DSet.m

Tcorr_uncert_acc = AccuracyTable;

for ln = 1:length(Tcorr_uncert_acc.SubjID)
    for grp = 1:2
        for s = 1:length(group{grp})
            if strcmp(group{grp}(s), Tcorr_uncert_acc.SubjID(ln))

                Tcorr_uncert_acc.coefuncert1(ln) = beta_uncertainty{grp}(s, 1);
                Tcorr_uncert_acc.coefuncert2(ln) = beta_uncertainty{grp}(s, 2);
                Tcorr_uncert_acc.coefuncert3(ln) = beta_uncertainty{grp}(s, 3);
                Tcorr_uncert_acc.coefuncert4(ln) = beta_uncertainty{grp}(s, 4);

                Tcorr_uncert_acc.corruncert1(ln) = Corr_pupil_uncert{grp}(s, 1);
                Tcorr_uncert_acc.corruncert2(ln) = Corr_pupil_uncert{grp}(s, 2);
                Tcorr_uncert_acc.corruncert3(ln) = Corr_pupil_uncert{grp}(s, 3);
                Tcorr_uncert_acc.corruncert4(ln) = Corr_pupil_uncert{grp}(s, 4);
            end
        end
    end
end
save_dir = [pwd, filesep, 'pupil_deconv_unfold\choice_uncertainty_4lags'];
% writetable(Tcorr_uncert_acc,[save_dir, '\pupil_uncertainty_corr.xlsx'])


%% correlation and scatter plot between correlation r and task accuracy

figure;
plot(Tcorr_uncert_acc.corruncert3(Tcorr_uncert_acc.GroupID == 2), Tcorr_uncert_acc.Accuracy(Tcorr_uncert_acc.GroupID == 2), 'd',...
    'MarkerEdgeColor',[.75 0.5 0.5],'MarkerFaceColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1); 
hold on
% [R,P] = corrcoef(Tcorr_uncert_acc.corruncert3(Tcorr_uncert_acc.GroupID == 2), Tcorr_uncert_acc.Accuracy(Tcorr_uncert_acc.GroupID == 2));
% if P(1, 2) < .05
%     lsline%h1 = lsline; set(h1(1),'color','r'); 
% end
hold on
plot(Tcorr_uncert_acc.corruncert3(Tcorr_uncert_acc.GroupID == 1), Tcorr_uncert_acc.Accuracy(Tcorr_uncert_acc.GroupID == 1), 'o',...
    'MarkerEdgeColor', 'k','MarkerFaceColor', 'k','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(Tcorr_uncert_acc.corruncert3(Tcorr_uncert_acc.GroupID == 1), Tcorr_uncert_acc.Accuracy(Tcorr_uncert_acc.GroupID == 1));
if P(1, 2) < .05
    h2 = lsline; set(h2(1),'color','k', 'LineWidth', 2);  set(h2(2),'color', [.75 .5 .5], 'LineWidth', 2); 
end

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'Pupil-uncertainty', 'correlation {\it r}'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')


[R,P] = corrcoef(Tcorr_uncert_acc.corruncert3(Tcorr_uncert_acc.GroupID == 1), Tcorr_uncert_acc.Accuracy(Tcorr_uncert_acc.GroupID == 1))
[R,P] = corrcoef(Tcorr_uncert_acc.corruncert3(Tcorr_uncert_acc.GroupID == 2), Tcorr_uncert_acc.Accuracy(Tcorr_uncert_acc.GroupID == 2))

%% correlation between deconvolution regression coefficient and accuracy
figure;
plot(Tcorr_uncert_acc.coefuncert3(Tcorr_uncert_acc.GroupID == 2), Tcorr_uncert_acc.Accuracy(Tcorr_uncert_acc.GroupID == 2), 'd',...
    'MarkerEdgeColor',[.75 0.5 0.5],'MarkerFaceColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1); 

[R,P] = corrcoef(Tcorr_uncert_acc.coefuncert3(Tcorr_uncert_acc.GroupID == 2), Tcorr_uncert_acc.Accuracy(Tcorr_uncert_acc.GroupID == 2));
if P(1, 2) < .05
    h1 = lsline; set(h1(1),'color',[.5 0.25 0.25]); 
end

hold on
plot(Tcorr_uncert_acc.coefuncert3(Tcorr_uncert_acc.GroupID == 1), Tcorr_uncert_acc.Accuracy(Tcorr_uncert_acc.GroupID == 1), 'o',...
    'MarkerEdgeColor', 'k','MarkerFaceColor', 'k','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(Tcorr_uncert_acc.coefuncert3(Tcorr_uncert_acc.GroupID == 1), Tcorr_uncert_acc.Accuracy(Tcorr_uncert_acc.GroupID == 1));
if P(1, 2) < .05
    h2 = lsline; %set(h2(1),'color','k')
end

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'Beta coefficient'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')



%% plot pupil - choice trials

x_time = -5:.02:14.998;     

% data_rs{1} = R_highlowCPP_ch{1}(:, 1:1000);
% data_rs{2} = R_highlowCPP_ch{2}(:, 1:1000);
% 
% data_btwrs{1} = R_highlowCPP_ch{1}(:, 1001:2000);
% data_btwrs{2} = R_highlowCPP_ch{2}(:, 1001:2000);


% % sig difference across groups
% [pval, t_orig, crit_t] = mult_comp_perm_t2(data_bsl{1,1}, data_bsl{2,1});
% sig_time = find(pval < .05); % figure; plot(t_orig)

figure;
data_mean = mean(beta_choice{1}, 1);
data_se = std(beta_choice{1}, [], 1)/sqrt(size(beta_choice{1}, 1));

plot(x_time, data_mean, 'k')
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, 'k', 'k', 1, 0.25)
hold on

data_mean = mean(beta_choice{2}, 1);
data_se = std(beta_choice{2}, [], 1)/sqrt(size(beta_choice{2}, 1));

plot(x_time, data_mean, '--r')
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, 'r', 'r', 1, 0.25)
hold on

% % plot sig times
% if ~isempty(sig_time)
%     plot(x_time(sig_time), ones(length(sig_time), 1)*(-.001), 's', 'color', 'k', 'MarkerFaceColor','k');
% 
% end

plot(x_time, zeros(length(x_time), 1), '--k')
hold on

plot([0 0], [-.07 .12], '--k')
hold off
ax = gca; box off
ax.LineWidth = 2.5; 
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';  %  ylim padded
axis([-inf inf -.07 .12])
xlabel('Time (s)', 'FontSize', 24, 'FontWeight','normal')
ylabel('Pupil (% mean)', 'FontSize', 24, 'FontWeight','normal')
%     title(var_data(var), 'FontSize', 24, 'FontWeight','normal')
     


%% plot uncertainty
% save_dir = [pwd, filesep, 'pupil_deconv_unfold\choice_uncertainty_4lags\'];
% load([save_dir,  'beta_uncertainty'])

% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
plot_2groups_errorbars(beta_uncertainty{1}, beta_uncertainty{2}, 'Coefficient',...
    {'', '', '', ''}, [1.5, 4.5, 7.5, 10.5], '')
yline(0, '--k', 'LineWidth', 1.5)
% axis([0 3 -inf inf]);
ylim padded
% x0=10;
% y0=10;
% width=300;
% height=400;
% set(gcf,'position',[x0,y0,width,height])

[h,p,ci,stats] = ttest2(beta_uncertainty{1}, beta_uncertainty{2})


%% plot uncertainty - pearson correlation
% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
plot_2groups_errorbars(Corr_pupil_uncert{1}, Corr_pupil_uncert{2}, 'Correlation {\it r}', {'', '', '', ''}, [1.5, 4.5, 7.5, 10.5], '')
yline(0, '--k', 'LineWidth', 1.5)
% axis([0 3 -inf inf]);
ylim padded
% x0=10;
% y0=10;
% width=300;
% height=400;
% set(gcf,'position',[x0,y0,width,height])

[h,p,ci,stats] = ttest2(Corr_pupil_uncert{1}, Corr_pupil_uncert{2})

[h,p,ci,stats] = ttest(Corr_pupil_uncert{1})
[h,p,ci,stats] = ttest(Corr_pupil_uncert{2})



%% plot cpp and uncertainty aligned with rule switch
save_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches';
cd(save_dir)
load cpp_ruleswitch
load uncertainty_ruleswitch

x_time = -12:37;
   
figure;
data_mean = mean([cpp_ruleswitch{1}; cpp_ruleswitch{2}], 1);
data_se = std([cpp_ruleswitch{1}; cpp_ruleswitch{2}], [], 1)/sqrt(size([cpp_ruleswitch{1}; cpp_ruleswitch{2}], 1));
yyaxis left
plot(x_time, data_mean,  'ok', 'LineWidth', 2)
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, 'k', 'k', 1, 0.25)
hold on
ylabel('CPP', 'FontSize', 24, 'FontWeight','normal')
data_mean = mean([uncertainty_ruleswitch{1}; uncertainty_ruleswitch{2}], 1);
data_se = std([uncertainty_ruleswitch{1}; uncertainty_ruleswitch{2}], [], 1)/sqrt(size([uncertainty_ruleswitch{1}; uncertainty_ruleswitch{2}], 1));
yyaxis right
plot(x_time, data_mean, 'd', 'color', [0.6350 0.0780 0.1840], 'LineWidth', 2)
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, [0.6350 0.0780 0.1840], [0.6350 0.0780 0.1840], 1, 0.25)
hold on

% plot(x_time, zeros(length(x_time), 1), '--k')
hold on
plot([0 0], [-3.5 -1], '--k')
hold off
ax = gca; box off
c = ax.Color;
axis([-12 37 -inf inf])
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';
ax.YAxis(1).Color = 'k';
ax.YAxis(2).Color = [0.6350 0.0780 0.1840];
xlabel('Peri rule-switch samples', 'FontSize', 24, 'FontWeight','normal')
ylabel('Uncertainty', 'FontSize', 24, 'FontWeight','normal')


% uncertainty at time of rule swicth versus uncertainty three samples before

[h,p,ci,stats] = ttest([uncertainty_ruleswitch{1}(:, 11); uncertainty_ruleswitch{2}(:, 11)], [uncertainty_ruleswitch{1}(:, 12); uncertainty_ruleswitch{2}(:, 12)])


[h,p,ci,stats] = ttest([cpp_ruleswitch{1}(:, 12); cpp_ruleswitch{2}(:, 12)], [cpp_ruleswitch{1}(:, 8); cpp_ruleswitch{2}(:, 8)])


%% aux functions
% median split
function median_split(data, sorting_variable, title_text)
    data_size = size(data, 2);
    data(:, end+1) = sorting_variable';
    data_sorted = data;
    data_sorted = sortrows(data_sorted, size(data_sorted, 2));

    data_sorted_m1 = data_sorted(1:floor(size(data_sorted, 1)/2), 1:data_size);
    data_sorted_m2 = data_sorted(floor(size(data_sorted, 1)/2)+1:end, 1:data_size);

    mean_median_split(1, :) = mean(data_sorted_m1, 1);
    mean_median_split(2, :) = mean(data_sorted_m2, 1);

    se_median_split(1, :) = std(data_sorted_m1,[], 1)/sqrt(size(data_sorted_m1, 1));
    se_median_split(2, :) = std(data_sorted_m2,[], 1)/sqrt(size(data_sorted_m2, 1));


    colormap hot;
    cmap = colormap;
    
    figure;
    xaxis = -199:2:1500;
    for q = 1:2
        plot(xaxis, mean_median_split(q, :), 'LineWidth', 1.5, 'color', cmap(10*q,:)); hold on
        jbfill(xaxis, mean_median_split(q, :)+se_median_split(q, :), mean_median_split(q, :)-se_median_split(q, :), cmap(10*q,:),cmap(10*q,:), 0.1)
        hold on;
    end
    % zero line
    hold on
    plot(xaxis, zeros(length(xaxis)), 'k:');
    hold off
    ax = gca;
%     legend('q1', 'q2', 'q3', 'q4', 'q5');
    ax.FontSize = 20; ax.FontName = 'Times New Roman'; ax.Color = 'none';
    axis([-200 1500 -inf inf])
    xlabel('Time (ms)', 'FontSize', 28, 'FontWeight','normal')
    ylabel({'Pupil size (%)'}, 'FontSize', 28, 'FontWeight','normal')
    title(title_text, 'FontSize', 18, 'FontWeight','normal')
    
    data_sorted_mean_epoch_m1 = mean(data_sorted_m1, 2); % average value in epoch
    data_sorted_mean_epoch_m2 = mean(data_sorted_m2, 2);
    
    mean_per_epoch_median_split(1, :) = mean(data_sorted_mean_epoch_m1, 1)*100;
    mean_per_epoch_median_split(2, :) = mean(data_sorted_mean_epoch_m2, 1)*100;

    se_per_epoch_median_split(1, :) = std(data_sorted_mean_epoch_m1,[], 1)/sqrt(size(data_sorted_mean_epoch_m1, 1))*100;
    se_per_epoch_median_split(2, :) = std(data_sorted_mean_epoch_m2,[], 1)/sqrt(size(data_sorted_mean_epoch_m2, 1))*100;

    figure;
    e = errorbar(1:2,mean_per_epoch_median_split,se_per_epoch_median_split, 'LineWidth', 2);
    e.Color = 'k';
    ax = gca;
    ax.FontSize = 20; ax.FontName = 'Times New Roman'; ax.Color = 'none';
    axis([0 3 -3.8 1.5])
    set(gca,'xtick',[1:5],'xticklabel','')
%     xlabel('Median split', 'FontSize', 28, 'FontWeight','normal')
    ylabel({'Pupil size (%)'}, 'FontSize', 28, 'FontWeight','normal')
    title(title_text, 'FontSize', 18, 'FontWeight','normal')

end


%% function plot data 2 groups 1 task
function plot_all_data_2groups(data_grp1, data_grp2, y_label_text, title_text)
       figure;
    % plot data for group 1
    yMean=mean(data_grp1, 'omitnan');
    y_se = std(data_grp1, 'omitnan')/sqrt(length(data_grp1(~isnan(data_grp1))));
    
        %plot the mean+-SEM box
        %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
%   Specify pos as a four-element vector of the form [x y w h] in data
%   units. The x and y elements determine the location and the w and h
%   elements determine the size. The function plots into the current axes
%   without clearing existing content from the axes.
    box off
    rectangle('Position',[1-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    hold on
    for y=1:length(data_grp1)
        plot(1+rand*0.2-0.1, data_grp1(y),'-o', 'color', [.8 .8 .8], ...
            'MarkerEdgeColor','k','MarkerSize',12, 'LineWidth', 1.5);
        hold on;
    end
    %plot line at zero    
    plot([0 3],[0 0],'--k','LineWidth', 1);
     %plot the mean line    
    plot([1-0.3 1+0.3],[yMean yMean] ,'Color','k','LineWidth',5);
   

    % group 2
    yMean=mean(data_grp2, 'omitnan');
    y_se = std(data_grp2, 'omitnan')/sqrt(length(data_grp2(~isnan(data_grp2))));
   rectangle('Position',[2-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1)
   
    for y=1:length(data_grp2)
        plot(2+rand*0.2-0.1, data_grp2(y) ,'-o',  'color', [1 .5 .5], ...
            'MarkerEdgeColor','k','MarkerSize',12, 'LineWidth', 1.5);
        hold on;
    end

    %plot the mean line
    plot([2-0.3 2+0.3],[yMean yMean] ,'Color','k','LineWidth',5);
    

    % axes('XColor','none');
    hold off;
    if strcmp(title_text, 'Run')
        axis([0 3 -inf 6]);
    elseif strcmp(title_text, 'Time-on-task')
        axis([0 3 -inf .2]);
    elseif strcmp(title_text, 'Alpha power')
        axis([0 3 -inf 10]);
    else
        axis([0 3 -inf inf]);
    end
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
%     ax.XTickLabel= [];
    ax.XAxis.FontSize = 30;
    ax.XTickLabel= {'' 'Young' 'Older' ''};
%     xticks([1 2])
    ylabel(y_label_text, 'FontSize', 30, 'FontWeight','normal')
    title(title_text, 'FontSize', 32, 'FontWeight','normal')

%     x0=10;
%     y0=10;
%     width=400;
%     height=400;
%     set(gcf,'position',[x0,y0,width,height])
end


%%
function plot_2groups_errorbars(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% data with observations x variables
    figure;
    % plot data for group 1
    yMean1=nanmean(data_grp1, 1);
    y_se1 = std(data_grp1,[], 1, 'omitnan')/sqrt(size(data_grp1, 1));
    
    pst = -2; meanpst1 = [];
    for v = 1:size(data_grp1, 2)
        pst = pst + 3;
        for y=1:size(data_grp1, 1)
            plot(pst+(rand-0.5)*0.2, data_grp1(y, v),'-o', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.75 .75 .75],'MarkerSize', 8, 'LineWidth', 1.5);
            hold on;
        end

        meanpst1 = [meanpst1, pst];
        % errorbar(pst, yMean(v), y_se(v),"_","MarkerSize", 25,...
        %     "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 1.5, 'color', 'k'); 
    end


    % group 2
    yMean2=nanmean(data_grp2, 1);
    y_se2 = std(data_grp2,[], 1, 'omitnan')/sqrt(size(data_grp2, 1));
    
    pst = -1; meanpst2 = [];
    for v = 1:size(data_grp2, 2)
        pst = pst + 3;

        for y=1:size(data_grp2, 1)
            plot(pst+(rand-0.5)*0.2, data_grp2(y, v),'-d', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.75 0.5 0.5],'MarkerSize',8, 'LineWidth', 1.5);
            hold on;
        end

        meanpst2 = [meanpst2, pst];

    %     errorbar(pst, yMean(v), y_se(v),"_-","MarkerSize",25,...
    % "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 1.5, 'color', 'k')
    end


    errorbar(meanpst1, yMean1, y_se1,"-k", 'LineWidth', 1.5); 
    errorbar(meanpst2, yMean2, y_se2,"-", 'LineWidth', 1.5, 'Color',[.4 0.15 0.15]); 

    hold off;     box off
%     axis([0 3 -inf inf]);
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    ax.XTickLabel= [];
    ax.XAxis.FontSize = 24;
    xticks(x_ticks);
    ax.XTickLabel= x_label_text;
    xtickangle(90)
    ylabel(y_label_text, 'FontSize', 28, 'FontWeight','normal')
    title(title_text, 'FontSize', 24, 'FontWeight','normal')

%     x0=10;
%     y0=10;
%     width=400;
%     height=400;
%     set(gcf,'position',[x0,y0,width,height])
end