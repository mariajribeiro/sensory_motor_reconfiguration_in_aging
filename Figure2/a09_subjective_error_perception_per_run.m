% analyses of perception of errors as percentage of choice trials per
% run/block

clear; close all
load DSet.mat
Tsubjrep = readtable('D:\Project_LC_fMRI\data\perception_of_task_performance.xlsx');

error_perception_run = cell(2, 3);
missing_data = [];    runs_included = [];   
for s = 1:length(DSet.P)
    runs = cell(1, 1); p_errors_fulltask = []; p_errors_inf = [];
    sessions = unique(DSet.P(s).Data.SessionNum);
    subj = find(strcmp(Tsubjrep.SubtID, DSet.P(s).Spec.SubjID));


    if strcmp(DSet.P(s).Spec.Group, 'young_adults')
        grp = 1;
    else
        grp = 2;
    end

    for ss = 1:length(sessions)
        if ismember(sessions(ss), [3, 4]) % ignore inference only task and data in the scanner
            continue
        end

        runs{ss} = unique(DSet.P(s).Data.BlockNum(DSet.P(s).Data.SessionNum == sessions(ss)));

        for r = 1:length(runs{ss})

            % percentage of errors perceived per number of choice trials in
            % run
            ep = ['err_perceived = [Tsubjrep.S', num2str(sessions(ss)), 'R', num2str(runs{ss}(r)), '(', num2str(subj), ')];'];
            eval(ep);

            % calculate how many runs missing in relation to total number
            % of runs included
            if isnan(err_perceived)
                missing_data = [missing_data; str2double(DSet.P(s).Spec.SubjID(3:end)), sessions(ss), runs{ss}(r)];
            else
                runs_included = [runs_included; str2double(DSet.P(s).Spec.SubjID(3:end)), sessions(ss), runs{ss}(r)];
            end
            % number of choice trials in run
            idx_trls = find(DSet.P(s).Data.SessionNum == sessions(ss) & DSet.P(s).Data.BlockNum == runs{ss}(r));
            ch_trl = DSet.P(s).Data.TrialNum(idx_trls);

            % accuracy in run
            accuracy = mean(DSet.P(s).Data.Acc(DSet.P(s).Data.SessionNum == sessions(ss) & DSet.P(s).Data.BlockNum == runs{ss}(r)), 'omitnan');
            
            if ~isnan(err_perceived) && sessions(ss) < 3
                p_errors_fulltask = [p_errors_fulltask; err_perceived, ch_trl(end), accuracy];
            % elseif ~isnan(err_perceived) && sessions(ss) == 4
            %     p_errors_inf = [p_errors_inf; err_perceived, ch_trl(end), accuracy];
            end

        end


    end
    % if ~isempty(p_errors_inf)
    %     error_perception_run{grp, 1} = [error_perception_run{grp, 1}; mean((p_errors_fulltask(:, 1)./p_errors_fulltask(:, 2))./p_errors_fulltask(:, 3)),...
    %         mean((p_errors_fulltask(:, 1)./p_errors_fulltask(:, 2))./(1-p_errors_fulltask(:, 3))),...
    %         mean(p_errors_fulltask(:, 1)./p_errors_fulltask(:, 2)), mean(p_errors_fulltask(:, 3))];
    %     error_perception_run{grp, 2} = [error_perception_run{grp, 2}; mean((p_errors_inf(:, 1)./p_errors_inf(:, 2))./p_errors_inf(:, 3))];
    % else
        error_perception_run{grp, 1} = [error_perception_run{grp, 1}; mean((p_errors_fulltask(:, 1)./p_errors_fulltask(:, 2))./p_errors_fulltask(:, 3)),...
            mean(p_errors_fulltask(:, 1)./p_errors_fulltask(:, 2)), mean(p_errors_fulltask(:, 3))];
    % end
    error_perception_run{grp, 2} = [error_perception_run{grp, 3}; DSet.P(s).Spec.SubjID];  

end

subj_missing_data = unique(missing_data(:, 1));

% percentage of runs missing

perc_missing = size(missing_data, 1)/(size(missing_data, 1) + size(runs_included, 1));

%%

[h,p,ci,stats] = ttest2(error_perception_run{1, 1}, error_perception_run{2, 1})

