% run second level LIMO stats
% use coefficients from deconvolution including rule switch, event in
% between rule switch (no rule switch), choice trials
% calculated here: D:\Project_LC_fMRI\analyses\pupil\pupil_according2rule_switches_deconv3events.m
% comparison of pupil response in choice trials across groups - t-test
clear;
eeglab;
pupil_folder = fileparts(pwd);
load([pupil_folder, '\LIMO_pupil\expected_chanlocs_both.mat']);

% addpath('D:\Project_LC_fMRI\analyses');
% group = participants_included;

level2_RM_ANOVA_dir = [pwd, '\level2_RM_ANOVA_pupil_grp_ruleswitch'];
mkdir(level2_RM_ANOVA_dir);
cd(level2_RM_ANOVA_dir);

% limo_random_robust(2,y1,y2,parameter number,LIMO)
%                    2 = two samples t-test
%                    y1 = data (dim channels, time or freq, subjects)
%                       = data (dim channels, freq, time, subjects)
%                       = the name of the Y1r file
%                    y2 = data (dim channels, time or freq, subjects)
%                       = data (dim channels, freq, time, subjects)
%                       = the name of the Y2r file
%                    parameter number = describe which parameter is currently analysed (e.g. 1 - use for maming only)

Y1 = []; Y2 = [];

load('D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv\R_rs_btwrs_ch.mat');
% Y = channels, time, subjects
% young - choice trials
Y1(1, :, :) = R_rs_btwrs_ch{1}(:, 2001:3000)'; 
% older - choice trials
Y2(1, :, :) = R_rs_btwrs_ch{2}(:, 2001:3000)'; 


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
LIMO.data.trim2               = size(Y1, 2);
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

%% independent samples t-test
% limo_random_robust(2,y1,y2,parameter number,LIMO)
LIMOpath = limo_random_robust(2,Y1,Y2,1,LIMO);
% 1 one_sample_parameter_X (channels, frames [time, freq or freq-time], [mean value, se, df, t, p])
%   H0_one_sample_ttest_parameter_X (channels, frames, [T values under H0, p values under H0], LIMO.design.bootstrap)

%% view results  - clustering
% addpath('C:\eeglab2022.0\plugins\limo_tools-master_Nov2022') 
% level2_RM_ANOVA_dir = [pwd, '\level2_RM_ANOVA_IBIvsECG'];
% cd(level2_RM_ANOVA_dir);
% https://github.com/LIMO-EEG-Toolbox/limo_tools/wiki/Workspace_variables
mask = [];
% limo_display_results(Type,FileName,PathName,p,MCC,LIMO,flag,options)
limo_display_results(1,'two_samples_ttest_parameter_1_.mat',pwd,0.05, 2,...
    fullfile(pwd,'LIMO.mat'), 0);

if ~isempty(mask)
    save mask mask
    save stat_values stat_values %F/t values
    save p_values p_values


    number_clusters = max(unique(mask(:)));
    p_value_cluster = p_values(mask == 1);
    max_p_value = max(p_values(mask ~= 0));
    %     what is the range of significant F/t values? 
    stats_F = [min(stat_values(mask ~= 0)) max(stat_values(mask ~= 0))];
end

