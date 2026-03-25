% run on server  graphs on computer
clear; close all

addpath('/DATAPOOL/home/mribeiro/matlab_toolboxes/eeglab2023.0/');

group = participants_included;

task_pupil_dir = [pwd, filesep, 'preprocessed_pupil_files'];
S = dir(task_pupil_dir);

% find which participants have pupil data for inference-only task
subj_infonly = {};
for f = 3:length(S)
    if str2num(S(f).name(13)) == 4
        subj_infonly = [subj_infonly; S(f).name(7:11)];
    end
end

subj_infonly = unique(subj_infonly);

group_infonly{1} = intersect(subj_infonly, group{1});
group_infonly{2} = intersect(subj_infonly, group{2});



% open eeglab
[ALLEEG EEG, CURRENTSET ALLCOM] = eeglab;


R_highlowCPP_ch_full_inf = cell(2, 2); 

for grp = 1:2
    for sbj = 1:length(group_infonly{grp})
        close all
        subject = char(group_infonly{grp}(sbj));

        % each subject has at least one session outside the scanner (sessions 1 and 2) and one inside
        % the scanner (session 3)
        % some participants also have outside the scanner four runs of
        % inference-only task saved as session 4
        S = dir([pwd, filesep 'ET_data', filesep, char(subject)]);
        sessions = []; % sessions = sum([S(~ismember({S.name},{'.','..'})).isdir]);
        for f = 1:length(S)
            if contains(S(f).name, 'session')
                sessions = [sessions, str2num(S(f).name(8))];
            end
        end

        b=0; condition = []; cpp_ruleswitch_tmp         = []; uncertainty_ruleswitch_tmp = []; number_highlowcpp_rs_tmp = [];
        clear sample_genside

        Y = cell(2, 1); X_highcpp = cell(2, 1); X_lowcpp = cell(2, 1); X_choice = cell(2, 1);
        n_rs_events = 0; n_btwrs_events = 0; n_choice_events = 0;

        rs_lockedwithruleswitch = [];
        for session = sessions
            % pupil preprocessed + gaze position
            % 1 - in the lab; 2 - in the MRI scanner; 3 -
            % inference-only task in the lab
            cond = [];
            if ismember(session, [1, 2]) % in the lab - hierarchical decisions task
                condition = [condition, 1];
                cond = 1; task = 1;
            elseif session == 3 % in the scanner - hierarchical decisions task
                condition = [condition, 2];
                cond = 2;
                continue
            elseif session == 4 % inference only in the lab
                condition = [condition, 3];
                cond = 3; task = 2;
            end
            
            folder_session = [pwd, filesep, 'ET_data', filesep, char(subject), filesep, 'session', num2str(session)];
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
                
%                 figure; plot(CPP); hold on; plot(sample_genside)
                
                % CPP thresholds determined to equalize number of events
                % with number of rule switches - D:\Project_LC_fMRI\analyses\pupil\uncertainty_according2rule_switches_CPP.m
                CPP_highthreshold = find(CPP > 0.0775);
                CPP_lowthreshold = find(CPP < 0.000825);
                
                %% clear eeglab
                STUDY = []; CURRENTSTUDY = 0; ALLEEG = []; EEG=[]; CURRENTSET=[];
                % load pupil data
                EEG = pop_loadset('filename',['pupil_', char(subject), '_',num2str(session), '_', num2str(run), '.set'],'filepath', task_pupil_dir);
                [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);

%                 % create events for rule switches
%                 % eventstruct = importevent( event, oldevent, srate, 'key1', 'value1', ...);
                cues_latency = [];
                for evn = 1:length(EEG.event)
                    if EEG.event(evn).type == 1 %|| EEG.event(evn).type == 4
                        cues_latency = [cues_latency; EEG.event(evn).latency];
                    end
                end
