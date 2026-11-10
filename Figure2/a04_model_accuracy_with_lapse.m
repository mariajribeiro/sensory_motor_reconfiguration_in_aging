
clear; close all

% load simulated data
load([pwd, filesep, 'simulationsDec2024\SimTrlDSet_twoLvlAll_miscal-h-normative-lapse_forExport.mat']);

% load real data
load([pwd, filesep, 'model_resultsSep2024\TrlDSet_forExport_240911.mat']);

accuracy = cell(2, 1);
model_acc = cell(2, 1);     

subj_yng = {}; subj_old = {};

yng = 0; old = 0;
for p = 1:length(SimTrlDSet.P)
    
   if strcmp(SimTrlDSet.P(p).Spec.Group, 'young_adults')
       grp = 1; yng = yng + 1;
       a = yng;
       subj_yng = [subj_yng; SimTrlDSet.P(p).Spec.SubjID];
   else
       grp = 2; old = old + 1;
       a = old;
       subj_old = [subj_old; SimTrlDSet.P(p).Spec.SubjID];
   end
   model_acc{grp}= [model_acc{grp}; mean(SimTrlDSet.P(p).Data.Acc(contains(SimTrlDSet.P(p).Data.BlockType, 'full_task')), 'omitnan')];

   
   if strcmp(TrlDSet.P(p).Spec.Group, 'young_adults')
       grp = 1; yng = yng + 1;
       a = yng;
       subj_yng = [subj_yng; TrlDSet.P(p).Spec.SubjID];
   else
       grp = 2; old = old + 1;
       a = old;
       subj_old = [subj_old; TrlDSet.P(p).Spec.SubjID];
   end
   accuracy{grp}= [accuracy{grp}; mean(TrlDSet.P(p).Data.Acc(contains(TrlDSet.P(p).Data.BlockType, 'full_task')), 'omitnan')];

end

   

%% accuracy - participants' and model accuracy    
        plot_2groups_variables([accuracy{1}.*100, model_acc{1}.*100], [accuracy{2}.*100, model_acc{2}.*100],'Accuracy (%)',...
    '', ...
   [1.5, 4.5] , '')
axis([.5 5.5 50 100]);
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0);
    xticks([1 2 4 5])
    xticklabels({'YA', 'OA', 'YA', 'OA'});
    x0=10;
    y0=10;
    width=600;
    height=400;
    set(gcf,'position',[x0,y0,width,height])

%% accuracy both groups and model accuracy
% plot the group average fit with SEM as a separate marker on top of the bar graphs for the data. 
plot_2groups_variables(accuracy{1}.*100, accuracy{2}.*100,'Accuracy (%)',...
    '', ...
   1.5 , '')
hold on
errorbar([1.2 2.2], [mean(model_acc{1}.*100), mean(model_acc{2}.*100)],...
    [std(model_acc{1}.*100)/sqrt(length(model_acc{1})), std(model_acc{2}.*100)/sqrt(length(model_acc{2}))],...
    'o', 'color', 'k', 'LineWidth', 1.5,...
    'MarkerFaceColor', 'g', 'MarkerEdgeColor','k')

axis([.5 2.5 50 100]);
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0);
    xticks([1 2])
    xticklabels({'YA', 'OA'});
    x0=10;
    y0=10;
    width=300;
    height=400;
    set(gcf,'position',[x0,y0,width,height])


[h,p_value,ci,stats] = ttest2(accuracy{1}, accuracy{2})
mean(accuracy{1})
mean(accuracy{2})
std(accuracy{1})
std(accuracy{2})

    
%% model accuracy    
plot_2groups_variables(model_acc{1}.*100, model_acc{2}.*100,'Accuracy (%)',...
    '', ...
   1.5 , '')
axis([.5 2.5 50 100]);
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0);
    xticks([1 2])
    xticklabels({'YA', 'OA'});
    x0=10;
    y0=10;
    width=300;
    height=400;
    set(gcf,'position',[x0,y0,width,height])

%%
plot_2groups_2conditions(accuracy{1}.*100, model_acc{1}.*100,...
    accuracy{2}.*100, model_acc{2}.*100, {'Accuracy (%)'}, '', {'Data', 'Simulated'})
