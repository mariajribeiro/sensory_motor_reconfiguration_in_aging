% run second level LIMO stats
% use coefficients from deconvolution including high CPP, elow CPP, choice trials
% calculated here: pupil_according2CPP_deconv3events.m
clear;
addpath('C:\eeglab2022.0\plugins\limo_tools-master_Nov2022') 
pupil_folder = fileparts(pwd);
load([pupil_folder, '\LIMO_pupil\expected_chanlocs_both.mat']);

% addpath('D:\Project_LC_fMRI\analyses');
% group = participants_included;

level2_RM_ANOVA_dir = [pwd, '\level2_RM_ANOVA_pupil_grp_highlowCPP'];
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

load('D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv\R_highlowCPP_ch.mat');
% Y = channels, time, subjects, measures
% high CPP
Y(1, :, :, 1) = [R_highlowCPP_ch{1}(:, 1:1000)', R_highlowCPP_ch{2}(:, 1:1000)']; 
% low CPP
Y(1, :, :, 2) = [R_highlowCPP_ch{1}(:, 1001:2000)', R_highlowCPP_ch{2}(:, 1001:2000)']; 

gp(:, 1) = [ones(size(R_highlowCPP_ch{1}, 1), 1);  ones(size(R_highlowCPP_ch{2}, 1), 1)*2];

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



%% average amplitude within clusters
% effect of condition
% cluster 1 starts at -4400ms ends at 440ms, max 16.0286 @ -780ms channel AF3 
% cluster 2 starts at 600ms ends at 5580ms, max 76.4155 @ 880ms channel AF3 
% cluster 3 starts at 8220ms ends at 11720ms, max 16.1604 @ 9920ms channel AF3 

load('D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv\R_highlowCPP_ch.mat');
% high CPP
Yhcpp = [R_highlowCPP_ch{1}(:, 1:1000)', R_highlowCPP_ch{2}(:, 1:1000)']; 
% low CPP
Ylcpp = [R_highlowCPP_ch{1}(:, 1001:2000)', R_highlowCPP_ch{2}(:, 1001:2000)']; 

mean_c1_diff = mean(mean(Yhcpp((5-4.4) * 50:(5+.44) * 50, :), 1)-mean(Ylcpp((5-4.4) * 50:(5+.44)*50 , :), 1))

sd_c1_diff = std(mean(Yhcpp((5-4.4) * 50:(5+.44) * 50, :), 1)-mean(Ylcpp((5-4.4) * 50:(5+.44)*50 , :), 1))


mean_c2_diff = mean(mean(Yhcpp((5+.6) * 50:(5+5.58) * 50, :), 1)-mean(Ylcpp((5+.6) * 50:(5+5.58) * 50, :), 1))

sd_c2_diff = std(mean(Yhcpp((5+.6) * 50:(5+5.58) * 50, :), 1)-mean(Ylcpp((5+.6) * 50:(5+5.58) * 50, :), 1))


mean_c3_diff = mean(mean(Yhcpp((5+8.2) * 50:(5+11.72) * 50, :), 1)-mean(Ylcpp((5+8.2) * 50:(5+11.72) * 50, :), 1))

sd_c3_diff = std(mean(Yhcpp((5+8.2) * 50:(5+11.72) * 50, :), 1)-mean(Ylcpp((5+8.2) * 50:(5+11.72) * 50, :), 1))


%% average amplitude - using significant time windows for group x condition interaction in full task
addpath('D:\Project_LC_fMRI\analyses');
group = participants_included;
% load mask 
mask_dir = 'D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil_ruleswitch_deconv3events\level2_RM_ANOVA_pupil_grp_highlowCPP';
load([mask_dir, filesep, 'mask_interaction.mat']);

% load data
load('D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv\R_highlowCPP_ch.mat');
% high CPP
Yhcpp = [R_highlowCPP_ch{1}(:, 1:1000); R_highlowCPP_ch{2}(:, 1:1000)]; 
% low CPP
Ylcpp = [R_highlowCPP_ch{1}(:, 1001:2000); R_highlowCPP_ch{2}(:, 1001:2000)]; 

% save table with group subjid highcpp_pupil, lowcpp_pupil, deltacpp_pupil
gp = [ones(size(R_highlowCPP_ch{1}, 1), 1);  ones(size(R_highlowCPP_ch{2}, 1), 1)*2];
subjid = [group{1}'; group{2}'];
highcpp_pupil = mean(Yhcpp(:, mask == 1), 2);
lowcpp_pupil = mean(Ylcpp(:, mask == 1), 2);
deltacpp_pupil = highcpp_pupil - lowcpp_pupil;


T_cpp_pupil = array2table([gp, highcpp_pupil, lowcpp_pupil, deltacpp_pupil]);
T_cpp_pupil.Properties.VariableNames= {'group', 'highcpp_pupil', 'lowcpp_pupil', 'deltacpp_pupil'};
T_cpp_pupil.SubjID = subjid;

