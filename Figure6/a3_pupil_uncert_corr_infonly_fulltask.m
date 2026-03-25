
clear; close all

addpath('D:\Project_LC_fMRI\analyses')
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
run('init_unfold.m') % start toolbox unfold

Corr_pupil_uncert_inf_full = cell(2, 2); 

for grp = 1:2
    for sbj = 1:length(group_infonly{grp})
        close all
        subject = char(group_infonly{grp}(sbj));

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
        processed_sets = cell(2, 1);
        uncertainty = cell(2, 1);
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
                continue
            elseif session == 4 % inference only in the lab
                condition = [condition, 3];
                cond = 3;
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
                
%                 figure; plot(CPP); hold on; plot(sample_genside)
                
                % CPP thresholds determined to equalize number of events
                % with number of rule switches - D:\Project_LC_fMRI\analyses\pupil\uncertainty_according2rule_switches_CPP.m
                CPP_highthreshold = find(CPP > 0.0775);
                CPP_lowthreshold = find(CPP < 0.000825);
                

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

                rule_switch_latency = cues_latency(rule_switch);
                evn_rule_switches = [ones(length(rule_switch_latency), 1) * 5, rule_switch_latency];

                % create event in between two true switchs for comparison - 6
                mid_rule_switch_latency = [];
                for r = 1:length(rule_switch)-1
                    mid_rule_switch_latency(r) = cues_latency(rule_switch(r)+round((rule_switch(r+1)-rule_switch(r))/2));
                end

                evn_norule_switches = [ones(length(mid_rule_switch_latency), 1) * 6, mid_rule_switch_latency'];

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
                EEG = pop_importevent( EEG, 'event',evn_cpp_all,'fields',{'type','latency'},'timeunit',NaN,'align',0,'optimalign','off');
                [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG);
                
                % downsample pupil to 50 Hz
                nanidx_chn = EEG.data(6, :);
                EEG = eeg_checkset( EEG );
                EEG = pop_resample( EEG, 50);
                EEG.data(6, :) = nanidx_chn(1:10:end);
                [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 

                evn_highcpp_idx_50Hz = [];
                evn_lowcpp_idx_50Hz = [];
                evn_choicetrial_idx_50Hz = [];
                evn_cue_idx_50Hz = [];
                for e = 1:length(EEG.event)
                    if EEG.event(e).type == 7
                        evn_highcpp_idx_50Hz = [evn_highcpp_idx_50Hz; round(EEG.event(e).latency)];
                    elseif EEG.event(e).type == 8
                        evn_lowcpp_idx_50Hz = [evn_lowcpp_idx_50Hz; round(EEG.event(e).latency)];
                    elseif EEG.event(e).type == 4
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
                

                if cond == 1 % full task in the lab
                    task = 1;
                elseif cond == 3 % inference-only task in the lab
                    task = 2;
                end
                processed_sets{task} = [processed_sets{task}; CURRENTSET];

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

                uncertainty{task} = [uncertainty{task}; uncert_tmp]; 

            end

        end

        for tsk = 1:2

            % merge datasets from different runs
            EEG = pop_mergeset( ALLEEG, processed_sets{tsk}, 0);
            [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET,'gui','off'); 
   
            for del = 1:4

                % exclude periods when pupil was interpolated for
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


                % calculate Pearson correlation coefficients between uncertainty and pupil
                % exclude interpolated data of more than 1 s and beginning and end
                % of recordings
                % exclude choice trials from onset to 5 s after
                pupil_data = EEG.data(1, :);
                uncertainty4corr = uncertainty{tsk}(:, del);
    
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
        
                Corr_pupil_uncert_inf_full{grp, tsk}(sbj, del) = R_corr_pupil(2, 1);

            end
        end    
    end
end

save_dir = [pwd, filesep, 'pupil_deconv_unfold\CPP_fulltask_infonly'];

cd(save_dir)

save Corr_pupil_uncert_inf_full Corr_pupil_uncert_inf_full

%% save to excel

grp = [ones(size(Corr_pupil_uncert_inf_full{1, 1}, 1), 1); ones(size(Corr_pupil_uncert_inf_full{2, 1}, 1), 1)*2];

T = array2table([grp, [Corr_pupil_uncert_inf_full{1, 1}; Corr_pupil_uncert_inf_full{2, 1}], ...
    [Corr_pupil_uncert_inf_full{1, 2}; Corr_pupil_uncert_inf_full{2, 2}]]);

T.Properties.VariableNames = {'group', 'corr_full_1', 'corr_full_2', 'corr_full_3', 'corr_full_4', ...
    'corr_inf_1', 'corr_inf_2', 'corr_inf_3', 'corr_inf_4'}

writetable(T, 'corr_pupil-uncertainty.xlsx')


%% plot uncertainty - pearson correlation
save_dir = [pwd, filesep, 'pupil_deconv_unfold\CPP_fulltask_infonly'];
cd(save_dir)
load Corr_pupil_uncert_inf_full

% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
plot_2groups_errorbars(Corr_pupil_uncert{1}, Corr_pupil_uncert{2}, 'Correlation r', {'', '', '', ''}, [1.5, 4.5, 7.5, 10.5], '')
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


%% plot uncertainty - pearson correlation
for tsk = 1:2
    % plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
    plot_2groups_errorbars(Corr_pupil_uncert_inf_full{1, tsk}, Corr_pupil_uncert_inf_full{2, tsk}, 'Correlation r', {'', '', '', ''}, [1.5, 4.5, 7.5, 10.5], '')
yline(0, '--k', 'LineWidth', 1.5)
    axis([0 11 -.05 .25]);
    % ylim padded
    % x0=10;
    % y0=10;
    % width=800;
    % height=400;
    % set(gcf,'position',[x0,y0,width,height])
    
    [h,p,ci,stats] = ttest2(Corr_pupil_uncert_inf_full{1, tsk}, Corr_pupil_uncert_inf_full{2, tsk})

end

%%
% plot_2groups_2conditions(data_grp1_cond1,data_grp1_cond2, data_grp2_cond1, data_grp2_cond2, y_label_text, title_text, xaxis_text)
 
plot_2groups_2conditions(Corr_pupil_uncert_inf_full{1, 2}(:, 3),...
    Corr_pupil_uncert_inf_full{1, 1}(:, 3),...
    Corr_pupil_uncert_inf_full{2, 2}(:, 3),...
    Corr_pupil_uncert_inf_full{2, 1}(:, 3),...
    'Correlation \it r', '', {'Infer-only', 'Two-level'})
axis([0 6, -.1, .3]);

[H,P,CI,STATS] = ttest(Corr_pupil_uncert_inf_full{2, 2}(:, 3), Corr_pupil_uncert_inf_full{2, 1}(:, 3)) 
[H,P,CI,STATS] = ttest(Corr_pupil_uncert_inf_full{1, 2}(:, 3), Corr_pupil_uncert_inf_full{1, 1}(:, 3)) 

[H,P,CI,STATS] = ttest2(Corr_pupil_uncert_inf_full{1, 2}(:, 3), Corr_pupil_uncert_inf_full{2, 2}(:, 3)) 
[H,P,CI,STATS] = ttest2(Corr_pupil_uncert_inf_full{1, 1}(:, 3), Corr_pupil_uncert_inf_full{2, 1}(:, 3)) 

%% aux functions

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


%% function plot data 2 groups, 2 conditions
function plot_2groups_2conditions(data_grp1_cond1,data_grp1_cond2, data_grp2_cond1, data_grp2_cond2, y_label_text, title_text, xaxis_text)
    figure;
    % plot data for group 1
    yMean1=nanmean(data_grp1_cond1);
    y_se1 = std(data_grp1_cond1,'omitnan')/sqrt(length(data_grp1_cond1));
    
    % condition 2
    yMean2=nanmean(data_grp1_cond2);
    y_se2 = std(data_grp1_cond2,'omitnan')/sqrt(length(data_grp1_cond2));
    
    

    
%         %plot the mean+-SEM box
%         %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
% %   Specify pos as a four-element vector of the form [x y w h] in data
% %   units. The x and y elements determine the location and the w and h
% %   elements determine the size. The function plots into the current axes
% %   without clearing existing content from the axes.
%     box off
%     rectangle('Position',[1-0.3,yMean1-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
%     hold on 
%     %plot the mean line    
%     plot([1-0.3 1+0.3],[yMean1 yMean1] ,'Color','k','LineWidth',3);
    

    box off
%     rectangle('Position',[2-0.3,yMean2-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
%     hold on
%     %plot the mean line    
%     plot([2-0.3 2+0.3],[yMean2 yMean2] ,'Color','k','LineWidth',5);
    hold on
    for y=1:length(data_grp1_cond1)
        plot([1+rand*0.2-0.1, 2+rand*0.2-0.1], [data_grp1_cond1(y), data_grp1_cond2(y)], '-o', 'color', [.8 .8 .8], ...
            'MarkerEdgeColor',[.75 .75 .75],'MarkerSize',6, 'LineWidth', 1);
        hold on;
    end
    
    bar([1, 2], [yMean1 yMean2], 'FaceColor','None','EdgeColor',[0 0 0],'LineWidth',1.5);
    hold on
    errorbar([1 2], [yMean1 yMean2], [y_se1 y_se2],".", 'LineWidth', 1.5, 'color', 'k')
%     errorbar([1 2], [yMean1 yMean2], [y_se1 y_se2],"o","MarkerSize",10,...
%         "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 3, 'color', 'k')
    %plot line between conditions  
%     plot([1 2],[yMean1 yMean2] ,'Color','k','LineWidth',2);
    
    
    % group 2
    % condition 1
    yMean1=nanmean(data_grp2_cond1);
    y_se1 = std(data_grp2_cond1,'omitnan')/sqrt(length(data_grp2_cond1));
        % condition 2
    yMean2=nanmean(data_grp2_cond2);
    y_se2 = std(data_grp2_cond2,'omitnan')/sqrt(length(data_grp2_cond2));
    
    box off
%     rectangle('Position',[4-0.3,yMean1-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
%     hold on
%     %plot the mean line    
%     plot([4-0.3 4+0.3],[yMean1 yMean1] ,'Color','k','LineWidth',5);
% 
%     box off
%     rectangle('Position',[5-0.3,yMean2-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
%     hold on
%     %plot the mean line    
%     plot([5-0.3 5+0.3],[yMean2 yMean2] ,'Color','k','LineWidth',5);
%     hold on
    
%         errorbar([4 5], [yMean1 yMean2], [y_se1 y_se2],"o","MarkerSize",10,...
%     "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 3, 'color', 'k')
    
    
    for y=1:length(data_grp2_cond1)
        plot([4+rand*0.2-0.1, 5+rand*0.2-0.1], [data_grp2_cond1(y), data_grp2_cond2(y)], '-d', 'color', [.8 .8 .8], ...
            'MarkerEdgeColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1);
        hold on;
    end
    
    bar([4, 5], [yMean1 yMean2], 'FaceColor','None','EdgeColor',[0 0 0],'LineWidth',1.5);
    hold on
    errorbar([4 5], [yMean1 yMean2], [y_se1 y_se2],".", 'LineWidth', 1.5, 'color', 'k')
    
    %plot line between conditions  
%     plot([4 5],[yMean1 yMean2] ,'Color','k','LineWidth',2);
    
    % axes('XColor','none');
    hold off;
    axis([0 6 -inf inf]);
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    ylim padded
%     ax.XTickLabel= [];
    ax.XAxis.FontSize = 24;
    xticks([1 2 4 5])
    ax.XTickLabel= xaxis_text; %{'Full task' 'Inference' 'Full task' 'Inference'};
    xtickangle(45)
    ylabel(y_label_text, 'FontSize', 30, 'FontWeight','normal')
    title(title_text, 'FontSize', 32, 'FontWeight','normal')

%     x0=10;
%     y0=10;
%     width=400;
%     height=400;
%     set(gcf,'position',[x0,y0,width,height])
end