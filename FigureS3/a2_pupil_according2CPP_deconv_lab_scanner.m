% run on server  graphs on computer
clear; close all

addpath('/DATAPOOL/home/mribeiro/matlab_toolboxes/eeglab2023.0/');


group = participants_included;

task_pupil_dir = [pwd, filesep, 'preprocessed_pupil_files'];
S = dir(task_pupil_dir);

% open eeglab
[ALLEEG EEG, CURRENTSET ALLCOM] = eeglab;


R_highlowCPP_ch_cond = cell(2); 

for grp = 1:2
    for sbj = 1:length(group{grp})
        close all
        subject = char(group{grp}(sbj));

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

        b=0; condition = []; cpp_ruleswitch_tmp  = []; uncertainty_ruleswitch_tmp = []; number_highlowcpp_rs_tmp = [];
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
                cond = 1;
            elseif session == 3 % in the scanner - hierarchical decisions task
                condition = [condition, 2];
                cond = 2;
            elseif session == 4 % inference only in the lab
                condition = [condition, 3];
                cond = 3;
                continue
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

                % create events for CPPs
                % eventstruct = importevent( event, oldevent, srate, 'key1', 'value1', ...);
                cues_latency = [];
                for evn = 1:length(EEG.event)
                    if EEG.event(evn).type == 1 %|| EEG.event(evn).type == 4
                        cues_latency = [cues_latency; EEG.event(evn).latency];
                    end
                end

               % create events for high CPPs = 7
                cpp_latency = cues_latency(CPP_highthreshold);
                evn_cpp = [ones(length(cpp_latency), 1) * 7, cpp_latency];
                
                % low cpp events = 8
                lowcpp_latency = cues_latency(CPP_lowthreshold);
                evn_lowcpp = [ones(length(lowcpp_latency), 1) * 8, lowcpp_latency];
                
                evn_cpp_all = [evn_cpp; evn_lowcpp];
                
               % add cue events 7 if there was a large CPP value
               % add cue events 8 if there was a low CPP value

               
                % to ensure that if CPP falls on rule switch it is not
                % overwritten use this instead
                EEG = eeg_checkset( EEG );
                EEG = pop_importevent( EEG, 'event',evn_cpp_all,'fields',{'type','latency'},'timeunit',NaN,'align',0,'optimalign','off');
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
                Y{cond} = [Y{cond}; EEG.data(1, :)']; epoch_idx = -250:749;
                

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
                
                X_highcpp{cond} = [X_highcpp{cond}; X_tmp];
                
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
                
                X_lowcpp{cond} = [X_lowcpp{cond}; X_tmp];
                

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

                X_choice{cond} = [X_choice{cond}; X_tmp];
%                 
            end
        end
        
        for cond = 1:2
            if ~isempty(Y{cond})
                % include high CPP, low CPP, choice trials
                X_cpp = [X_highcpp{cond}, X_lowcpp{cond}, X_choice{cond}];
                X_pinv=pinv(X_cpp);
                R_highlowCPP_ch_cond{grp, cond} = [R_highlowCPP_ch_cond{grp, cond}; (X_pinv * Y{cond})'];
            end
        end

        
    end
end

   
save_dir = [pwd, filesep, 'pupil_cpp_deconv_lab_scanner'];
mkdir(save_dir)
cd(save_dir)

save R_highlowCPP_ch_cond R_highlowCPP_ch_cond

%% plot pupil - choice trials
save_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_cpp_deconv_lab_scanner';

load([save_dir, filesep, 'R_highlowCPP_ch_cond']); 

x_time = -5:.02:14.998;     



data_ch{1, 1} = R_highlowCPP_ch_cond{1, 1}(:, 2001:3000);
data_ch{2, 1} = R_highlowCPP_ch_cond{2, 1}(:, 2001:3000);

data_ch{1, 2} = R_highlowCPP_ch_cond{1, 2}(:, 2001:3000);
data_ch{2, 2} = R_highlowCPP_ch_cond{2, 2}(:, 2001:3000);

color_grp = {'k', [.75 0 0]};

figure;

% in the lab
data_mean = mean(data_ch{1, 1}, 1);
data_se = std(data_ch{1, 1}, [], 1)/sqrt(size(data_ch{1, 1}, 1));

plot(x_time, data_mean, 'k', 'LineWidth', 1.5)
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, 'k', 'k', 1, 0.25)
hold on

data_mean = mean(data_ch{2, 1}, 1);
data_se = std(data_ch{2, 1}, [], 1)/sqrt(size(data_ch{2, 1}, 1));

plot(x_time, data_mean, 'color', [.75 0 0], 'LineWidth', 1.5)
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, [.75 0 0], [.75 0 0], 1, 0.25)
hold on


