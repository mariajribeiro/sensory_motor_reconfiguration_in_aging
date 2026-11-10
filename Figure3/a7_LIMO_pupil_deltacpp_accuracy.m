%% time point by time point regressio associating teh amplitude of pupil locked with high CPP with accuracy
clear; close all
dir_beh = 'D:\Project_LC_fMRI\analyses\behaviour\';
load([dir_beh, 'AccuracyTable.mat']);
save_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv';
% load reg_coeff_deriv
load([save_dir, filesep, 'R_highlowCPP_ch']);

addpath('D:\Project_LC_fMRI\analyses')
group = participants_included;

accuracy = cell(2, 1);
acc_sbj = cell(2, 1);

accuracy{1} = AccuracyTable.Accuracy(strcmp(AccuracyTable.Group, 'young_adults'));
accuracy{2} = AccuracyTable.Accuracy(strcmp(AccuracyTable.Group, 'older_adults'));

acc_sbj{1} = AccuracyTable.SubjID(strcmp(AccuracyTable.Group, 'young_adults'));
acc_sbj{2} = AccuracyTable.SubjID(strcmp(AccuracyTable.Group, 'older_adults'));

coef_low_accuracy = cell(2, 1); coef_high_accuracy = cell(2, 1);
sbj_low_accuracy = []; sbj_high_accuracy = [];
for grp = 1:2
    sbj_low_accuracy = acc_sbj{grp}(accuracy{grp} <= median(accuracy{grp}, 'omitnan'));
    sbj_high_accuracy = acc_sbj{grp}(accuracy{grp} > median(accuracy{grp}, 'omitnan'));

    for sbj = 1:length(group{grp})
        if ismember(group{grp}(sbj), sbj_low_accuracy)
            coef_low_accuracy{grp} = [coef_low_accuracy{grp}; sbj];
        elseif ismember(group{grp}(sbj), sbj_high_accuracy)
            coef_high_accuracy{grp} = [coef_high_accuracy{grp}; sbj];
        end
    end
end


%% run level 2 regression level 2 across subjects with task accuracy
% age groups separate

eeglab;
pupil_folder = fileparts(pwd);
load([pupil_folder, '\LIMO_pupil\expected_chanlocs_both.mat']);

group_name = {'young', 'older'};

for grp = 1:2
    % run only Level 2
    % limo_random_robust(4,y,X,parameter number,LIMO)
    %                    4 = regression analysis
    %                    y = data (dim channels, time or freq, subjects)
    %                      = data (dim channels, freq, time, subjects)
    %                    X = continuous regressor(s)
    %                    parameter number = describe which parameter is currently analysed (e.g. 1 - use for maming only)

    y = [];
    % pupil_evoked_rule_switches_nobsln_HD = sbj x time x coefficients
    % difference between respone to high and response to low CPP
    for sbj = 1:size(R_highlowCPP_ch{grp, 1}, 1)
            y(1, :, sbj) = R_highlowCPP_ch{grp, 1}(sbj, 1:1000)-R_highlowCPP_ch{grp, 1}(sbj, 1001:2000);
    end
    
    % create continuous variable with individual accuracy values
    
    acc = [];
    for s = 1:length(acc_sbj{grp})
        for a = 1:size(y, 3)
            if strcmp(group{grp}(s), acc_sbj{grp}(a))
                acc = [acc; accuracy{grp}(a)];
            end
        end
    end

    level2_dir = [pwd filesep 'effect_of_acc_deltacpp_regression_', group_name{grp}];
    mkdir(level2_dir)
    cd(level2_dir)

    % create LIMO variable
    LIMO = [];
    LIMO.Level = 2;

    LIMO.Type = 'Channels';
    LIMO.Analysis = 'Time';

    LIMO.dir                      = level2_dir;
    LIMO.data.data_dir            = level2_dir;
    % LIMO.data.data                = 
    LIMO.data.start               = -5000;
    LIMO.data.end                 = 14998;
    LIMO.data.trim1               = 1; 
    LIMO.data.trim2               = size(y, 2);
    LIMO.data.timevect            = -5000:20:14998; 
    LIMO.data.sampling_rate       = 50;

    LIMO.data.neighbouring_matrix = channeighbstructmat(1, 1);
    LIMO.data.chanlocs = expected_chanlocs(1);
