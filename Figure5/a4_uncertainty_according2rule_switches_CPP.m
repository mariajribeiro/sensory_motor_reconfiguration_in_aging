% 
clear;close all

addpath('D:\Project_LC_fMRI\analyses');

group = participants_included;

task_pupil_dir = [pwd, '\preprocessed_pupil_files\'];
S = dir(task_pupil_dir);

for grp = 1:2
    for sbj = 1:length(group{grp})
        close all
        subject = char(group{grp}(sbj));

        % each subject has at least one session outside the scanner (sessions 1 and 2) and one inside
        % the scanner (session 3)
        % some participants also have outside the scanner four runs of
        % inference-only task saved as session 4
        S = dir(['D:\Project_LC_fMRI\data\ET_data\', char(subject)]);
        sessions = []; % sessions = sum([S(~ismember({S.name},{'.','..'})).isdir]);
        for f = 1:length(S)
            if contains(S(f).name, 'session')
                sessions = [sessions, str2num(S(f).name(8))];
            end
        end


        b=0; condition = []; 
        cpp_ruleswitch_tmp = []; uncertainty_ruleswitch_tmp = [];
        cpp_btwruleswitch_tmp = []; uncertainty_btwruleswitch_tmp = [];
        uncertainty_CPP_high_tmp = []; uncertainty_CPP_low_tmp = [];

        clear sample_genside

        % threshold to determine which equalizes number of trials with rule
        % switch with last value testing for threshold determined
        cpp_thrs_high = [.06:.005:.2, 0.0775]; 
        cpp_thrs_low = [.000001:.00005:.001, 0.000825];
        CPP_highthreshold_tmp = zeros(length(cpp_thrs_high), 1);  
        CPP_lowthreshold_tmp = zeros(length(cpp_thrs_low), 1);    
        rule_switch_tmp = 0;  

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
            end
            
            folder_session = ['D:\Project_LC_fMRI\data\ET_data\', char(subject), '\session', num2str(session)];
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
                sample_dir = [folder_session ,'\run', num2str(run)];

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
                
                btw_rule_switch = [];
                for rs = 1:length(rule_switch)-1
                    btw_rule_switch(rs, 1) = round(rule_switch(rs)+(rule_switch(rs+1)-rule_switch(rs))/2);
                end


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
                
                
                % cpp_thrs_high = .06:.005:.2;
                % cpp_thrs_low = .000001:.00005:.001;
                for ct = 1:length(cpp_thrs_high)
                    CPP_highthreshold_tmp(ct, 1) = CPP_highthreshold_tmp(ct, 1) + length(find(CPP > cpp_thrs_high(ct)));
                end

                for ct = 1:length(cpp_thrs_low)
                    CPP_lowthreshold_tmp(ct, 1) = CPP_lowthreshold_tmp(ct, 1) + length(find(CPP < cpp_thrs_low(ct))); 
                end

                % high/low CPP samples
                CPP_high = find(CPP > 0.0775); % threshold that equalizes with number of rule switches
                CPP_low = find(CPP < 0.000825); % threshold that equalizes with number of rule switches

                rule_switch_tmp = rule_switch_tmp + length(rule_switch);
                              
%                 figure; plot(CPP); hold on; plot(CPP_threshold, ones(length(CPP_threshold), 1).*.1, 'o');
%                 hold on; plot(CPP_lowthreshold, ones(length(CPP_lowthreshold), 1).*.08, '+')

                % create variable with CPP and uncertainty aligned to rule
                % switches - from 12 samples before up to  37 samples after rule switch
                % for trials belonging to full task in lab and scanner
                if ismember(cond, [1, 2])
                    for rs = 1:length(rule_switch)
                        if rule_switch(rs)>12 && rule_switch(rs) < length(CPP)-37
                            cpp_ruleswitch_tmp = [cpp_ruleswitch_tmp; CPP(rule_switch(rs)-12: rule_switch(rs)+37)];
                            uncertainty_ruleswitch_tmp = [uncertainty_ruleswitch_tmp; -abs(prior(rule_switch(rs)-12: rule_switch(rs)+37))'];
                        end
                    end
                end

                % create variable with CPP and uncertainty aligned to the sample between rule
                % switches (no rule switch) - from 12 samples before up to 37 samples after rule switch
                % for trials belonging to full task in lab and scanner
                if ismember(cond, [1, 2])
                    for rs = 1:length(btw_rule_switch)
                        if btw_rule_switch(rs)>12 && btw_rule_switch(rs) < length(CPP)-37
                            cpp_btwruleswitch_tmp = [cpp_btwruleswitch_tmp; CPP(btw_rule_switch(rs)-12: btw_rule_switch(rs)+37)];
                            uncertainty_btwruleswitch_tmp = [uncertainty_btwruleswitch_tmp; -abs(prior(btw_rule_switch(rs)-12: btw_rule_switch(rs)+37))'];
                        end
                    end
                end

                % create variable with uncertainty aligned to high cpp samples - from 12 samples before up to 37 samples after rule switch
                % for trials belonging to full task in lab and scanner
                if ismember(cond, [1, 2])
                    for rs = 1:length(CPP_high)
                        if CPP_high(rs)>12 && CPP_high(rs) < length(CPP)-37
                            uncertainty_CPP_high_tmp = [uncertainty_CPP_high_tmp; -abs(prior(CPP_high(rs)-12: CPP_high(rs)+37))'];
                        end
                    end
                end   

                % create variable with uncertainty aligned to high cpp samples - from 12 samples before up to 37 samples after rule switch
                % for trials belonging to full task in lab and scanner
                if ismember(cond, [1, 2])
                    for rs = 1:length(CPP_low)
                        if CPP_low(rs)>12 && CPP_low(rs) < length(CPP)-37
                            uncertainty_CPP_low_tmp = [uncertainty_CPP_low_tmp; -abs(prior(CPP_low(rs)-12: CPP_low(rs)+37))'];
                        end
                    end
                end   
                


            end
        end
        
        % save cpp and uncertainty aligned with rule switches average
        % within participant
        cpp_ruleswitch{grp}(sbj, :) = mean(cpp_ruleswitch_tmp, 1);
        uncertainty_ruleswitch{grp}(sbj, :) = mean(uncertainty_ruleswitch_tmp, 1);

        cpp_noruleswitch{grp}(sbj, :) = mean(cpp_btwruleswitch_tmp, 1);
        uncertainty_noruleswitch{grp}(sbj, :) = mean(uncertainty_btwruleswitch_tmp, 1);

        uncertainty_CPPhigh{grp}(sbj, :) = mean(uncertainty_CPP_high_tmp, 1);
        uncertainty_CPPlow{grp}(sbj, :) = mean(uncertainty_CPP_low_tmp, 1)

        number_highcppthreshold{grp}(sbj, :) = CPP_highthreshold_tmp;
        number_lowcppthreshold{grp}(sbj, :) = CPP_lowthreshold_tmp;
        number_ruleswitches{grp}(sbj, :) = rule_switch_tmp;
        % add subject to variables
        subject_id{grp, sbj} = subject;

    end
end

% save_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches';
% 
% cd(save_dir)
% 
% save number_highcppthreshold number_highcppthreshold
% save number_lowcppthreshold number_lowcppthreshold
% save number_ruleswitches number_ruleswitches
% 
% save cpp_ruleswitch cpp_ruleswitch
% save uncertainty_ruleswitch uncertainty_ruleswitch
% save cpp_noruleswitch cpp_noruleswitch
% save uncertainty_noruleswitch uncertainty_noruleswitch
% 
% save uncertainty_CPPhigh uncertainty_CPPhigh
% save uncertainty_CPPlow uncertainty_CPPlow


%% find cpp thresholds that approximate number of rule switches
cd('D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches')
load number_highcppthreshold; load number_lowcppthreshold
load number_ruleswitches; 

figure; 
plot(mean([number_highcppthreshold{1}; number_highcppthreshold{2}], 1 ), 'o')
hold on
plot(mean([number_lowcppthreshold{1}; number_lowcppthreshold{2}], 1 ), '+')
hold on
plot([1, size(number_highcppthreshold{1}, 2)], [mean([number_ruleswitches{1}; number_ruleswitches{2}]), mean([number_ruleswitches{1}; number_ruleswitches{2}])])
hold off
ax = gca; box off

ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';
%     axis([-200 2000 -inf inf])
xlabel('CPP threshold', 'FontSize', 24, 'FontWeight','normal')
ylabel('Number of events', 'FontSize', 24, 'FontWeight','normal')
legend('high cpp', 'low cpp', 'rule switches','Location','eastoutside')

data_high = [number_highcppthreshold{1}; number_highcppthreshold{2}];
data_low = [number_lowcppthreshold{1}; number_lowcppthreshold{2}];

[h,p,ci,stats] = ttest2(data_high(:, end), [number_ruleswitches{1}; number_ruleswitches{2}])
[h,p,ci,stats] = ttest2(data_low(:, end), [number_ruleswitches{1}; number_ruleswitches{2}])

mean([number_ruleswitches{1}; number_ruleswitches{2}])
std([number_ruleswitches{1}; number_ruleswitches{2}])

mean(data_high(:, end))
std(data_high(:, end))

mean(data_low(:, end))
std(data_low(:, end))


cpp_thrs_high = [.06:.005:.2, 0.0775]; 
cpp_thrs_low = [.000001:.00005:.001, 0.000825];
figure; 
plot(cpp_thrs_high, mean([number_highcppthreshold{1}; number_highcppthreshold{2}], 1 ), 'o')
ax = gca; box off
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';
%     axis([-200 2000 -inf inf])
xlabel('CPP threshold', 'FontSize', 24, 'FontWeight','normal')
ylabel('Number of events', 'FontSize', 24, 'FontWeight','normal')
legend('high cpp', 'low cpp', 'rule switches','Location','eastoutside')


figure; 
plot(cpp_thrs_low, mean([number_lowcppthreshold{1}; number_lowcppthreshold{2}], 1 ), '+')
ax = gca; box off
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';
%     axis([-200 2000 -inf inf])
xlabel('CPP threshold', 'FontSize', 24, 'FontWeight','normal')
ylabel('Number of events', 'FontSize', 24, 'FontWeight','normal')
legend('low cpp', 'Location','eastoutside')




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
plot(x_time, data_mean,  '-k', 'LineWidth', 2, 'color', [229, 122, 119]./255)
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, [229, 122, 119]./255, [229, 122, 119]./255, 1, 0.25)
hold on
ylabel('CPP', 'FontSize', 24, 'FontWeight','normal')
data_mean = mean([uncertainty_ruleswitch{1}; uncertainty_ruleswitch{2}], 1);
data_se = std([uncertainty_ruleswitch{1}; uncertainty_ruleswitch{2}], [], 1)/sqrt(size([uncertainty_ruleswitch{1}; uncertainty_ruleswitch{2}], 1));
yyaxis right
plot(x_time, data_mean, '-', 'color', [61, 101, 165]./255, 'LineWidth', 2)
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, [61, 101, 165]./255, [61, 101, 165]./255, 1, 0.25)
hold on

% plot(x_time, zeros(length(x_time), 1), '--k')
hold on
plot([0 0], [-3.5 -1], '--k')
hold off
ax = gca; box off
axis([-12 37 -inf inf])
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';
ax.YAxis(1).Color = [229, 122, 119]./255;
ax.YAxis(2).Color = [61, 101, 165]./255;
xlabel('Sample relative to rule-switch', 'FontSize', 24, 'FontWeight','normal')
ylabel('Uncertainty', 'FontSize', 24, 'FontWeight','normal')


% uncertainty at time of rule swicth versus uncertainty three samples before

[h,p,ci,stats] = ttest([uncertainty_ruleswitch{1}(:, 11); uncertainty_ruleswitch{2}(:, 11)], [uncertainty_ruleswitch{1}(:, 12); uncertainty_ruleswitch{2}(:, 12)])


[h,p,ci,stats] = ttest([cpp_ruleswitch{1}(:, 12); cpp_ruleswitch{2}(:, 12)], [cpp_ruleswitch{1}(:, 8); cpp_ruleswitch{2}(:, 8)])


%% plot uncertainty aligned with rule switch and no rule switch
save_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches';
cd(save_dir)

load uncertainty_ruleswitch; load uncertainty_noruleswitch;
data_ruleswitch = [uncertainty_ruleswitch{1}; uncertainty_ruleswitch{2}];
data_noruleswitch = [uncertainty_noruleswitch{1}; uncertainty_noruleswitch{2}];


[h,p,ci,stats] = ttest(data_ruleswitch(:, 12), data_noruleswitch(:, 12));

% % sig different from zero
% [pval, t_orig, crit_t] = mult_comp_perm_t1([uncertainty_ruleswitch{1}; uncertainty_ruleswitch{2}]-[uncertainty_noruleswitch{1}; uncertainty_noruleswitch{2}]);
% sig_samples = find(pval < .05); % figure; plot(t_orig)

x_time = -12:37;
   
figure;
data_mean = mean([uncertainty_ruleswitch{1}; uncertainty_ruleswitch{2}], 1);
data_se = std([uncertainty_ruleswitch{1}; uncertainty_ruleswitch{2}], [], 1)/sqrt(size([uncertainty_ruleswitch{1}; uncertainty_ruleswitch{2}], 1));

plot(x_time, data_mean, 'LineWidth', 2,  'color',[.9 .6 0])
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, [.9 .6 0], [.9 .6 0], 1, 0.25)
hold on

data_mean = mean([uncertainty_noruleswitch{1}; uncertainty_noruleswitch{2}], 1);
data_se = std([uncertainty_noruleswitch{1}; uncertainty_noruleswitch{2}], [], 1)/sqrt(size([uncertainty_noruleswitch{1}; uncertainty_noruleswitch{2}], 1));

plot(x_time, data_mean,  '--', 'color',  [0 .6 .5], 'LineWidth', 2)
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, [0 .6 .5], [0 .6 .5], 1, 0.25)
hold on

% plot(x_time, zeros(length(x_time), 1), '--k')
hold on
plot([0 0], [-3.5 -1], '--k')
hold off
ax = gca; box off
c = ax.Color;
axis([-12 37 -3.2 -1.5])
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';
xlabel({'Sample relative to', 'rule-switch/no rule-switch'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Uncertainty', 'FontSize', 28, 'FontWeight','normal')


%% plot uncertainty aligned with high CPP and low CPP
save_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches';
cd(save_dir)

load uncertainty_CPPhigh; load uncertainty_CPPlow;
data_highCPP = [uncertainty_CPPhigh{1}; uncertainty_CPPhigh{2}];
data_lowCPP = [uncertainty_CPPlow{1}; uncertainty_CPPlow{2}];


[h,p,ci,stats] = ttest(data_highCPP(:, 12), data_lowCPP(:, 12))

[h,p,ci,stats] = ttest(data_highCPP(:, 40), data_lowCPP(:, 40))

% % sig different from zero
% [pval, t_orig, crit_t] = mult_comp_perm_t1(data_highCPP-data_lowCPP);
% sig_samples = find(pval < .05); % figure; plot(t_orig)

x_time = -12:37;
   
figure;
data_mean = mean(data_highCPP, 1);
data_se = std(data_highCPP, [], 1)/sqrt(size(data_highCPP, 1));

plot(x_time, data_mean, 'LineWidth', 2,  'color',[.9 .6 0])
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, [.9 .6 0], [.9 .6 0], 1, 0.25)
hold on

data_mean = mean(data_lowCPP, 1);
data_se = std(data_lowCPP, [], 1)/sqrt(size(data_lowCPP, 1));

plot(x_time, data_mean, '--','color',  [0 .6 .5], 'LineWidth', 2)
hold on
jbfill(x_time, data_mean + data_se, data_mean - data_se, [0 .6 .5], [0 .6 .5], 1, 0.25)
hold on

% plot(x_time, zeros(length(x_time), 1), '--k')
hold on
plot([0 0], [-4.5 -1], '--k')
hold off
ax = gca; box off
c = ax.Color;
axis([-12 37 -inf inf])
% ylim padded
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';
xlabel('Sample relative to high/low CPP', 'FontSize', 28, 'FontWeight','normal')
ylabel('Uncertainty', 'FontSize', 28, 'FontWeight','normal')

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
