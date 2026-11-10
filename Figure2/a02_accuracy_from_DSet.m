clear
load DSet.mat
variable_names = {'SubjID', 'Group', 'GroupID', 'Accuracy', 'AccIdealObsvr', 'AccLAstSample', 'Acc_lab', 'Acc_scanner' 'Acc_Inference'};
name = {}; accuracy = []; accuracy_inference = NaN(size(DSet.P, 2), 1);
for sbj = 1:size(DSet.P, 2)
    
    name{sbj, 1} = DSet.P(sbj).Spec.SubjID;
    group{sbj, 1} = DSet.P(sbj).Spec.Group;
    if strcmp(DSet.P(sbj).Spec.Group, 'young_adults')
        group_numb(sbj, 1) = 1;
    else
        group_numb(sbj, 1) = 2;
    end
    accuracy(sbj, 1)= mean(DSet.P(sbj).Data.Acc(contains(DSet.P(sbj).Data.BlockType, 'full_task')), 'omitnan');
    accuracy_inference(sbj, 1) = mean(DSet.P(sbj).Data.Acc(contains(DSet.P(sbj).Data.BlockType, 'inference')), 'omitnan');
    
    accuracy_fulltask_lab(sbj, 1)= mean(DSet.P(sbj).Data.Acc(strcmp(DSet.P(sbj).Data.BlockType, 'full_task_lab')), 'omitnan');
    accuracy_fulltask_scanner(sbj, 1)= mean(DSet.P(sbj).Data.Acc(strcmp(DSet.P(sbj).Data.BlockType, 'full_task_scanner')), 'omitnan');
    
end

%% compare accuracy with subjective lapse perception
% load lapse data

lapse = readtable('subjective_err_perception.xlsx');

% reorder lapse to match accuracy
acc_lapse = [];
for s = 1:length(name)
    acc_lapse(s, 1) = accuracy_fulltask_lab(s);
    for ss = 1:size(lapse, 1)
        if strcmp(name{s}, lapse.SubjID(ss))
            acc_lapse(s, 2) = lapse.err_fulltask(ss);
        end
    end
     acc_lapse(s, 3) =  group_numb(s);
end

figure; 
plot(acc_lapse(acc_lapse(:, 3) == 1, 1), acc_lapse(acc_lapse(:, 3) == 1, 2), 'o')
lsline

figure; 
plot(acc_lapse(acc_lapse(:, 3) == 2, 1), acc_lapse(acc_lapse(:, 3) == 2, 2), 'x')
lsline

[r,p] = corrcoef(acc_lapse(acc_lapse(:, 3) == 1, 1), acc_lapse(acc_lapse(:, 3) == 1, 2))

[r,p] = corrcoef(acc_lapse(acc_lapse(:, 3) == 2, 1), acc_lapse(acc_lapse(:, 3) == 2, 2))


lapses_by_acc_young = acc_lapse(acc_lapse(:, 3) == 1, 2)./acc_lapse(acc_lapse(:, 3) == 1, 1)

lapses_by_acc_older = acc_lapse(acc_lapse(:, 3) == 2, 2)./acc_lapse(acc_lapse(:, 3) == 2, 1)

[h,p,ci,stats] = ttest2(lapses_by_acc_young, lapses_by_acc_older)


mean(lapses_by_acc_young)
std(lapses_by_acc_young)
mean(lapses_by_acc_older)
std(lapses_by_acc_older)


%% plot data
data_grp1 = accuracy(strcmp(group, 'young_adults'))*100;
data_grp2 = accuracy(strcmp(group, 'older_adults'))*100;

plot_all_data_2groups(data_grp1, data_grp2, 'Accuracy (%)', '')

%% include ideal observer and last sample accuracy on the graph
% calculated in L:\Project_LC_fMRI\analyses\behaviour\ideal_observer.m
load([pwd filesep 'results_behaviour\acc_ideal_obsv']); % young, older x outside scanner, inside scanner, inference only, subjects
load([pwd filesep 'results_behaviour\acc_last_sample']);

% save data in excel file for statistical analyses

%% write excel file with participants accuracy and idela observer + last sample
accuracy_idealosb = NaN(length(name), 1);
for n = 1:length(name)
    for grp = 1:2
        for i = 1:length(acc_ideal_obsv{grp, 1})
            if strcmp(acc_ideal_obsv{grp, 4}{i}, name{n})
                accuracy_idealosb(n) = mean([acc_ideal_obsv{grp, 1}(i), acc_ideal_obsv{grp, 2}(i)], 'omitnan');
            end
        end
    end
