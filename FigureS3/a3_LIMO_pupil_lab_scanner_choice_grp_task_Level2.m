% run second level LIMO stats
% pupil responses to choice trials for participants that performed
% inference-only and two level task - comparing across age groups and tasks
clear;
eeglab
pupil_folder = fileparts(pwd);
load([pupil_folder, '\LIMO_pupil\expected_chanlocs_both.mat']);

% addpath('D:\Project_LC_fMRI\analyses');
% group = participants_included;


% load data
save_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_cpp_deconv_lab_scanner';
load([save_dir, filesep, 'R_highlowCPP_ch_cond']); 

% delete data from participants that don't have data in the scanner
load subject_included

% Create a logical array where true means the cell is empty
emptyCells = cellfun(@isempty, subject_included{1, 2});
% Get the linear indices of the empty cells
emptyIndices = find(emptyCells);

R_highlowCPP_ch_cond{1, 1}(emptyIndices, :) = [];


% Create a logical array where true means the cell is empty
emptyCells = cellfun(@isempty, subject_included{2, 2});
% Get the linear indices of the empty cells
emptyIndices = find(emptyCells);

R_highlowCPP_ch_cond{2, 1}(emptyIndices, :) = [];

level2_RM_ANOVA_dir = [pwd, '\level2_RM_ANOVA_grp_site_choice'];
mkdir(level2_RM_ANOVA_dir);
cd(level2_RM_ANOVA_dir);

% limo_random_robust(6,y,gp,factor_levels,LIMO,'go',option)
%                    6 = Repeated measures ANOVA/ANCOVA using multivariate approach
%                    y = data (dim channels, time or freq, subjects, measures)
%                      = data (dim channels, freq, time, subjects, measures)
%                      = the name of the Yr file
%                    gp = a vector defining gps
%                    factor_levels = a vector specifying the levels of each repeated measure factor
%                    LIMO the basic structure with data, design and channel info
%                         or the full name of the LIMO file
%                    'go' is optional and prompt or not the pseudo-design
%                         options are 'yes' (prompt, default),
%                         or 'no' (no prompt, usuful for scripting)

Y = []; gp = [];




% Y = channels, time, subjects, measures
% choice trials - lab
Y(1, :, :, 1) = [R_highlowCPP_ch_cond{1, 1}(:, 2001:3000); R_highlowCPP_ch_cond{2, 1}(:, 2001:3000)]'; 
% choice trials - scanner
Y(1, :, :, 2) = [R_highlowCPP_ch_cond{1, 2}(:, 2001:3000); R_highlowCPP_ch_cond{2, 2}(:, 2001:3000)]'; 

gp(:, 1) = [ones(size(R_highlowCPP_ch_cond{1, 1}, 1), 1);  ones(size(R_highlowCPP_ch_cond{2, 1}, 1), 1)*2];

% save Y Y
% save gp gp

% create LIMO variable
LIMO.Level                    = 2;

LIMO.Type = 'Channels';
LIMO.Analysis = 'Time';

LIMO.dir                      = level2_RM_ANOVA_dir;

LIMO.data.data_dir            = level2_RM_ANOVA_dir;
% LIMO.data.data                = 

LIMO.data.start               = 1;
LIMO.data.end                 = 1000;
LIMO.data.trim1               = 1; 
LIMO.data.trim2               = size(Y, 2);
LIMO.data.timevect            = -5000:20:14999;
LIMO.data.sampling_rate       = 50;
LIMO.data.neighbouring_matrix = channeighbstructmat(1, 1);
LIMO.data.chanlocs = expected_chanlocs(1);

% LIMO.design.fullfactorial     = 0;
% LIMO.design.zscore            = 0;
LIMO.design.method            = 'Trimmed mean'; 
LIMO.design.type_of_analysis  = 'Mass-univariate';
LIMO.design.bootstrap         = 1000; 
LIMO.design.tfce              = 0;

save LIMO LIMO

