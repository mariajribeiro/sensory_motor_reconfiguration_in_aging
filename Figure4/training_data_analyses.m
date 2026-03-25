% training of the rule using an Instructed rule task
clear; close all

% young = {'AB100' 'AB101' 'AB102' 'AB103' 'AB062' 'AB105' 'AB099' 'AB053'...
% 'AB109' 'AB110' 'AB111' 'AB076' 'AB114' 'AB117' 'AB118'};
% 
% older = {'AB104' 'AB071' 'AB058' 'AB057' 'AB067' 'AB106' 'AB107' 'AB011'...
% 'AB073' 'AB108' 'AB112' 'AB079' 'AB113' 'AB075' 'AB115' 'AB116'};

% group = {young, older};

addpath('D:\Project_LC_fMRI\analyses')
group = participants_included;

data_dir = 'D:\Project_LC_fMRI\data\training_data\';
rule_repetitions = cell(2, 1); rule_last_accuracy = cell(2, 1); rule_avg_accuracy = cell(2, 1); rule_choice_trials = cell(2, 1);
infer_repetitions = cell(2, 1); infer_last_accuracy = cell(2, 1); infer_avg_accuracy = cell(2, 1); infer_choice_trials = cell(2, 1);
fulltask_repetitions = cell(2, 1); fulltask_last_accuracy = cell(2, 1); fulltask_avg_accuracy = cell(2, 1); fulltask_choice_trials = cell(2, 1);
for grp = 1:2
    for sbj = 1:length(group{grp})
        subject = char(group{grp}(sbj));
        if strcmp(subject, 'AB106') || strcmp(subject, 'AB058') || strcmp(subject, 'AB076')  % for these subjects training data was recorded in two separate files
            load([data_dir, subject, '_2_training.mat']);
        elseif strcmp(subject, 'AB056') || strcmp(subject, 'AB144') % for these subjects training data was not recorded by mistake
            continue
        else
            load([data_dir, subject, '_training.mat']);
        end
        % check how many times repeated rule training (instructed rule)
        % register last accuracy and average accuracy
        acc = [];
        rule_repetitions{grp} = [rule_repetitions{grp}; length(p.accuracy.phase6_color)];
        rule_last_accuracy{grp} = [rule_last_accuracy{grp}; p.accuracy.phase6_color{end}];
        for rp = 1:length(p.accuracy.phase6_color)
            acc = [acc; p.accuracy.phase6_color{rp}];
        end
        rule_avg_accuracy{grp} = [rule_avg_accuracy{grp}; mean(acc)];
        % how many choice trials - average across repetitions
        numb_choice = [];
        for rp = 1:length(p.seq.phase6_color)
            numb_choice = [numb_choice; length(find(p.seq.phase6_color{1, rp}.type == 1))];
        end
        rule_choice_trials{grp} = [rule_choice_trials{grp}; mean(numb_choice), numb_choice(end)];
        


        % training data full task - last phase phase7_no_color
        acc = [];
        fulltask_repetitions{grp} = [fulltask_repetitions{grp}; length(p.accuracy.phase7_no_color)];
        fulltask_last_accuracy{grp} = [fulltask_last_accuracy{grp}; p.accuracy.phase7_no_color{end}];
        for rp = 1:length(p.accuracy.phase7_no_color)
            acc = [acc; p.accuracy.phase7_no_color{rp}];
        end
        fulltask_avg_accuracy{grp} = [fulltask_avg_accuracy{grp}; mean(acc)];
        % how many choice trials - average across repetitions
        numb_choice = [];
        for rp = 1:length(p.seq.phase7_no_color)
            numb_choice = [numb_choice; length(find(p.seq.phase7_no_color{1, rp}.type == 1))];
        end
        fulltask_choice_trials{grp} = [fulltask_choice_trials{grp}; mean(numb_choice), numb_choice(end)];
        

        if strcmp(subject, 'AB106') || strcmp(subject, 'AB058') || strcmp(subject, 'AB076')
            load([data_dir, subject, '_training.mat']);
        elseif strcmp(subject, 'AB175') % subject training data only recorded for second phase
            infer_last_accuracy{grp} = [infer_last_accuracy{grp}; NaN];
            continue
        end    
        % check how many times repeated inferrence task
        % register last accuracy and average accuracy

        acc = [];
        infer_repetitions{grp} = [infer_repetitions{grp}; length(p.accuracy.phase5_difficult)];
        infer_last_accuracy{grp} = [infer_last_accuracy{grp}; p.accuracy.phase5_difficult{end}];
        for rp = 1:length(p.accuracy.phase5_difficult)
            acc = [acc; p.accuracy.phase5_difficult{rp}];
        end
        infer_avg_accuracy{grp} = [infer_avg_accuracy{grp}; mean(acc)];  
        % how many choice trials per block on average
        numb_choice = [];
        for rp = 1:length(p.seq.phase5)
            numb_choice = [numb_choice; length(find(p.seq.phase5{1, rp}.type == 1))];
        end
        infer_choice_trials{grp} = [infer_choice_trials{grp}; mean(numb_choice), numb_choice(end)];
        
   end