end


accuracy_lastsample = NaN(length(name), 1);
for n = 1:length(name)
    for grp = 1:2
        for i = 1:length(acc_last_sample{grp, 1})
            if strcmp(acc_last_sample{grp, 4}(i, :), name{n})
                accuracy_lastsample(n) = mean([acc_last_sample{grp, 1}(i), acc_last_sample{grp, 2}(i)], 'omitnan');
            end
        end
    end
end


% AccuracyTable = table(name, group, group_numb, accuracy, accuracy_idealosb, accuracy_lastsample, accuracy_fulltask_lab, accuracy_fulltask_scanner, accuracy_inference,...
%     'VariableNames', variable_names);
% 
% save AccuracyTable AccuracyTable
% 
% writetable(AccuracyTable,'AccuracyTable.xlsx')


% mean + se ideal observer - avg outside + inside scanner - full task
idealobs_mean = mean(mean([[acc_ideal_obsv{1, 1},acc_ideal_obsv{1, 2}];[acc_ideal_obsv{2, 1},acc_ideal_obsv{2, 2}]] , 2, 'omitnan'));
idealobs_se = std(mean([[acc_ideal_obsv{1, 1},acc_ideal_obsv{1, 2}];[acc_ideal_obsv{2, 1},acc_ideal_obsv{2, 2}]] , 2, 'omitnan'))/sqrt(size([acc_ideal_obsv{1, 1};acc_ideal_obsv{2, 1}], 1));

% mean + se ideal observer - avg outside + inside scanner - full task
lastsample_mean = mean(mean([[acc_last_sample{1, 1},acc_last_sample{1, 2}];[acc_last_sample{2, 1},acc_last_sample{2, 2}]] , 2, 'omitnan'));
lastsample_se = std(mean([[acc_last_sample{1, 1},acc_last_sample{1, 2}];[acc_last_sample{2, 1},acc_last_sample{2, 2}]] , 2, 'omitnan'))/sqrt(size([acc_last_sample{1, 1};acc_last_sample{2, 1}], 1));

%% plot accuracy data
data_grp1 = accuracy(strcmp(group, 'young_adults'))*100;
data_grp2 = accuracy(strcmp(group, 'older_adults'))*100;

plot_all_data_2groups(data_grp1, data_grp2, 'Accuracy (%)', '')
% add ideal observer
hold on
for x = 0.05:.05:3
    plot([x x], [idealobs_mean-idealobs_se, idealobs_mean+idealobs_se].*100, 'Color', [0.9500 0.4250 0.1980], 'LineWidth', 5);
end
plot([0.02 3], [idealobs_mean, idealobs_mean].*100, 'k');

% add last sample
hold on
for x = 0.05:.05:3
    plot([x x], [lastsample_mean-lastsample_se, lastsample_mean+lastsample_se].*100, 'Color', [1 0.7940 0.2250], 'LineWidth', 5);
end
plot([0.02 3], [lastsample_mean, lastsample_mean].*100, 'k');

%% plot data inference
data_grp1 = accuracy_inference(strcmp(group, 'young_adults'))*100;
data_grp2 = accuracy_inference(strcmp(group, 'older_adults'))*100;


plot_all_data_2groups(data_grp1, data_grp2, 'Accuracy (%)', 'inference-only')


%% plot data - comparison accuracy in the lab with accuracy in the scanner
idx_scn_young = find(accuracy_fulltask_scanner > 0 & strcmp(group, 'young_adults'));
idx_scn_older = find(accuracy_fulltask_scanner > 0 & strcmp(group, 'older_adults'));

% plot_2groups_2conditions(data_grp1_cond1,data_grp1_cond2, data_grp2_cond1, data_grp2_cond2, y_label_text, title_text, xaxis_text)

plot_2groups_2conditions(accuracy_fulltask_lab(idx_scn_young)*100,accuracy_fulltask_scanner(idx_scn_young)*100,...
    accuracy_fulltask_lab(idx_scn_older)*100, accuracy_fulltask_scanner(idx_scn_older)*100, 'Accuracy (%)', '', ...
    {'Lab' 'Scanner' 'Lab' 'Scanner'})


