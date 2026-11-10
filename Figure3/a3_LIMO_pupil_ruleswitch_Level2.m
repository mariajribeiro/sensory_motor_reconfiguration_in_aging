% run second level LIMO stats
% use coefficients from deconvolution including rule switch, event in
% between rule switch (no rule switch), choice trials
% calculated here: D:\Project_LC_fMRI\analyses\pupil\pupil_according2rule_switches_deconv3events.m
clear;
addpath('C:\eeglab2022.0\plugins\limo_tools-master_Nov2022') 
pupil_folder = fileparts(pwd);
load([pupil_folder, '\LIMO_pupil\expected_chanlocs_both.mat']);

% addpath('D:\Project_LC_fMRI\analyses');
% group = participants_included;

level2_RM_ANOVA_dir = [pwd, '\level2_RM_ANOVA_pupil_grp_ruleswitch'];
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

load('D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv\R_rs_btwrs_ch.mat');
% Y = channels, time, subjects, measures
% rule switch
Y(1, :, :, 1) = [R_rs_btwrs_ch{1}(:, 1:1000)', R_rs_btwrs_ch{2}(:, 1:1000)']; 
% no rule switch
Y(1, :, :, 2) = [R_rs_btwrs_ch{1}(:, 1001:2000)', R_rs_btwrs_ch{2}(:, 1001:2000)']; 

gp(:, 1) = [ones(size(R_rs_btwrs_ch{1}, 1), 1);  ones(size(R_rs_btwrs_ch{2}, 1), 1)*2];

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
    %     what is the range of significant F/t values? 
    stats_F = [min(stat_values(mask ~= 0)) max(stat_values(mask ~= 0))];
end

%%
limo_display_results(1,'Rep_ANOVA_Interaction_gp_Factor_1.mat',pwd,0.05, 2,...
    fullfile(pwd,'LIMO.mat'), 0);
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

%% amplitude difference
load('D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv\R_rs_btwrs_ch.mat');
% rule switch
Yrs = [R_rs_btwrs_ch{1}(:, 1:1000)', R_rs_btwrs_ch{2}(:, 1:1000)']; 
% no rule switch
Ynrs = [R_rs_btwrs_ch{1}(:, 1001:2000)', R_rs_btwrs_ch{2}(:, 1001:2000)']; 


% cluster 1 starts at -1480ms ends at 640ms, max 25.9393 @ -220ms channel AF3 

mean_c1_rs = mean(mean(Yrs((5-1.48) * 50:(5+.64) * 50, :), 1))
mean_c1_nrs = mean(mean(Ynrs((5-1.48) * 50:(5+.64) * 50, :), 1))

mean_c1_diff = mean(mean(Ynrs((5-1.48) * 50:(5+.64) * 50, :), 1)-mean(Yrs((5-1.48) * 50:(5+.64) * 50, :), 1))

sd_c1_diff = std(mean(Ynrs((5-1.48) * 50:(5+.64) * 50, :), 1)-mean(Yrs((5-1.48) * 50:(5+.64) * 50, :), 1))



% cluster 2 starts at 1200ms ends at 8460ms, max 54.4866 @ 5920ms channel AF3 

mean_c2_diff = mean(mean(Ynrs((5 + 1.2)*50:(5+8.46)*50, :), 1)-mean(Yrs((5 + 1.2)*50:(5+8.46)*50, :), 1))

sd_c2_diff = std(mean(Ynrs((5 + 1.2)*50:(5+8.46)*50, :), 1)-mean(Yrs((5 + 1.2)*50:(5+8.46)*50, :), 1))