end

%% all tasks

plot_2groups_variables([infer_last_accuracy{1}.*100, rule_last_accuracy{1}.*100, fulltask_last_accuracy{1}.*100],...
    [infer_last_accuracy{2}.*100, rule_last_accuracy{2}.*100, fulltask_last_accuracy{2}.*100], {'Accuracy (%)'},...
    {'YA', 'OA', 'YA', 'OA' ,'YA', 'OA'}, [1, 2, 4, 5, 7, 8], '')
axis([0 9 30 inf]);

x0=10;
y0=10;
width=700;
height=300;
set(gcf,'position',[x0,y0,width,height])


%% inference only
plot_2groups_variables(infer_last_accuracy{1}.*100, infer_last_accuracy{2}.*100,{'Accuracy (%)'},...
    {'YA', 'OA'}, [1, 2], '')
axis([0 3 40 inf]);

x0=10;
y0=10;
width=350;
height=400;
set(gcf,'position',[x0,y0,width,height])

avg_choice_trls = mean([infer_choice_trials{1}(:, 2); infer_choice_trials{2}(:, 2)])
sd_choive_trls = std([infer_choice_trials{1}(:, 2); infer_choice_trials{2}(:, 2)])

[p,h,stats] = ranksum(infer_repetitions{1}, infer_repetitions{2})

median(infer_repetitions{1})
median(infer_repetitions{2})

iqr(infer_repetitions{1})
iqr(infer_repetitions{2})

%% rule only
plot_2groups_variables(rule_last_accuracy{1}.*100, rule_last_accuracy{2}.*100,{'Accuracy (%)'},...
    {'YA', 'OA'}, [1, 2], '')
axis([0 3 40 inf]);

x0=10;
y0=10;
width=350;
height=400;
set(gcf,'position',[x0,y0,width,height])

avg_choice_trls = mean([mean(rule_choice_trials{1}(:, 2)), mean(rule_choice_trials{2}(:, 2))])

[h,p_value,ci,stats] = ttest2(rule_last_accuracy{1}, rule_last_accuracy{2})

[p,h,stats] = ranksum(rule_repetitions{1}, rule_repetitions{2})

median(rule_repetitions{1})
median(rule_repetitions{2})

iqr(rule_repetitions{1})
iqr(rule_repetitions{2})

%% two-level task
plot_2groups_variables(fulltask_last_accuracy{1}.*100, fulltask_last_accuracy{2}.*100,{'Accuracy (%)'},...
    {'YA', 'OA'}, [1, 2], '')
axis([0 3 40 inf]);

x0=10;
y0=10;
width=350;
height=400;
set(gcf,'position',[x0,y0,width,height])

avg_choice_trls = mean([mean(fulltask_choice_trials{1}(:, 2)), mean(fulltask_choice_trials{2}(:, 2))])

[h,p_value,ci,stats] = ttest2(fulltask_last_accuracy{1}.*100, fulltask_last_accuracy{2}.*100)

[p,h,stats] = ranksum(fulltask_repetitions{1}, fulltask_repetitions{2})

median(fulltask_repetitions{1})
median(fulltask_repetitions{2})

iqr(fulltask_repetitions{1})
iqr(fulltask_repetitions{2})

%% 
plot_2groups_variables(rule_avg_accuracy{1},rule_avg_accuracy{2},{'Accuracy (%)'},...
    {'YA', 'OA'}, [1, 2], '')