%% plot comparison across conditions
% plot_2groups_2conditions(data_grp1_cond1,data_grp1_cond2, data_grp2_cond1, data_grp2_cond2, y_label_text, title_text)
idx_inf_young = find(accuracy_inference > 0 & strcmp(group, 'young_adults'));
idx_inf_older = find(accuracy_inference > 0 & strcmp(group, 'older_adults'));
plot_2groups_2conditions(accuracy_fulltask_lab(idx_inf_young)*100, accuracy_inference(idx_inf_young)*100,...
    accuracy_fulltask_lab(idx_inf_older)*100, accuracy_inference(idx_inf_older)*100, 'Accuracy (%)', '', ...
    {'Full task' 'Inference' 'Full task' 'Inference'})

mean(accuracy_fulltask_lab(idx_inf_young)*100)
std(accuracy_fulltask_lab(idx_inf_young)*100)

mean(accuracy_fulltask_lab(idx_inf_older)*100)
std(accuracy_fulltask_lab(idx_inf_older)*100)

mean(accuracy_inference(idx_inf_young)*100)
std(accuracy_inference(idx_inf_young)*100)

mean(accuracy_inference(idx_inf_older)*100)
std(accuracy_inference(idx_inf_older)*100)


[h,p,ci,stats] = ttest2(accuracy_inference(idx_inf_young)*100, accuracy_inference(idx_inf_older)*100)


%% function plot data 2 groups 1 task
function plot_all_data_2groups(data_grp1, data_grp2, y_label_text, title_text)
       figure;
    % plot data for group 1
    yMean1=nanmean(data_grp1);
    y_se1 = std(data_grp1,'omitnan')/sqrt(length(data_grp1));
    
    % condition 2
    yMean2=nanmean(data_grp2);
    y_se2 = std(data_grp2,'omitnan')/sqrt(length(data_grp2));
    

    for y=1:length(data_grp1)
        plot(1+rand*0.3-0.15, data_grp1(y),'-o', 'color', [.8 .8 .8], ...
            'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',6, 'LineWidth', 1.5);
        hold on;
    end