% in the scanner
data_mean = mean(data_ch{1, 2}, 1);
data_se = std(data_ch{1, 2}, [], 1)/sqrt(size(data_ch{1, 2}, 1));

plot(x_time, data_mean, '--k', 'LineWidth', 1.5)
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, 'k', 'k', 1, 0.25)
hold on

data_mean = mean(data_ch{2, 2}, 1);
data_se = std(data_ch{2, 2}, [], 1)/sqrt(size(data_ch{2, 2}, 1));

plot(x_time, data_mean, '--', 'color', [.75 0 0], 'LineWidth', 1.5)
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, [.75 0 0], [.75 0 0], 1, 0.25)
hold on
% plot sig times
load('D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil_lab_scanner\level2_RM_ANOVA_grp_site_choice\mask_main_effect.mat')
sig_time = find(mask > 0);
if ~isempty(sig_time)
    plot(x_time(sig_time), ones(length(sig_time), 1)*(-.09), 's', 'color', 'k', 'MarkerFaceColor','k',...
            'MarkerSize', 4);
end

hold on
xline(0, '--k'); yline(0,  '--k')
hold off
ax = gca; box off; ax.LineWidth = 2.5;
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none'; %ylim padded
axis([-inf inf -.1 .12])
xlabel('Time (s)', 'FontSize', 28, 'FontWeight','normal')
ylabel('Pupil (% mean)', 'FontSize', 28, 'FontWeight','normal')
     
%% plot pupil - high CPP vs low CPP - two groups together - black and red
save_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_cpp_deconv_lab_scanner';
load([save_dir, filesep, 'R_highlowCPP_ch_cond']); 
pupil_label = {'Pupil (% mean)'};
x_time = -5:.02:14.998;     

cond = 1;

data_rs{1} = R_highlowCPP_ch_cond{1, cond}(:, 1:1000);
data_rs{2} = R_highlowCPP_ch_cond{2, cond}(:, 1:1000);

data_btwrs{1} = R_highlowCPP_ch_cond{1, cond}(:, 1001:2000);
data_btwrs{2} = R_highlowCPP_ch_cond{2, cond}(:, 1001:2000);

data_ch{1} = R_highlowCPP_ch_cond{1, cond}(:, 2001:3000);
data_ch{2} = R_highlowCPP_ch_cond{2, cond}(:, 2001:3000);

color_grp = {'k', [.75 0 0]};

figure;
for grp = 1:2

    data_mean = mean(data_rs{grp}, 1);
    data_se = std(data_rs{grp}, [], 1)/sqrt(size(data_rs{grp}, 1));

    plot(x_time, data_mean, 'color', color_grp{grp}, 'LineWidth', 1.5)
    hold on
    jbfill(x_time, data_mean + data_se, data_mean - data_se, color_grp{grp}, color_grp{grp}, 1, 0.25)
    hold on

    data_mean = mean(data_btwrs{grp}, 1);
    data_se = std(data_btwrs{grp}, [], 1)/sqrt(size(data_btwrs{grp}, 1));

    plot(x_time, data_mean, '--', 'color',  color_grp{grp}, 'LineWidth', 1.5)
    hold on
    jbfill(x_time, data_mean + data_se, data_mean - data_se, color_grp{grp}, color_grp{grp}, 1, 0.25)

    hold on