%                 
%                 rule_switch_latency = cues_latency(rule_switch);
%                 evn_rule_switches = [ones(length(rule_switch_latency), 1) * 5, rule_switch_latency];
%                 
%                 % create event in between two true switchs for comparison - 6
%                 mid_rule_switch_latency = [];
%                 for r = 1:length(rule_switch)-1
%                     mid_rule_switch_latency(r) = cues_latency(rule_switch(r)+round((rule_switch(r+1)-rule_switch(r))/2));
%                 end
%                 
%                 evn_norule_switches = [ones(length(mid_rule_switch_latency), 1) * 6, mid_rule_switch_latency'];
%                 

               % create events for high CPPs = 7
                cpp_latency = cues_latency(CPP_highthreshold);
                evn_cpp = [ones(length(cpp_latency), 1) * 7, cpp_latency];
                
                % low cpp events = 8
                lowcpp_latency = cues_latency(CPP_lowthreshold);
                evn_lowcpp = [ones(length(lowcpp_latency), 1) * 8, lowcpp_latency];
                
                evn_cpp_all = [evn_cpp; evn_lowcpp];
                
               % add cue events 5 if there was a switch in the generative distribution
               % add cue events 6 for a cue in between rule switches
               % add cue events 7 if there was a large CPP value
               % add cue events 8 if there was a low CPP value

               
                % to ensure that if CPP falls on rule switch it is not
                % overwritten use this instead
                EEG = eeg_checkset( EEG );
                EEG = pop_importevent( EEG, 'event', evn_cpp_all,'fields',{'type','latency'},'timeunit',NaN,'align',0,'optimalign','off');
                [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);
                
                % downsample pupil to 50 Hz
                nanidx_chn = EEG.data(6, :);
                EEG = eeg_checkset( EEG );
                EEG = pop_resample( EEG, 50);
                [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 

                evn_highcpp_idx_50Hz = [];
                evn_lowcpp_idx_50Hz = [];
                evn_choicetrial_idx_50Hz = [];
                for e = 1:length(EEG.event)
                    if EEG.event(e).type == 7
                        evn_highcpp_idx_50Hz = [evn_highcpp_idx_50Hz; round(EEG.event(e).latency)];
                    elseif EEG.event(e).type == 8
                        evn_lowcpp_idx_50Hz = [evn_lowcpp_idx_50Hz; round(EEG.event(e).latency)];
                    elseif EEG.event(e).type == 4
                        evn_choicetrial_idx_50Hz = [evn_choicetrial_idx_50Hz; round(EEG.event(e).latency)];
                    end
                end

                
                %% deconvolution of rule switch responses - from 5 s before
                % to 10 s after
                Y{task} = [Y{task}; EEG.data(1, :)']; epoch_idx = -250:749;
                
               % deconvolution high cpp - from 5 s
               % before to 10s after event
                X_tmp = zeros(size(EEG.data, 2), 15*EEG.srate);
                for rs_idx = 1:size(evn_highcpp_idx_50Hz, 1)
                   if evn_highcpp_idx_50Hz(rs_idx) > abs(epoch_idx(1)) && evn_highcpp_idx_50Hz(rs_idx)< length(EEG.data(1, :))-epoch_idx(end)
                       for ep_idx = 1:length(epoch_idx)
                           X_tmp(evn_highcpp_idx_50Hz(rs_idx)+epoch_idx(ep_idx), ep_idx) = 1;
                       end
                   end
                end
                
                X_highcpp{task} = [X_highcpp{task}; X_tmp];
                
               % deconvolution low cpp - from 5 s
               % before to 10s after event
                X_tmp = zeros(size(EEG.data, 2), 15*EEG.srate);
                for rs_idx = 1:size(evn_lowcpp_idx_50Hz, 1)
                   if evn_lowcpp_idx_50Hz(rs_idx) > abs(epoch_idx(1)) && evn_lowcpp_idx_50Hz(rs_idx)< length(EEG.data(1, :))-epoch_idx(end)
                       for ep_idx = 1:length(epoch_idx)
                           X_tmp(evn_lowcpp_idx_50Hz(rs_idx)+epoch_idx(ep_idx), ep_idx) = 1;
                       end
                   end
                end
                
                X_lowcpp{task} = [X_lowcpp{task}; X_tmp];
                

                % choice events
                X_tmp = zeros(size(EEG.data, 2), 15*EEG.srate); 
                for rs_idx = 1:size(evn_choicetrial_idx_50Hz, 1)
                   if evn_choicetrial_idx_50Hz(rs_idx) > abs(epoch_idx(1)) && evn_choicetrial_idx_50Hz(rs_idx)< length(EEG.data(1, :))-epoch_idx(end)
                       n_choice_events = n_choice_events + 1;
                       for ep_idx = 1:length(epoch_idx)
                           X_tmp(evn_choicetrial_idx_50Hz(rs_idx)+epoch_idx(ep_idx), ep_idx) = 1;
                       end
                   end
                end

                X_choice{task} = [X_choice{task}; X_tmp];
%                 
            end
        end
        
        for tsk = 1:2
            % include high CPP, low CPP, choice trials
            X_cpp = [X_highcpp{tsk}, X_lowcpp{tsk}, X_choice{tsk}];
            X_pinv = pinv(X_cpp);
            R_highlowCPP_ch_full_inf{grp, tsk} = [R_highlowCPP_ch_full_inf{grp, tsk}; (X_pinv * Y{tsk})'];
        end
        
        clear X_highcpp X_lowcpp X_choice X_cpp X_pinv
        
        

    end
end


% figure; plot(epoch_idx, mean(R{1}, 1))
% hold on
% plot(epoch_idx, mean(R{2}, 1))
   

save_dir = [pwd, filesep, 'pupil_cpp_deconv_inf_full'];
mkdir(save_dir)
cd(save_dir)

save R_highlowCPP_ch_full_inf R_highlowCPP_ch_full_inf

%% plot pupil - choice trials
data_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_cpp_deconv_inf_full';

load([data_dir , filesep, 'R_highlowCPP_ch_full_inf']); 

x_time = -5:.02:14.998;     

for t = 1:2

% data_rs{1} = R_highlowCPP_ch{1}(:, 1:1000);
% data_rs{2} = R_highlowCPP_ch{2}(:, 1:1000);
% 
% data_btwrs{1} = R_highlowCPP_ch{1}(:, 1001:2000);
% data_btwrs{2} = R_highlowCPP_ch{2}(:, 1001:2000);

data_ch{1} = R_highlowCPP_ch_full_inf{1, t}(:, 2001:3000);
data_ch{2} = R_highlowCPP_ch_full_inf{2, t}(:, 2001:3000);

% % sig difference across groups
% [pval, t_orig, crit_t] = mult_comp_perm_t2(data_bsl{1,1}, data_bsl{2,1});
% sig_time = find(pval < .05); % figure; plot(t_orig)

figure;
data_mean = mean(data_ch{1}, 1);
data_se = std(data_ch{1}, [], 1)/sqrt(size(data_ch{1}, 1));

plot(x_time, data_mean, 'k')
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, 'k', 'k', 1, 0.25)
hold on

data_mean = mean(data_ch{2}, 1);
data_se = std(data_ch{2}, [], 1)/sqrt(size(data_ch{2}, 1));

plot(x_time, data_mean, '--r')
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, 'r', 'r', 1, 0.25)
hold on

% % plot sig times
% if ~isempty(sig_time)
%     plot(x_time(sig_time), ones(length(sig_time), 1)*(-.001), 's', 'color', 'k', 'MarkerFaceColor','k');
% 
% end

xline(0, '--')
yline(0, '--')
hold off
ax = gca; box off; ax.LineWidth = 2.5; 
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';  %  ylim padded
axis([-inf inf -.1 .12])
xlabel('Time (s)', 'FontSize', 32, 'FontWeight','normal')
ylabel('Pupil (%)', 'FontSize', 32, 'FontWeight','normal')
%     title(var_data(var), 'FontSize', 24, 'FontWeight','normal')
     
end

%% plot pupil - high cpp responses
data_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_cpp_deconv_inf_full';

load([data_dir , filesep, 'R_highlowCPP_ch_full_inf']); 


% highlight time windows where there was a significant group x condition
% interaction in the full task using teh whole sample
% load mask 
mask_dir = 'D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil_ruleswitch_deconv3events\level2_RM_ANOVA_pupil_grp_highlowCPP';
load([mask_dir, filesep, 'mask_interaction.mat']);

sig_time = find(mask > 0);


x_time = -5:.02:14.998;     

for t = 1:2

% data_rs{1} = R_highlowCPP_ch{1}(:, 1:1000);
% data_rs{2} = R_highlowCPP_ch{2}(:, 1:1000);
% 
% data_btwrs{1} = R_highlowCPP_ch{1}(:, 1001:2000);
% data_btwrs{2} = R_highlowCPP_ch{2}(:, 1001:2000);

data_ch{1} = R_highlowCPP_ch_full_inf{1, t}(:, 1:1000);
data_ch{2} = R_highlowCPP_ch_full_inf{2, t}(:, 1:1000);

% % sig difference across groups
% [pval, t_orig, crit_t] = mult_comp_perm_t2(data_bsl{1,1}, data_bsl{2,1});
% sig_time = find(pval < .05); % figure; plot(t_orig)

figure;
data_mean = mean(data_ch{1}, 1);
data_se = std(data_ch{1}, [], 1)/sqrt(size(data_ch{1}, 1));

plot(x_time, data_mean, 'k')
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, 'k', 'k', 1, 0.25)
hold on

data_mean = mean(data_ch{2}, 1);
data_se = std(data_ch{2}, [], 1)/sqrt(size(data_ch{2}, 1));

plot(x_time, data_mean, '--r')
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, 'r', 'r', 1, 0.25)
hold on

% plot sig times
if ~isempty(sig_time)
    plot(x_time(sig_time), ones(length(sig_time), 1)*(-.015), 's', 'color', 'k', 'MarkerFaceColor','k');

end

xline(0, '--')
yline(0, '--')
hold off
ax = gca; box off; ax.LineWidth = 2.5; 
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';  %  ylim padded
axis([-inf inf -.02 .022])
xlabel('Time (s)', 'FontSize', 32, 'FontWeight','normal')
ylabel('Pupil (%)', 'FontSize', 32, 'FontWeight','normal')
%     title(var_data(var), 'FontSize', 24, 'FontWeight','normal')
     
end