% add accuracy to table and bayesian model fit parameters
model_dir = 'D:\Project_LC_fMRI\analyses\behaviour\Josh\';
Tparams = readtable([model_dir, 'model_free_parameters.xlsx']);

for s = 1:size(T_cpp_pupil, 1)
    for ss = 1:size(Tparams, 1)
        if strcmp(T_cpp_pupil.SubjID(s), Tparams.subjID(ss))
            T_cpp_pupil.accuracy(s) = Tparams.Accuracy(ss);
            T_cpp_pupil.DN(s) = Tparams.DN_miscal_h_normative(ss);
            T_cpp_pupil.LR(s) = Tparams.LR_miscal_h_normative(ss);
            T_cpp_pupil.H(s) = Tparams.H_miscal_h_normative(ss);
        end
    end
end

save([mask_dir, filesep, 'T_cpp_pupil.mat'], 'T_cpp_pupil')




%% graph delta_pupil vs accuracy

[R_older,P_older] = corrcoef(T_cpp_pupil.deltacpp_pupil(T_cpp_pupil.group == 2), T_cpp_pupil.accuracy(T_cpp_pupil.group == 2))
[R_young,P_young] = corrcoef(T_cpp_pupil.deltacpp_pupil(T_cpp_pupil.group == 1), T_cpp_pupil.accuracy(T_cpp_pupil.group == 1))