end

% plot sig times
load('D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil_lab_scanner\level2_RM_ANOVA_grp_site_CPP\mask_main_effect_2.mat')
sig_time = find(mask > 0);
if ~isempty(sig_time)
    plot(x_time(sig_time), ones(length(sig_time), 1)*(-.013), 's', 'color', 'k', 'MarkerFaceColor','k',...
            'MarkerSize', 4);
end


hold on
xline(0, '--k'); yline(0,  '--k')
hold off
ax = gca; box off; ax.LineWidth = 2.5;
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none'; %ylim padded
axis([-inf inf -.014 .018])
xlabel('Time (s)', 'FontSize', 28, 'FontWeight','normal')
ylabel('Pupil (% mean)', 'FontSize', 28, 'FontWeight','normal')
     


%% choice trials
cond = 2;

data_rs{1} = R_highlowCPP_ch_cond{1, cond}(:, 1:1000);
data_rs{2} = R_highlowCPP_ch_cond{2, cond}(:, 1:1000);

data_btwrs{1} = R_highlowCPP_ch_cond{1, cond}(:, 1001:2000);
data_btwrs{2} = R_highlowCPP_ch_cond{2, cond}(:, 1001:2000);

data_ch{1} = R_highlowCPP_ch_cond{1, cond}(:, 2001:3000);
data_ch{2} = R_highlowCPP_ch_cond{2, cond}(:, 2001:3000);

color_grp = {'k', [.75 0 0]};

figure;
for grp = 1:2

    data_mean = mean(data_rs{grp}, 1);
    data_se = std(data_rs{grp}, [], 1)/sqrt(size(data_rs{grp}, 1));

    plot(x_time, data_mean, 'color', color_grp{grp}, 'LineWidth', 1.5)
    hold on
    jbfill(x_time, data_mean + data_se, data_mean - data_se, color_grp{grp}, color_grp{grp}, 1, 0.25)
    hold on

    data_mean = mean(data_btwrs{grp}, 1);
    data_se = std(data_btwrs{grp}, [], 1)/sqrt(size(data_btwrs{grp}, 1));

    plot(x_time, data_mean, '--', 'color',  color_grp{grp}, 'LineWidth', 1.5)
    hold on
    jbfill(x_time, data_mean + data_se, data_mean - data_se, color_grp{grp}, color_grp{grp}, 1, 0.25)

    hold on
end
plot(x_time, zeros(length(x_time), 1), '--k')

hold on
xline(0, '--k'); yline(0,  '--k')
hold off
ax = gca; box off; ax.LineWidth = 2.5;
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none'; %ylim padded
axis([-inf inf -.014 .018])
xlabel('Time (s)', 'FontSize', 28, 'FontWeight','normal')
ylabel('Pupil (% mean)', 'FontSize', 28, 'FontWeight','normal')
     





%% plot pupil - high CPP vs low CPP - two groups together
save_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv';
% var_data = {'R_high_cpp_ch',...
%     'R_low_cpp_ch','R_btwrs_ch', 'R_rs_ch'};
load([save_dir, filesep, 'R_highlowCPP_ch']); 

pupil_label = {'Pupil (% mean)'};
x_time = -5:.02:14.998;     

data_rs{1} = R_highlowCPP_ch{1}(:, 1:1000);
data_rs{2} = R_highlowCPP_ch{2}(:, 1:1000);

data_btwrs{1} = R_highlowCPP_ch{1}(:, 1001:2000);
data_btwrs{2} = R_highlowCPP_ch{2}(:, 1001:2000);

data_ch{1} = R_highlowCPP_ch{1}(:, 2001:3000);
data_ch{2} = R_highlowCPP_ch{2}(:, 2001:3000);