axis([0 6, 50, 100]);

[h,p,ci,stats] = ttest2(accuracy{1}(:, 1), accuracy{2}(:, 1))

[h,p,ci,stats] = ttest2(model_acc{1}, model_acc{2})

%% function plot data 2 groups 1 task
function plot_all_data_2groups(data_grp1, data_grp2, y_label_text, title_text)
       figure;
    % plot data for group 1
    yMean=nanmean(data_grp1);
    y_se = std(data_grp1,'omitnan')/sqrt(length(data_grp1));
    
% plot the mean+-SEM box
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
            'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',12, 'LineWidth', 1.5);
        hold on;
    end
%     %plot line at accuracy of ideal observed  
%     plot([0 3],[0.92 0.92],'--k','LineWidth', 1);
%     %plot line at accuracy of last sample  
%     plot([0 3],[0.74 0.74],'--k','LineWidth', 1);
     %plot the mean line    
    plot([1-0.3 1+0.3],[yMean yMean] ,'Color','k','LineWidth',5);
   

    % group 2
    yMean=nanmean(data_grp2);
    y_se = std(data_grp2,'omitnan')/sqrt(length(data_grp2));
   rectangle('Position',[2-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1)
   
    for y=1:length(data_grp2)
        plot(2+rand*0.2-0.1, data_grp2(y) ,'-o',  'color', [1 .5 .5], ...
            'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',12, 'LineWidth', 1.5);
        hold on;
    end

    %plot the mean line
    plot([2-0.3 2+0.3],[yMean yMean] ,'Color', 'k','LineWidth',5);
%     hold on
%     plot([0, 3], [74, 74], '--k') % last sample
%     hold on
%     plot([0, 3], [91, 91], '--k') % ideal observer

    % axes('XColor','none');
    hold off;
    axis([0 3 -inf inf]);
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
%     ax.XTickLabel= [];
    ax.XAxis.FontSize = 30;
    ax.XTickLabel= {'' 'Young' 'Older'};
%     xticks([1 2])
    ylabel(y_label_text, 'FontSize', 30, 'FontWeight','normal')
    title(title_text, 'FontSize', 32, 'FontWeight','normal')

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


%% function plot data 2 groups 7 variables
function plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% data with observations x variables
    figure;
    % plot data for group 1
    yMean=nanmean(data_grp1, 1);
    y_se = std(data_grp1,[], 1, 'omitnan')/sqrt(size(data_grp1, 1));
    
        %plot the mean+-SEM box
        %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
%   Specify pos as a four-element vector of the form [x y w h] in data
%   units. The x and y elements determine the location and the w and h
%   elements determine the size. The function plots into the current axes
%   without clearing existing content from the axes.
    pst = -2;
    for v = 1:size(data_grp1, 2)
        pst = pst + 3;
%         rectangle('Position',[pst-0.3,yMean(v)-y_se(v), 0.6, 2*y_se(v) ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
%         hold on
        for y=1:size(data_grp1, 1)
            plot(pst+rand*0.2-0.1, data_grp1(y, v),'-o', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.75 .75 .75],'MarkerSize', 5, 'LineWidth', 1.5);
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
    
        %plot the mean+-SEM box
        %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
%   Specify pos as a four-element vector of the form [x y w h] in data
%   units. The x and y elements determine the location and the w and h
%   elements determine the size. The function plots into the current axes
%   without clearing existing content from the axes.
    pst = -1;
    for v = 1:size(data_grp2, 2)
        pst = pst + 3;
%         rectangle('Position',[pst-0.3,yMean(v)-y_se(v), 0.6, 2*y_se(v) ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
%         hold on
        for y=1:size(data_grp2, 1)
            plot(pst+rand*0.2-0.1, data_grp2(y, v),'-d', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.75 0.5 0.5],'MarkerSize',5, 'LineWidth', 1.5);
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

%% function plot data 1 group 7 variables
function bg = plot_1group_variables(data_grp1, y_label_text, x_label_text, x_ticks, title_text)
% data with observations x variables
    figure;
    % plot data for group 1
    yMean=nanmean(data_grp1, 1);
    y_se = std(data_grp1,[], 1, 'omitnan')/sqrt(size(data_grp1, 1));
    
    pst = 0;
    for v = 1:size(data_grp1, 2)
        pst = pst + 1;
%         rectangle('Position',[pst-0.3,yMean(v)-y_se(v), 0.6, 2*y_se(v) ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
%         hold on
        for y=1:size(data_grp1, 1)
            plot(pst+rand*0.2-0.1, data_grp1(y, v),'-o', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.75 .75 .75],'MarkerSize', 5, 'LineWidth', 1.5);
            hold on;
        end

        bg = bar(pst, yMean(v), 'FaceColor','None','EdgeColor',[0 0 0],'LineWidth',1.5);
        hold on
        errorbar(pst, yMean(v), y_se(v),"-","MarkerSize",2,...
            "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 1.5, 'color', 'k');
    end

    hold off;     box off
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    ax.XTickLabel= [];
    ax.XAxis.FontSize = 16;
    xticks(x_ticks);
    ax.XTickLabel= x_label_text;
    ax.XTickLabel{6} = ['\color[rgb]{0.4660 0.6740 0.1880}', x_label_text{6}];
    xtickangle(45)
    ylabel(y_label_text, 'FontSize', 30, 'FontWeight','normal')
    title(title_text, 'FontSize', 24, 'FontWeight','normal')

%     x0=10;
%     y0=10;
%     width=400;
%     height=400;
%     set(gcf,'position',[x0,y0,width,height])
end


%% function plot data 2 groups 7 variables
function plot_2groups_boxplot(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% data with observations x variables
    figure;
    % plot data for group 1
    yMean=nanmean(data_grp1, 1);
    y_se = std(data_grp1,[], 1, 'omitnan')/sqrt(size(data_grp1, 1));
    
    for v = 1:size(data_grp1, 2)
        for y=1:size(data_grp1, 1)
            plot(1+rand*0.2-0.1, data_grp1(y, v),'-o', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.75 .75 .75],'MarkerSize', 5, 'LineWidth', 1.5);
            hold on;
        end
    end
%         % plot the mean line    
%         plot([pst-0.3 pst+0.3],[yMean(v) yMean(v)] ,'Color','k','LineWidth',2);
        bx2 = boxplot([data_grp1, NaN(length(data_grp1), 1), NaN(length(data_grp1), 1)], 'whisker', 30, 'notch', 'on','colors','k');
        set(bx2,'LineWidth',1.5);

        hold on
%         errorbar(pst, yMean(v), y_se(v),"-","MarkerSize",2,...
%             "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 1.5, 'color', 'k');
%         er.Color = [0 0 0];                            
%         er.LineStyle = 'none';  

    
    % group 2
    yMean=nanmean(data_grp2, 1);
    y_se = std(data_grp2,[], 1, 'omitnan')/sqrt(size(data_grp2, 1));
    
        %plot the mean+-SEM box
        %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
%   Specify pos as a four-element vector of the form [x y w h] in data
%   units. The x and y elements determine the location and the w and h
%   elements determine the size. The function plots into the current axes
%   without clearing existing content from the axes.

    for v = 1:size(data_grp2, 2)
%         rectangle('Position',[pst-0.3,yMean(v)-y_se(v), 0.6, 2*y_se(v) ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
%         hold on
        for y=1:size(data_grp2, 1)
            plot(2+rand*0.2-0.1, data_grp2(y, v),'-d', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.75 0.5 0.5],'MarkerSize',5, 'LineWidth', 1.5);
            hold on;
        end
    end
%         % plot the mean line    
%         plot([pst-0.3 pst+0.3],[yMean(v) yMean(v)] ,'Color','k','LineWidth',2);
        bx1 = boxplot([NaN(length(data_grp2), 1), data_grp2, NaN(length(data_grp2), 1)], 'whisker', 30, 'notch', 'on','colors','k');
        set(bx1,'LineWidth',1.5);
%         bar(pst, yMean(v), 'FaceColor','None','EdgeColor',[0 0 0],'LineWidth',1.5);
        hold on
%             errorbar(pst, yMean(v), y_se(v),"-","MarkerSize",2,...
%         "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 1.5, 'color', 'k')


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