figure;
plot(T_cpp_pupil.deltacpp_pupil(T_cpp_pupil.group == 2), T_cpp_pupil.accuracy(T_cpp_pupil.group == 2), 'd',...
    'MarkerEdgeColor',[.75 0.5 0.5],'MarkerFaceColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1); 

h2 = lsline; set(h2(1),'color', [.75 0.5 0.5], 'LineWidth', 1);
hold on
plot(T_cpp_pupil.deltacpp_pupil(T_cpp_pupil.group == 1), T_cpp_pupil.accuracy(T_cpp_pupil.group == 1), 'o',...
    'MarkerEdgeColor', 'k','MarkerFaceColor', 'k','MarkerSize',6, 'LineWidth', 1); 
h2 = lsline; set(h2(2),'color', [.75 0.5 0.5], 'LineWidth', 1.5); set(h2(1),'color','k', 'LineWidth', 1.5); 

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'\Delta pupil (%)'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')

%% graph high cpp pupil vs accuracy

[R_older,P_older] = corrcoef(T_cpp_pupil.highcpp_pupil(T_cpp_pupil.group == 2), T_cpp_pupil.accuracy(T_cpp_pupil.group == 2))
[R_young,P_young] = corrcoef(T_cpp_pupil.highcpp_pupil(T_cpp_pupil.group == 1), T_cpp_pupil.accuracy(T_cpp_pupil.group == 1))

figure;
plot(T_cpp_pupil.highcpp_pupil(T_cpp_pupil.group == 1), T_cpp_pupil.accuracy(T_cpp_pupil.group == 1), 'o',...
    'MarkerEdgeColor', 'k','MarkerFaceColor', 'k','MarkerSize',6, 'LineWidth', 1); 
h2 = lsline; set(h2(1),'color','k', 'LineWidth', 1.5); 

hold on
plot(T_cpp_pupil.highcpp_pupil(T_cpp_pupil.group == 2), T_cpp_pupil.accuracy(T_cpp_pupil.group == 2), 'd',...
    'MarkerEdgeColor',[.75 0.5 0.5],'MarkerFaceColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1); 

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'Pupil (%)'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')


%% graph delta_pupil vs decision noise

[R_older,P_older] = corrcoef(T_cpp_pupil.deltacpp_pupil(T_cpp_pupil.group == 2), T_cpp_pupil.DN(T_cpp_pupil.group == 2))
[R_young,P_young] = corrcoef(T_cpp_pupil.deltacpp_pupil(T_cpp_pupil.group == 1), T_cpp_pupil.DN(T_cpp_pupil.group == 1))
[R_all,P_all] = corrcoef(T_cpp_pupil.deltacpp_pupil, T_cpp_pupil.DN)

figure;
plot(T_cpp_pupil.deltacpp_pupil(T_cpp_pupil.group == 1), T_cpp_pupil.DN(T_cpp_pupil.group == 1), 'o',...
    'MarkerEdgeColor', 'k','MarkerFaceColor', 'k','MarkerSize',6, 'LineWidth', 1); 
h2 = lsline; set(h2(1),'color','k', 'LineWidth', 1.5); 
hold on
plot(T_cpp_pupil.deltacpp_pupil(T_cpp_pupil.group == 2), T_cpp_pupil.DN(T_cpp_pupil.group == 2), 'd',...
    'MarkerEdgeColor',[.75 0.5 0.5],'MarkerFaceColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1); 

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'\Delta pupil (%)'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Decision noise', 'FontSize', 28, 'FontWeight','normal')

%% graph delta_pupil vs lapse rate

[R_older,P_older] = corrcoef(T_cpp_pupil.deltacpp_pupil(T_cpp_pupil.group == 2), T_cpp_pupil.LR(T_cpp_pupil.group == 2))
[R_young,P_young] = corrcoef(T_cpp_pupil.deltacpp_pupil(T_cpp_pupil.group == 1), T_cpp_pupil.LR(T_cpp_pupil.group == 1))
[R_all,P_all] = corrcoef(T_cpp_pupil.deltacpp_pupil, T_cpp_pupil.LR)

figure;
plot(T_cpp_pupil.deltacpp_pupil(T_cpp_pupil.group == 1), T_cpp_pupil.LR(T_cpp_pupil.group == 1), 'o',...
    'MarkerEdgeColor', 'k','MarkerFaceColor', 'k','MarkerSize',6, 'LineWidth', 1); 
% h2 = lsline; set(h2(1),'color','k', 'LineWidth', 1.5); 
hold on
plot(T_cpp_pupil.deltacpp_pupil(T_cpp_pupil.group == 2), T_cpp_pupil.LR(T_cpp_pupil.group == 2), 'd',...
    'MarkerEdgeColor',[.75 0.5 0.5],'MarkerFaceColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1); 

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'\Delta pupil (%)'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Lapse rate', 'FontSize', 28, 'FontWeight','normal')


%% comparison accross groups for high CPP and low CPP

% limo_random_robust(2,y1,y2,parameter number,LIMO)
%                    2 = two samples t-test
%                    y1 = data (dim channels, time or freq, subjects)
%                       = data (dim channels, freq, time, subjects)
%                       = the name of the Y1r file
%                    y2 = data (dim channels, time or freq, subjects)
%                       = data (dim channels, freq, time, subjects)
%                       = the name of the Y2r file
%                    parameter number = describe which parameter is currently analysed (e.g. 1 - use for maming only)
clear
load('D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil\expected_chanlocs_both.mat');
level2_ttest_dir = 'D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil_ruleswitch_deconv3events\level2_ttest_grpcomp_highCPP';
mkdir(level2_ttest_dir);
cd(level2_ttest_dir);

load('D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv\R_highlowCPP_ch.mat');

Y1(1, :, :) = R_highlowCPP_ch{1}(:, 1:1000)'; 
% no rule switch
Y2(1, :, :) = R_highlowCPP_ch{2}(:, 1:1000)'; 


LIMO = [];
% create LIMO variable
LIMO.Level                    = 2;

LIMO.Type = 'Channels';
LIMO.Analysis = 'Time';

LIMO.dir                      = level2_ttest_dir;

LIMO.data.data_dir            = level2_ttest_dir;
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

limo_random_robust(2,Y1,Y2,1,LIMO);

%%

mask = [];
limo_display_results(1,'two_samples_ttest_parameter_1_.mat',pwd,0.05, 2,...
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

%% average pupil across groups
% cluster 1 starts at 6000ms ends at 8400ms, max -3.21602 @ 8240ms channel AF3 
load('D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv\R_highlowCPP_ch.mat');
% high CPP
Yhcpp1 = [R_highlowCPP_ch{1}(:, 1:1000)']; 
Yhcpp2 = [R_highlowCPP_ch{2}(:, 1:1000)'];


mean_c1_diff = mean(mean(Yhcpp1((5+6) * 50:(5+8.4) * 50, :), 1))-mean(mean(Yhcpp2((5+6) * 50:(5+8.4) * 50, :), 1))

sd_c1_diff = std(mean(Yhcpp1((5+6) * 50:(5+8.4) * 50, :), 1)-mean(Yhcpp2((5+6) * 50:(5+8.4) * 50, :), 1))



%% comparison accros groups for low CPP

% limo_random_robust(2,y1,y2,parameter number,LIMO)
%                    2 = two samples t-test
%                    y1 = data (dim channels, time or freq, subjects)
%                       = data (dim channels, freq, time, subjects)
%                       = the name of the Y1r file
%                    y2 = data (dim channels, time or freq, subjects)
%                       = data (dim channels, freq, time, subjects)
%                       = the name of the Y2r file
%                    parameter number = describe which parameter is currently analysed (e.g. 1 - use for maming only)
clear
load('D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil\expected_chanlocs_both.mat');
level2_ttest_dir = 'D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil_ruleswitch_deconv3events\level2_ttest_grpcomp_lowCPP';
mkdir(level2_ttest_dir);
cd(level2_ttest_dir);

load('D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv\R_highlowCPP_ch.mat');

Y1(1, :, :) = R_highlowCPP_ch{1}(:, 1001:2000)'; 
% no rule switch
Y2(1, :, :) = R_highlowCPP_ch{2}(:, 1001:2000)'; 


LIMO = [];
% create LIMO variable
LIMO.Level                    = 2;

LIMO.Type = 'Channels';
LIMO.Analysis = 'Time';

LIMO.dir                      = level2_ttest_dir;

LIMO.data.data_dir            = level2_ttest_dir;
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

limo_random_robust(2,Y1,Y2,1,LIMO);

%

mask = [];
limo_display_results(1,'two_samples_ttest_parameter_1_.mat',pwd,0.05, 2,...
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