%% repeated measures ANOVA
% limo_random_robust(6,y,gp,factor_levels,LIMO,'go',option)
LIMOpath = limo_random_robust(6, Y, gp, 2, LIMO);
% 1 one_sample_parameter_X (channels, frames [time, freq or freq-time], [mean value, se, df, t, p])
%   H0_one_sample_ttest_parameter_X (channels, frames, [T values under H0, p values under H0], LIMO.design.bootstrap)

%% view results  - clustering
% addpath('C:\eeglab2022.0\plugins\limo_tools-master_Nov2022') 
% level2_RM_ANOVA_dir = [pwd, '\level2_RM_ANOVA_IBIvsECG'];
% cd(level2_RM_ANOVA_dir);
% https://github.com/LIMO-EEG-Toolbox/limo_tools/wiki/Workspace_variables
mask = [];
% limo_display_results(Type,FileName,PathName,p,MCC,LIMO,flag,options)
limo_display_results(1,'Rep_ANOVA_Main_effect_1.mat',pwd,0.05, 2,...
    fullfile(pwd,'LIMO.mat'), 0);

if ~isempty(mask)
    save mask_main_effect mask
    save stat_values_main_effect stat_values %F/t values
    save p_values_main_effect p_values

    number_clusters = max(unique(mask(:)));
    p_value_cluster = p_values(mask == 1);
    max_p_value = max(p_values(mask ~= 0));
    % what is the range of significant F/t values? 
    stats_F = [min(stat_values(mask ~= 0)) max(stat_values(mask ~= 0))];
end

%%
mask = [];
limo_display_results(1,'Rep_ANOVA_Interaction_gp_Factor_1.mat',pwd,0.05, 2,...
    fullfile(pwd,'LIMO.mat'), 0);
if ~isempty(mask)
    save mask_interaction mask
    save stat_values_interaction stat_values %F/t values
    save p_values_interaction p_values


    number_clusters = max(unique(mask(:)));
    p_value_cluster = p_values(mask == 1);
    max_p_value = max(p_values(mask ~= 0));
    %     what is the range of significant F/t values? 
    stats_F = [min(stat_values(mask ~= 0)) max(stat_values(mask ~= 0))];
end


%%

mask = [];
limo_display_results(1,'Rep_ANOVA_Gp_effect.mat',pwd,0.05, 2,...
    fullfile(pwd,'LIMO.mat'), 0);
% saveas(gcf, 'One_sample_timecourse.fig'); close(gcf)
if ~isempty(mask)
    save mask_group_effect mask
    save stat_values_group_effect stat_values %F/t values
    save p_values_group_effect p_values
    
    number_clusters = max(unique(mask(:)));
    p_value_cluster = p_values(mask == 1);
    max_p_value = max(p_values(mask ~= 0));
    %     what is the range of significant F/t values? 
    stats_F = [min(stat_values(mask ~= 0)) max(stat_values(mask ~= 0))];
end

%     number_clusters = max(unique(mask(:)));
%     p_value_cluster = p_values(mask == 1);
%     max_p_value = max(p_values(mask ~= 0));
%     %     what is the range of significant F/t values? 
%     % [min(stat_values(mask ~= 0)) max(stat_values(mask ~= 0))] etc ..
% 
%     % replot using 
%     limo_display_image(LIMO,stat_values ,mask,'go/no-go HR effect',0) 



%% average pupil across groups

load mask_main_effect

Ychoice_lab = [R_highlowCPP_ch_cond{1, 1}(:, 2001:end); R_highlowCPP_ch_cond{2, 1}(:, 2001:end)]; 
Ychoice_scanner = [R_highlowCPP_ch_cond{1, 2}(:, 2001:end); R_highlowCPP_ch_cond{2, 2}(:, 2001:end)]; 


mean_c1_diff = mean(mean(Ychoice_lab(:, mask == 2), 2) - mean(Ychoice_scanner(:, mask == 2), 2), 1)

sd_c1_diff = std(mean(Ychoice_lab(:, mask == 2), 2) - mean(Ychoice_scanner(:, mask == 2), 2), 1)



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