mean(error_perception_run{1, 1})

mean(error_perception_run{2, 1})


[r,p] = corrcoef(error_perception_run{1, 1}, error_perception_run{2, 1})


%% lapses per correct
% error_perception_run{2, 1}(30, :) = [];
plot_2groups_variables(error_perception_run{1, 1}(:, 1), error_perception_run{2, 1}(:, 1),'Lapses/Accuracy',...
    '', ...
   1.5 , '')

axis([.5 2.5 -inf inf]);
ax = gca; ax.XAxis.FontSize = 24;
xtickangle(0);
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=10;
y0=10;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])


mean(error_perception_run{1, 1}(:, 1))
std(error_perception_run{1, 1}(:, 1))

mean(error_perception_run{2, 1}(:, 1))
std(error_perception_run{2, 1}(:, 1))

[h,p,ci,stats] = ttest2(error_perception_run{1, 1}(:, 1), error_perception_run{2, 1}(:, 1))



%%

plot_2groups_variables(error_perception_run{1, 1}, error_perception_run{2, 1},'Lapses/Accuracy',...
    '', ...
   1.5 , '')

axis([.5 2.5 -inf inf]);
ax = gca; ax.XAxis.FontSize = 24;
xtickangle(0);
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=10;
y0=10;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])


mean(error_perception_run{1, 1}(:, 1))
std(error_perception_run{1, 1}(:, 1))

mean(error_perception_run{2, 1}(:, 1))
std(error_perception_run{2, 1}(:, 1))

%% correlation accuracy lapse perception

% error_perception_run{grp, 1} = [error_perception_run{grp, 1}; mean((p_errors_fulltask(:, 1)./p_errors_fulltask(:, 2))./p_errors_fulltask(:, 3)),...
%     mean(p_errors_fulltask(:, 1)./p_errors_fulltask(:, 2)), mean(p_errors_fulltask(:, 3))];
% % lapses per accuracy, % lapses, accuracy

figure;
plot(error_perception_run{1, 1}(:, 2), error_perception_run{1, 1}(:, 3), 'ok')
lsline
hold on
plot(error_perception_run{2, 1}(:, 2), error_perception_run{2, 1}(:, 3), 'xr')
lsline
box off
% axis([0 .2 .45 1]);
ax = gca;
ax.LineWidth = 2.5; 
ax.FontSize = 24;
ax.FontName = 'Arial';
ax.Color = 'none';
xlabel('Lapses', 'FontSize', 30, 'FontWeight','normal')
ylabel('Accuracy', 'FontSize', 30, 'FontWeight','normal')
% title('Younger adults', 'FontSize', 24, 'FontWeight','normal')
%%
figure;
plot(error_perception_run{1, 1}(:, 2), error_perception_run{1, 1}(:, 3), 'ok')
lsline
hold on
plot(error_perception_run{2, 1}(:, 2), error_perception_run{2, 1}(:, 3), 'xr')
lsline
box off
% axis([0 .2 .45 1]);
ax = gca;
ax.LineWidth = 2.5; 
ax.FontSize = 24;
ax.FontName = 'Arial';
ax.Color = 'none';
xlabel('Lapses', 'FontSize', 30, 'FontWeight','normal')
ylabel('Accuracy', 'FontSize', 30, 'FontWeight','normal')


figure;
plot(error_perception_run{2, 1}(:, 2), error_perception_run{2, 1}(:, 3), 'or')
lsline
box off
axis([0 .2 .45 1]);
ax = gca;
ax.LineWidth = 2.5; 
ax.FontSize = 24;
ax.FontName = 'Arial';
ax.Color = 'none';
xlabel('Lapses', 'FontSize', 30, 'FontWeight','normal')
ylabel('Accuracy', 'FontSize', 30, 'FontWeight','normal')
title('Older adults', 'FontSize', 24, 'FontWeight','normal')




%% plot only participants with inference task

plot_2groups_variables(error_perception_run{1, 2}, error_perception_run{2, 2},'Lapses/Accuracy',...
    '', ...
   1.5 , '')

axis([.5 2.5 -inf inf]);
ax = gca; ax.XAxis.FontSize = 24;
xtickangle(0);
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=10;
y0=10;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])


mean(error_perception_run{1, 2}(:, 1))
std(error_perception_run{1, 2}(:, 1))