figure;
for grp = 1:2
    if grp == 1
        lnw = 3;
    else
        lnw = 1;
    end

    data_mean = mean(data_rs{grp}, 1);
    data_se = std(data_rs{grp}, [], 1)/sqrt(size(data_rs{grp}, 1));

    plot(x_time, data_mean, 'color',[.9 .6 0], 'LineWidth', lnw)
    hold on
    jbfill(x_time, data_mean + data_se, data_mean - data_se, [.9 .6 0], [.9 .6 0], 1, 0.25)
    hold on


%     % sig different from zero
%     [pval, t_orig, crit_t] = mult_comp_perm_t1(data_bsl(:, 260:end)-data_bsl_btwrs(:, 260:end));
%     sig_time = find(pval < .05); % figure; plot(t_orig)

    data_mean = mean(data_btwrs{grp}, 1);
    data_se = std(data_btwrs{grp}, [], 1)/sqrt(size(data_btwrs{grp}, 1));

    plot(x_time, data_mean, '--', 'color',  [0 .6 .5], 'LineWidth', lnw)
    hold on
    jbfill(x_time, data_mean + data_se, data_mean - data_se,  [0 .6 .5],  [0 .6 .5], 1, 0.25)
    hold on

%     % plot sig times
%     if ~isempty(sig_time)
%         if grp == 1
%             plot(x_time(sig_time+259), ones(length(sig_time), 1)*(-.015), 's', 'color', 'k', 'MarkerFaceColor','k',...
%                  'MarkerSize', 8);
%         else
%             plot(x_time(sig_time+259), ones(length(sig_time), 1)*(-.01), 's', 'color', 'k', 'MarkerFaceColor','k',...
%                 'MarkerSize', 4);
%         end
%     end
    hold on
end
plot(x_time, zeros(length(x_time), 1), '--k')
hold on


% plot sig times - effect of CPP from LIMO calculated here:
% D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil_ruleswitch_deconv3events\LIMO_pupil_CPP_Level2.m
% load mask
mask = [];
RM_ANOVA_dir = 'D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil_ruleswitch_deconv3events\level2_RM_ANOVA_pupil_grp_highlowCPP';
load([RM_ANOVA_dir, '\mask_main_effect.mat']);
if ~isempty(mask)
        plot(x_time(mask > 0), ones(length(x_time(mask > 0)), 1)*(-.011), 's', 'color', 'k', 'MarkerFaceColor', 'k',...
             'MarkerSize', 8);
end
hold on
mask = [];
% interaction CPP x group
load([RM_ANOVA_dir, '\mask_interaction.mat']);
if ~isempty(mask)
        plot(x_time(mask > 0), ones(length(x_time(mask > 0)), 1)*(-.015), 's', 'color', [0.6350 0.0780 0.1840], 'MarkerFaceColor',[0.6350 0.0780 0.1840],...
             'MarkerSize', 8);
end
% hold on
% 
% % plot sig window with group difference in high COO condition calculated
% % LIMO t-test here: D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil_ruleswitch_deconv3events\LIMO_pupil_CPP_Level2.m
% ttest_dir = 'D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil_ruleswitch_deconv3events\level2_ttest_grpcomp_highCPP';
% mask = [];
% % interaction CPP x group
% load([ttest_dir, '\mask_group_effect.mat']);
% if ~isempty(mask)
%         plot(x_time(mask > 0), ones(length(x_time(mask > 0)), 1)*(-.015), 's', 'color', [0.9290 0.6940 0.1250], 'MarkerFaceColor',[0.9290 0.6940 0.1250],...
%              'MarkerSize', 8);
% end
hold on


plot([0 0], [-.017 .015], '--k')
hold off
ax = gca; box off
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none'; %ylim padded
axis([-inf inf -.017 .015])
xlabel('Time (s)', 'FontSize', 28, 'FontWeight','normal')
ylabel('Pupil (% mean)', 'FontSize', 28, 'FontWeight','normal')
     




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