axis([0 3 -inf inf]);
ylim padded

%% graphs
bar_graph([rule_repetitions{1}', NaN, NaN rule_repetitions{2}'], 'rule training repetitions', 'repetitions')
bar_graph([rule_avg_accuracy{1}', NaN, NaN rule_avg_accuracy{2}'], 'rule training avg accuracy', 'accuracy (%)')
bar_graph([rule_last_accuracy{1}', NaN, NaN rule_last_accuracy{2}'], 'rule training last accuracy', 'accuracy (%)')

bar_graph([infer_repetitions{1}', NaN, NaN infer_repetitions{2}'], 'inferrence training repetitions', 'repetitions')
bar_graph([infer_avg_accuracy{1}', NaN, NaN infer_avg_accuracy{2}'], 'inferrence training avg accuracy', 'accuracy (%)')
bar_graph([infer_last_accuracy{1}', NaN, NaN, infer_last_accuracy{2}'], 'inferrence training last accuracy', 'accuracy (%)')

%% stats
[h,p_value,ci,stats] = ttest2(rule_repetitions{1}, rule_repetitions{2})
[h,p_value,ci,stats] = ttest2(rule_avg_accuracy{1}, rule_avg_accuracy{2})
[h,p_value,ci,stats] = ttest2(rule_last_accuracy{1}, rule_last_accuracy{2})

[h,p_value,ci,stats] = ttest2(infer_repetitions{1}, infer_repetitions{2})
[h,p_value,ci,stats] = ttest2(infer_avg_accuracy{1}, infer_avg_accuracy{2})
[h,p_value,ci,stats] = ttest2(infer_last_accuracy{1}, infer_last_accuracy{2})

%% aux function
function bar_graph(data, title_text, y_label_text)
    figure;

    bar(data, 'FaceColor', [.8 .8 .8],'EdgeColor',[0 0 0],'LineWidth',1)
    box off
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 20;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    if contains(title_text, 'accuracy')
        axis([-inf inf .5 1]);
    end
    ax.XAxis.FontSize = 30;
    xticks([7.5 17+8])
    ax.XTickLabel= {'Young' 'Older'}; 
    ylabel(y_label_text, 'FontSize', 24, 'FontWeight','normal')
    title(title_text, 'FontSize', 24, 'FontWeight','normal')
end

%%
function plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% data with observations x variables
    figure;
    % plot data for group 1
    yMean=nanmean(data_grp1, 1);
    y_se = std(data_grp1,[], 1, 'omitnan')/sqrt(size(data_grp1, 1));
    
    pst = -2;
    for v = 1:size(data_grp1, 2)
        pst = pst + 3;
        for y=1:size(data_grp1, 1)
            plot(pst+rand*0.2-0.1, data_grp1(y, v),'-o', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.75 .75 .75],'MarkerSize', 5, 'LineWidth', 1.5);
            hold on;
        end

        bar(pst, yMean(v), 'FaceColor','None','EdgeColor',[0 0 0],'LineWidth',1.5);
        hold on
        errorbar(pst, yMean(v), y_se(v),"-","MarkerSize",2,...
            "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 1.5, 'color', 'k'); 
    end

    % group 2
    yMean=nanmean(data_grp2, 1);
    y_se = std(data_grp2,[], 1, 'omitnan')/sqrt(size(data_grp2, 1));
    
    pst = -1;
    for v = 1:size(data_grp2, 2)
        pst = pst + 3;

        for y=1:size(data_grp2, 1)
            plot(pst+rand*0.2-0.1, data_grp2(y, v),'-d', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.75 0.5 0.5],'MarkerSize',5, 'LineWidth', 1.5);
            hold on;
        end

        bar(pst, yMean(v), 'FaceColor','None','EdgeColor',[0 0 0],'LineWidth',1.5);
        hold on
            errorbar(pst, yMean(v), y_se(v),"-","MarkerSize",2,...
        "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 1.5, 'color', 'k')
    end

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
    xtickangle(0)
    ylabel(y_label_text, 'FontSize', 30, 'FontWeight','normal')
    title(title_text, 'FontSize', 24, 'FontWeight','normal')

%     x0=10;
%     y0=10;
%     width=400;
%     height=400;
%     set(gcf,'position',[x0,y0,width,height])
end