mean(error_perception_run{2, 2}(:, 1))
std(error_perception_run{2, 2}(:, 1))

%% function plot data 2 groups 7 variables
function plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% data with observations x variables
    figure;
    % plot data for group 1
    yMean=nanmean(data_grp1, 1);
    y_se = std(data_grp1,[], 1, 'omitnan')/sqrt(size(data_grp1, 1));
    
    pst = -2;
    for v = 1:size(data_grp1, 2)
        pst = pst + 3;
%         rectangle('Position',[pst-0.3,yMean(v)-y_se(v), 0.6, 2*y_se(v) ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
%         hold on
        for y=1:size(data_grp1, 1)
            plot(pst+rand*0.2-0.1, data_grp1(y, v),'-o', 'color', [.8 .8 .8], ...
            'MarkerEdgeColor',[.75 .75 .75],'MarkerSize',6, 'LineWidth', 1);
            hold on;
        end

%         % plot the mean line    
%         plot([pst-0.3 pst+0.3],[yMean(v) yMean(v)] ,'Color','k','LineWidth',2);
        bar(pst, yMean(v), 'FaceColor','None','EdgeColor',[0 0 0],'LineWidth',1.5);
        hold on
        errorbar(pst, yMean(v), y_se(v),"-","MarkerSize",2,...
            "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 1.5, 'color', 'k');
%         er.Color = [0 0 0];                            
%         er.LineStyle = 'none';  
    end
    
    % group 2
    yMean=nanmean(data_grp2, 1);
    y_se = std(data_grp2,[], 1, 'omitnan')/sqrt(size(data_grp2, 1));
    
    pst = -1;
    for v = 1:size(data_grp2, 2)
        pst = pst + 3;
%         rectangle('Position',[pst-0.3,yMean(v)-y_se(v), 0.6, 2*y_se(v) ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
%         hold on
        for y=1:size(data_grp2, 1)
            plot(pst+rand*0.2-0.1, data_grp2(y, v),'-d', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1);
            hold on;
        end

%         % plot the mean line    
%         plot([pst-0.3 pst+0.3],[yMean(v) yMean(v)] ,'Color','k','LineWidth',2);
        bar(pst, yMean(v), 'FaceColor','None','EdgeColor',[0 0 0],'LineWidth',1.5);
        hold on
            errorbar(pst, yMean(v), y_se(v),"-","MarkerSize",2,...
        "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 1.5, 'color', 'k')
    end

    % axes('XColor','none');
    hold off;     box off
%     axis([0 3 -inf inf]);
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    ax.XTickLabel= [];
    ax.XAxis.FontSize = 16;
    xticks(x_ticks);
    ax.XTickLabel= x_label_text;
    xtickangle(45)
    ylabel(y_label_text, 'FontSize', 30, 'FontWeight','normal')
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
    
    

    box off
    hold on
    for y=1:length(data_grp1_cond1)
        plot([1+rand*0.2-0.1, 2+rand*0.2-0.1], [data_grp1_cond1(y), data_grp1_cond2(y)], '-o', 'color', [.8 .8 .8], ...
            'MarkerEdgeColor',[.75 .75 .75],'MarkerSize',6, 'LineWidth', 1);
        hold on;
    end
    
    bar([1, 2], [yMean1 yMean2], 'FaceColor','None','EdgeColor',[0 0 0],'LineWidth',1.5);
    hold on
    errorbar([1 2], [yMean1 yMean2], [y_se1 y_se2],".", 'LineWidth', 1.5, 'color', 'k')
    
    
    % group 2
    % condition 1
    yMean1=nanmean(data_grp2_cond1);
    y_se1 = std(data_grp2_cond1,'omitnan')/sqrt(length(data_grp2_cond1));
        % condition 2
    yMean2=nanmean(data_grp2_cond2);
    y_se2 = std(data_grp2_cond2,'omitnan')/sqrt(length(data_grp2_cond2));
    
    box off
    
    
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
    ylabel(y_label_text, 'FontSize', 25, 'FontWeight','normal')
    title(title_text, 'FontSize', 24, 'FontWeight','normal')
%     x0=10;
%     y0=10;
%     width=400;
%     height=400;
%     set(gcf,'position',[x0,y0,width,height])
end