%     LIMO.design.method            = 'Trimmed mean'; 
    LIMO.design.type_of_analysis  = 'Mass-univariate';
    LIMO.design.bootstrap         = 1000; 
    LIMO.design.tfce              = 0;

    save LIMO LIMO
    save y y
    save acc acc

    % limo_random_robust(4,y,X,parameter number,LIMO)
    limo_random_robust(4,y, acc, 1,LIMO)
    %% view results  - clustering
    % https://github.com/LIMO-EEG-Toolbox/limo_tools/wiki/Workspace_variables
    
    mask = [];
    limo_display_results(1,'Covariate_effect_1.mat',pwd,0.05, 2,...
        fullfile(pwd,'LIMO.mat'), 0);
    if ~isempty(mask)
        save mask_covariate mask
        save stat_values_covariate stat_values %F/t values
        save p_values_covariate p_values

        [row,col] = find(mask == 1);
        max_time = max(col)*2+51;

        number_clusters = max(unique(mask(:)));
        p_value_cluster = p_values(mask == 1);
        max_p_value = max(p_values(mask ~= 0));
        %     what is the range of significant F/t values? 
%         stats_F = [min(stat_values(mask ~= 0)) max(stat_values(mask ~= 0))];
    else
        save mask_covariate mask
    end
%%    
    cd ..

end


%% graphs - low vs high performers - delta pupil - difference high -low CPP response
% group = {'Young', 'Older'};
group_name = {'young', 'older'};
graph_title = {'Young Adults', 'Older Adults'};
xaxis = -5:.020:14.998;  chn = 1; 
save_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv';
% load reg_coeff_deriv
load([save_dir, filesep, 'R_highlowCPP_ch']);

for grp = 1:2

    sig_time = [];
    data_low_acc = R_highlowCPP_ch{grp, 1}(coef_low_accuracy{grp},1:1000) - R_highlowCPP_ch{grp, 1}(coef_low_accuracy{grp},1001:2000);
    data_high_acc = R_highlowCPP_ch{grp, 1}(coef_high_accuracy{grp}, 1:1000) - R_highlowCPP_ch{grp, 1}(coef_high_accuracy{grp}, 1001:2000);
    
    level2_dir = [pwd filesep 'effect_of_acc_deltacpp_regression_', group_name{grp}];
    if exist([level2_dir, filesep, 'mask_covariate.mat'], 'file')
        load([level2_dir, filesep, 'mask_covariate.mat']);
        sig_time = (find(mask > 0));
    end
%         plot_coefsvstime_2groups(data_grp1, data_grp2, y_label_text, title_text, xaxis, sig_time, color1, color2)
    plot_coefsvstime_2groups(data_high_acc, data_low_acc, '\Delta Pupil (% mean)', graph_title(grp),...
        xaxis, sig_time, [93, 58, 155]/255, [230, 97, 0]/255)
    hold on
    plot([0 0], [-.015 0.025], '--k');
    axis([-inf inf -.015 0.025])

end


%% scatter plot between delta cpp pupil and accuracy
% find the intersection between the significant period across groups
group_name = {'young', 'older'};
save_dir = 'D:\Project_LC_fMRI\analyses\pupil\pupil_rule_switches\deconv\pupil_rule_switches_deconv';
load([save_dir, filesep, 'R_highlowCPP_ch']);
sig_time = {};
for grp = 1:2

    data_deltacpp{grp} = R_highlowCPP_ch{grp, 1}(:,1:1000) - R_highlowCPP_ch{grp, 1}(:,1001:2000);
    
    level2_dir = [pwd filesep 'effect_of_acc_deltacpp_regression_', group_name{grp}];
    if exist([level2_dir, filesep, 'mask_covariate.mat'], 'file')
        load([level2_dir, filesep, 'mask_covariate.mat']);
        sig_time{grp} = (find(mask > 0));
    end