%     %plot line at accuracy of ideal observed  
%     plot([0 3],[0.92 0.92],'--k','LineWidth', 1);
%     %plot line at accuracy of last sample  
%     plot([0 3],[0.74 0.74],'--k','LineWidth', 1);
   
   
    for y=1:length(data_grp2)
        plot(2+rand*0.3-0.15, data_grp2(y) ,'-o',  'color', [1 .5 .5], ...
            'MarkerEdgeColor',[.5 0 0],'MarkerSize',6, 'LineWidth', 1.5);
        hold on;
    end

    
    errorbar([1 2], [yMean1 yMean2], [y_se1 y_se2],"o","MarkerSize",7,...
    "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 1.5, 'color', 'k')
    hold on

    % axes('XColor','none');
    box off
    axis([0.5 2.5 50 100]);
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
%     ax.XTickLabel= [];
    ax.XAxis.FontSize = 24;
    ax.XTickLabel= {'YA' 'OA'};
    xticks([1 2])
    ylabel(y_label_text, 'FontSize', 30, 'FontWeight','normal')
    title(title_text, 'FontSize', 32, 'FontWeight','normal')

    x0=10;
    y0=10;
    width=300;
    height=400;
    set(gcf,'position',[x0,y0,width,height])
end

% %% function plot data 2 groups 1 task
% function plot_all_data_2groups(data_grp1, data_grp2, y_label_text, title_text)
%        figure;
%     % plot data for group 1
%     yMean=nanmean(data_grp1);
%     y_se = std(data_grp1,'omitnan')/sqrt(length(data_grp1));
%     
%         %plot the mean+-SEM box
%         %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
% %   Specify pos as a four-element vector of the form [x y w h] in data
% %   units. The x and y elements determine the location and the w and h
% %   elements determine the size. The function plots into the current axes
% %   without clearing existing content from the axes.
%     box off
%     rectangle('Position',[1-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
%     hold on
%     for y=1:length(data_grp1)
%         plot(1+rand*0.2-0.1, data_grp1(y),'-o', 'color', [.8 .8 .8], ...
%             'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',6, 'LineWidth', 1.5);
%         hold on;
%     end
% %     %plot line at accuracy of ideal observed  
% %     plot([0 3],[0.92 0.92],'--k','LineWidth', 1);
% %     %plot line at accuracy of last sample  
% %     plot([0 3],[0.74 0.74],'--k','LineWidth', 1);
%      %plot the mean line    
%     plot([1-0.3 1+0.3],[yMean yMean] ,'Color','k','LineWidth',5);
%    
% 
%     % group 2
%     yMean=nanmean(data_grp2);
%     y_se = std(data_grp2,'omitnan')/sqrt(length(data_grp2));
%    rectangle('Position',[2-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1)
%    
%     for y=1:length(data_grp2)
%         plot(2+rand*0.2-0.1, data_grp2(y) ,'-o',  'color', [1 .5 .5], ...
%             'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',6, 'LineWidth', 1.5);
%         hold on;
%     end
% 
%     %plot the mean line
%     plot([2-0.3 2+0.3],[yMean yMean] ,'Color', 'k','LineWidth',5);
% %     hold on
% %     plot([0, 3], [74, 74], '--k') % last sample
% %     hold on
% %     plot([0, 3], [91, 91], '--k') % ideal observer
% 
%     % axes('XColor','none');
%     axis([0 3 50 100]);
%     ax = gca;
%     ax.LineWidth = 2.5; 
%     ax.FontSize = 24;
%     ax.FontName = 'Arial';
%     ax.Color = 'none';
% %     ax.XTickLabel= [];
%     ax.XAxis.FontSize = 30;
%     ax.XTickLabel= {'' 'Young' 'Older'};
% %     xticks([1 2])
%     ylabel(y_label_text, 'FontSize', 30, 'FontWeight','normal')
%     title(title_text, 'FontSize', 32, 'FontWeight','normal')
% 
% %     x0=10;
% %     y0=10;
% %     width=400;
% %     height=400;
% %     set(gcf,'position',[x0,y0,width,height])
% end



%% function plot data 2 groups, 2 conditions
function plot_2groups_2conditions(data_grp1_cond1,data_grp1_cond2, data_grp2_cond1, data_grp2_cond2, y_label_text, title_text, xaxis_text)
    figure;
    % plot data for group 1
    yMean=nanmean(data_grp1_cond1);
    y_se = std(data_grp1_cond1,'omitnan')/sqrt(length(data_grp1_cond1));
    
        %plot the mean+-SEM box
        %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
%   Specify pos as a four-element vector of the form [x y w h] in data
%   units. The x and y elements determine the location and the w and h
%   elements determine the size. The function plots into the current axes
%   without clearing existing content from the axes.
    box off
    rectangle('Position',[1-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    hold on 
    %plot the mean line    
    plot([1-0.3 1+0.3],[yMean yMean] ,'Color','k','LineWidth',5);
    % condition 2
    yMean=nanmean(data_grp1_cond2);
    y_se = std(data_grp1_cond2,'omitnan')/sqrt(length(data_grp1_cond2));
    box off
    rectangle('Position',[2-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    hold on
    %plot the mean line    
    plot([2-0.3 2+0.3],[yMean yMean] ,'Color','k','LineWidth',5);
    hold on
    for y=1:length(data_grp1_cond1)
        plot([1+rand*0.2-0.1, 2+rand*0.2-0.1], [data_grp1_cond1(y), data_grp1_cond2(y)], '-o', 'color', [.8 .8 .8], ...
            'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',6, 'LineWidth', 1);
        hold on;
    end

    % group 2
    yMean=nanmean(data_grp2_cond1);
    y_se = std(data_grp2_cond1,'omitnan')/sqrt(length(data_grp2_cond1));
    
    box off
    rectangle('Position',[4-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    hold on
    %plot the mean line    
    plot([4-0.3 4+0.3],[yMean yMean] ,'Color','k','LineWidth',5);
    % condition 2
    yMean=nanmean(data_grp2_cond2);
    y_se = std(data_grp2_cond2,'omitnan')/sqrt(length(data_grp2_cond2));
    box off
    rectangle('Position',[5-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    hold on
    %plot the mean line    
    plot([5-0.3 5+0.3],[yMean yMean] ,'Color','k','LineWidth',5);
    hold on
    for y=1:length(data_grp1_cond1)
        plot([4+rand*0.2-0.1, 5+rand*0.2-0.1], [data_grp2_cond1(y), data_grp2_cond2(y)], '-o', 'color', [.8 .8 .8], ...
            'MarkerEdgeColor',[.5 0 0],'MarkerSize',6, 'LineWidth', 1);
        hold on;
    end
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
    ax.XAxis.FontSize = 30;
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