end

sig_time_intersect = intersect(sig_time{1}, sig_time{2});


% average within the sig time window different for each group where the
% regression was significant
figure;
plot(mean(data_deltacpp{2}(:, sig_time{2}), 2), AccuracyTable.Accuracy(AccuracyTable.GroupID == 2), 'd',...
    'MarkerEdgeColor',[.75 0.5 0.5],'MarkerFaceColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1); 
hold on
[R,P] = corrcoef(mean(data_deltacpp{2}(:, sig_time{2}), 2), AccuracyTable.Accuracy(AccuracyTable.GroupID == 2));
if P(1, 2) < .05
    lsline%h1 = lsline; set(h1(1),'color','r'); 
end
hold on
plot(mean(data_deltacpp{1}(:, sig_time{1}), 2), AccuracyTable.Accuracy(AccuracyTable.GroupID == 1), 'o',...
    'MarkerEdgeColor', 'k','MarkerFaceColor', 'k','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(mean(data_deltacpp{1}(:, sig_time{1}), 2), AccuracyTable.Accuracy(AccuracyTable.GroupID == 1))
if P(1, 2) < .05
    h2 = lsline; set(h2(1),'color','k', 'LineWidth', 2);  set(h2(2),'color', [.75 .5 .5], 'LineWidth', 2); 
end

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'\Delta Pupil (% mean)'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')


%% using the time window where there was a significant condition x group interaction

level2_dir = 'D:\Project_LC_fMRI\analyses\pupil\LIMO_pupil_ruleswitch_deconv3events\level2_RM_ANOVA_pupil_grp_highlowCPP';
if exist([level2_dir, filesep, 'mask_interaction.mat'], 'file')
    load([level2_dir, filesep, 'mask_interaction.mat']);
    sig_time_interaction = (find(mask > 0));
end

figure;
plot(mean(data_deltacpp{2}(:, sig_time_interaction), 2), AccuracyTable.Accuracy(AccuracyTable.GroupID == 2), 'd',...
    'MarkerEdgeColor',[.75 0.5 0.5],'MarkerFaceColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1); 
hold on
[R,P] = corrcoef(mean(data_deltacpp{2}(:, sig_time_interaction), 2), AccuracyTable.Accuracy(AccuracyTable.GroupID == 2));
if P(1, 2) < .05
    lsline%h1 = lsline; set(h1(1),'color','r'); 
end
hold on
plot(mean(data_deltacpp{1}(:, sig_time_interaction), 2), AccuracyTable.Accuracy(AccuracyTable.GroupID == 1), 'o',...
    'MarkerEdgeColor', 'k','MarkerFaceColor', 'k','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(mean(data_deltacpp{1}(:, sig_time_interaction), 2), AccuracyTable.Accuracy(AccuracyTable.GroupID == 1))
if P(1, 2) < .05
    h2 = lsline; set(h2(1),'color','k', 'LineWidth', 2);  set(h2(2),'color', [.75 .5 .5], 'LineWidth', 2); 
end

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'\Delta Pupil (% mean)'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')


%%
figure;
plot(mean(R_highlowCPP_ch{2}(:, sig_time_interaction), 2), AccuracyTable.Accuracy(AccuracyTable.GroupID == 2), 'd',...
    'MarkerEdgeColor',[.75 0.5 0.5],'MarkerFaceColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1); 
hold on
[R,P] = corrcoef(mean(R_highlowCPP_ch{2}(:, sig_time_interaction), 2), AccuracyTable.Accuracy(AccuracyTable.GroupID == 2));
if P(1, 2) < .05
    lsline%h1 = lsline; set(h1(1),'color','r'); 
end
hold on
plot(mean(R_highlowCPP_ch{1}(:, sig_time_interaction), 2), AccuracyTable.Accuracy(AccuracyTable.GroupID == 1), 'o',...
    'MarkerEdgeColor', 'k','MarkerFaceColor', 'k','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(mean(R_highlowCPP_ch{1}(:, sig_time_interaction), 2), AccuracyTable.Accuracy(AccuracyTable.GroupID == 1))
if P(1, 2) < .05
    h2 = lsline; set(h2(1),'color','k', 'LineWidth', 2);  set(h2(2),'color', [.75 .5 .5], 'LineWidth', 2); 
end

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'Pupil (% mean)'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')


%% plot regression coefficients
group_name = {'young', 'older'};
sig_time = {}; betas_deltacpp = {};
for grp = 1:2
    level2_dir = [pwd filesep 'effect_of_acc_deltacpp_regression_', group_name{grp}];
    load([level2_dir, filesep, 'Betas.mat']);
    betas_deltacpp{grp} = squeeze(Betas(:, :, 1));
    if exist([level2_dir, filesep, 'mask_covariate.mat'], 'file')
        load([level2_dir, filesep, 'mask_covariate.mat']);
        sig_time{grp} = (find(mask > 0));
    end
end

figure
plot(xaxis, betas_deltacpp{1}, 'k', 'LineWidth', 1.5)
hold on
plot(xaxis, betas_deltacpp{2}, 'Color', [.75 0 0], 'LineWidth', 1.5)
hold on
% plot horizontal line where regression is significant
plot(xaxis(sig_time{1}), ones(length(sig_time{1}), 1)*-.003, 's', 'color', 'k', 'MarkerFaceColor', 'k', MarkerSize=6);
hold on
% plot horizontal line where regression is significant
plot(xaxis(sig_time{2}), ones(length(sig_time{2}), 1)*-.004, 's', 'Color', [.75 0 0], 'MarkerFaceColor', [.75 0 0], MarkerSize=6);
hold on
xline(0, '--'); yline(0, '--');
hold off
box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded
xlabel('Time (s)', 'FontSize', 28, 'FontWeight','normal')
ylabel('Regression coefficients', 'FontSize', 27, 'FontWeight','normal')
% title(title_text, 'FontSize', 24, 'FontWeight','normal')





%% functions

function plot_coefsvstime_2groups(data_grp1, data_grp2, y_label_text, title_text, xaxis, sig_time, color1, color2)
    if nargin == 6
        color1 = 'k'; color2 = 'r';
    end


    % data_grp1 = subjects x time
    
    mean_data1 = mean(data_grp1, 1);
    se_data1 = std(data_grp1, [], 1)/sqrt(size(data_grp1, 1));
    
    mean_data2 = mean(data_grp2, 1);
    se_data2 = std(data_grp2, [], 1)/sqrt(size(data_grp2, 1));
    
%     min_data = min([min(mean_data1), min(mean_data2)]);
%     pos_sig_line = min_data;
    pos_sig_line = -.01;
    figure;
%     xaxis = 4:2:1000;
    plot(xaxis, mean_data1, 'LineWidth', 1.5, 'color', color1); hold on
    jbfill(xaxis, mean_data1+se_data1, mean_data1-se_data1,  color1,  color1, 1, 0.25)
    hold on;
    if ~isempty(mean_data2)
        plot(xaxis, mean_data2, '--', 'LineWidth', 1.5, 'color', color2); hold on
        jbfill(xaxis, mean_data2+se_data2, mean_data2-se_data2, color2, color2, 1, 0.25)
        hold on;
    end
    % plot horizontal line where groups are significantly different
    plot(xaxis(sig_time), ones(length(sig_time), 1)*pos_sig_line, 's', 'color', 'k', 'MarkerFaceColor', 'k');
    % zero line
    hold on
    plot(xaxis, zeros(length(xaxis)), '--k');
    hold off
    box off
    ax = gca; ax.LineWidth = 2.5;
    ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
%     if ~isempty(sig_time) && pos_sig_line <= 0
%         axis([-inf inf pos_sig_line-.3*abs(pos_sig_line) inf])
%     end
%     axis([-inf inf -.07 0.12])
    ylim padded
    xlabel('Time from high CPP (s)', 'FontSize', 24, 'FontWeight','normal')
    ylabel(y_label_text, 'FontSize', 28, 'FontWeight','normal')
    title(title_text, 'FontSize', 24, 'FontWeight','normal')

end
