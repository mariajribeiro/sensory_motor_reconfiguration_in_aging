% calculate effect of rule switches on accuracy based on DSet variable
% for each participant calculate average accuracy for all trials where
clear
load DSet.mat
a=0; yng = 0; old = 0;
for p = 1:length(DSet.P)
    if contains(DSet.P(p).Spec.Group, 'young')
        grp = 1; yng = yng + 1;
    else
        grp = 2; old = old + 1;
    end

    % use only full task trials
    trls = find(contains(DSet.P(p).Data.BlockType, 'full_task'));
    dist2rule_switch = [];
    for t = 1:length(trls)
        rule_switchpercue_before = [0, abs(diff(cell2mat(DSet.P(p).Data.RuleIsHouseToLeftForCue(trls(t)))))];
        last_rule_switch = find(rule_switchpercue_before == 1);

        next_rule_switch = [];
        if t < length(trls) && DSet.P(p).Data.BlockNum(trls(t)) == DSet.P(p).Data.BlockNum(trls(t+1))
            if DSet.P(p).Data.RuleIsHouseToLeftForCue{trls(t)}(end) == DSet.P(p).Data.RuleIsHouseToLeftForCue{trls(t+1)}(1)
                rule_switchpercue_after = [0, abs(diff(cell2mat(DSet.P(p).Data.RuleIsHouseToLeftForCue(trls(t+1)))))];
            else
                rule_switchpercue_after = [1, abs(diff(cell2mat(DSet.P(p).Data.RuleIsHouseToLeftForCue(trls(t+1)))))];
            end
            next_rule_switch = find(rule_switchpercue_after == 1);
        end

        if ~isempty(find(rule_switchpercue_before == 1))
            dist2rule_switch(t, 1) = length(rule_switchpercue_before)-last_rule_switch(end)+1;
        else
            dist2rule_switch(t, 1) = NaN;
        end

        if ~isempty(next_rule_switch)
            dist2rule_switch(t, 2) = next_rule_switch(1);
        else
            dist2rule_switch(t, 2) = NaN;
        end

        dist2rule_switch(t, 3) = DSet.P(p).Data.Acc(trls(t));

    end
    
    dist = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 1:30];
    for d = 1:10
        if grp == 1
            acc_rule_switch{grp}(yng, d) = [mean(dist2rule_switch(dist2rule_switch(:, 2) == dist(d), 3))];
        else
            acc_rule_switch{grp}(old, d) = [mean(dist2rule_switch(dist2rule_switch(:, 2) == dist(d), 3))];
        end
    end

    for d = 11:40
        if grp == 1
            acc_rule_switch{grp}(yng, d) = [mean(dist2rule_switch(dist2rule_switch(:, 1) == dist(d), 3))];
        else
            acc_rule_switch{grp}(old, d) = [mean(dist2rule_switch(dist2rule_switch(:, 1) == dist(d), 3))];
        end
    end

end

% save data in excel for stats in spss

group = [ones(size(acc_rule_switch{1}, 1), 1); ones(size(acc_rule_switch{2}, 1), 1).*2];

x_samples = [-10:-1 1:30];
for s = 1:length(x_samples)
    sample_variables{s} = ['Sample', num2str(x_samples(s))];
end

varnames = {};
varnames{1} = 'group';
varnames(2:length(sample_variables)+1) = sample_variables;

% replace missing values by mean of group
for grp = 1:2
    mean_sample = mean(acc_rule_switch{grp}, 1, 'omitnan');
    for s = 1:size(acc_rule_switch{grp}, 2)
        nidx = find(isnan(acc_rule_switch{grp}(:, s)));
        acc_rule_switch{grp}(nidx, s) = mean_sample(s);
    end
end


% AccRuleSwitchTable_MeanReplaced = array2table([group, [acc_rule_switch{1}; acc_rule_switch{2}]],...
%     'VariableNames', varnames);
% 
% save AccRuleSwitchTable_MeanReplaced AccRuleSwitchTable_MeanReplaced
% 
% writetable(AccRuleSwitchTable_MeanReplaced,'AccRuleSwitchTable_MeanReplaced.xlsx')

%%  fit exponential to data - https://www.alloprof.qc.ca/en/students/vl/mathematics/the-role-of-parameters-in-an-exponential-function-m1144
% different formula according to the website
% clear
load AccRuleSwitchTable_MeanReplaced
data_rs = table2array(AccRuleSwitchTable_MeanReplaced(:, 12:end));
yng = 0; old = 0;    figure;
for s = 1:size(data_rs, 1)
    
    grp = AccRuleSwitchTable_MeanReplaced.group(s);
    if grp == 1
        yng = yng + 1;
        idx = yng;
    else
        old = old + 1;
        idx = old;
    end
    
    y = [data_rs(s, :).*100]';
    x = [1:length(y)]';

%     g = fittype('a-b*exp(-c*x)');
% %     [f0{grp}{idx}, gof{grp}{idx}] = fit(x,y,g,'StartPoint',[[ones(size(x)), -exp(-x)]\y; 1]);
%     [fit_exp_acc_rs{grp}{idx}, gof_exp_acc_rs{grp}{idx}] = fit(x,y,g,'StartPoint',[[ones(size(x)), -exp(-x)]\y; .01], 'Upper', [100, 100, inf],...
%         'Lower', [0 0 0]);
    % fit with tme constant for easy of interpretation
    g = fittype('a-b*exp(-1/t*x)');
%     [f0{grp}{idx}, gof{grp}{idx}] = fit(x,y,g,'StartPoint',[[ones(size(x)), -exp(-x)]\y; 1]);
    % [fit_exp_acc_rs{grp}{idx}, gof_exp_acc_rs{grp}{idx}] = fit(x,y,g,'StartPoint',[[ones(size(x)), -exp(-x)]\y; 100], 'Upper', [100, 100, inf],...
    %     'Lower', [0 0 0]);

    [fit_exp_acc_rs{grp}{idx}, gof_exp_acc_rs{grp}{idx}] = fit(x,y,g,'StartPoint',[[ones(size(x)), -exp(-x)]\y; 100], 'Upper', [100, 100, 30],...
        'Lower', [0 0 0]);

    plot(x,y,'o',x,fit_exp_acc_rs{grp}{idx}(x),'r-');
    yy = 0;
end

% compare exp coefficients accross groups
exp_coef = cell(2, 1); adjrsquare = cell(2, 1);
for grp = 1:2
    for idx = 1:length(fit_exp_acc_rs{grp})
        % exp_coef{grp} = [exp_coef{grp}; [fit_exp_acc_rs{grp}{idx}.a, fit_exp_acc_rs{grp}{idx}.b, fit_exp_acc_rs{grp}{idx}.c]];
        exp_coef{grp} = [exp_coef{grp}; [fit_exp_acc_rs{grp}{idx}.a, fit_exp_acc_rs{grp}{idx}.b, fit_exp_acc_rs{grp}{idx}.t]];
        adjrsquare{grp} = [adjrsquare{grp}; gof_exp_acc_rs{grp}{idx}.adjrsquare];
    end
end

[h,p,ci,stats] = ttest2(exp_coef{1}(:, 1), exp_coef{2}(:, 1))
[h,p,ci,stats] = ttest2(exp_coef{1}(:, 2), exp_coef{2}(:, 2))
[h,p,ci,stats] = ttest2(exp_coef{1}(:, 3), exp_coef{2}(:, 3))

[h,p,ci,stats] = ttest2(adjrsquare{1}, adjrsquare{2})

mean(adjrsquare{1})
std(adjrsquare{1})

mean(adjrsquare{2})
std(adjrsquare{2})


mean(exp_coef{1}(:, 1))
std(exp_coef{1}(:, 1))

mean(exp_coef{2}(:, 1))
std(exp_coef{2}(:, 1))

mean(exp_coef{1}(:, 2))
std(exp_coef{1}(:, 2))

mean(exp_coef{2}(:, 2))
std(exp_coef{2}(:, 2))

mean(exp_coef{1}(:, 3))
std(exp_coef{1}(:, 3))

mean(exp_coef{2}(:, 3))
std(exp_coef{2}(:, 3))



mean(exp_coef{1}(:, 1)-exp_coef{1}(:, 2))
mean(exp_coef{2}(:, 1)-exp_coef{2}(:, 2))




% ('a-b*exp(-c*x)');
figure; plot([0:30], mean(exp_coef{1}(:, 1), 1)-mean(exp_coef{1}(:, 2), 1)*exp(-1/mean(exp_coef{1}(:, 3), 1).*[0:30]), 'k');
hold on; plot([0:30],  mean(exp_coef{2}(:, 1), 1)-mean(exp_coef{2}(:, 2), 1)*exp(-1/mean(exp_coef{2}(:, 3), 1).*[0:30]),'--r');

% without teh asympthote
figure; plot([1:30], -mean(exp_coef{1}(:, 2), 1)*exp(-mean(exp_coef{1}(:, 3), 1).*[1:30]), 'k');
hold on; plot([1:30],  -mean(exp_coef{2}(:, 2), 1)*exp(-mean(exp_coef{2}(:, 3), 1).*[1:30]),'--r');


%% plot bar graphs with the fitted parameters
% plot_2groups_boxplot(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)

plot_2groups_boxplot(exp_coef{1}(:, 1), exp_coef{2}(:, 1), 'a = asymptote', {'YA', 'OA'},...
   [1.5] , '')
hold on

axis([0.5 2.5 -inf inf]); ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=250;
height=400;
set(gcf,'position',[x0,y0,width,height])

%%
[p,h,stats] = ranksum(exp_coef{1}(:, 1), exp_coef{2}(:, 1))

median(exp_coef{1}(:, 1))
iqr(exp_coef{1}(:, 1))

median(exp_coef{2}(:, 1))
iqr(exp_coef{2}(:, 1))

%% plot_2groups_boxplot(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
%Vertical scaling
plot_2groups_boxplot(exp_coef{1}(:, 2), exp_coef{2}(:, 2), 'b = vertical scaling', {'YA', 'OA'},...
   [1.5] , '')
hold on

axis([0.5 2.5 -inf inf]); ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=250;
height=400;
set(gcf,'position',[x0,y0,width,height])

%%
[p,h,stats] = ranksum(exp_coef{1}(:, 2), exp_coef{2}(:, 2))

median(exp_coef{1}(:, 2))
iqr(exp_coef{1}(:, 2))

median(exp_coef{2}(:, 2))
iqr(exp_coef{2}(:, 2))

%% plot_2groups_boxplot(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
%Time constant
plot_2groups_boxplot(exp_coef{1}(:, 3), exp_coef{2}(:, 3), '\tau = time constant', {'YA', 'OA'},...
   [1.5] , '')
hold on

axis([0.5 2.5 -inf inf]); ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=250;
height=400;
set(gcf,'position',[x0,y0,width,height])

%%
[p,h,stats] = ranksum(exp_coef{1}(:, 3), exp_coef{2}(:, 3))



median(exp_coef{1}(:, 3))
iqr(exp_coef{1}(:, 3))

median(exp_coef{2}(:, 3))
iqr(median(exp_coef{2}(:, 3)))

%%

[iqr_old, q_old] = iqr(exp_coef{2}(:, 2));

outliers_old = find(exp_coef{2}(:, 2) > q_old(2) + 1.5 * iqr_old | exp_coef{2}(:, 2) < q_old(1) - 1.5 * iqr_old )



iqr_yng = iqr(exp_coef{1}(:, 2));
median_yng = median(exp_coef{1}(:, 2));
outliers_yng = find(exp_coef{1}(:, 2) > median_yng + 1.5 * iqr_yng)


plot_2groups_boxplot(exp_coef{1}(setdiff(1:length(exp_coef{1}(:, 2)), outliers_yng), 2),...
    exp_coef{2}(setdiff(1:length(exp_coef{2}(:, 2)), outliers_old ), 2), {'Vertical scaling'}, {'YA', 'OA'},...
   [1.5] , '')
hold on

axis([0.5 2.5 -inf inf]); ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])


[p,h,stats] = ranksum(exp_coef{1}(:, 2), exp_coef{2}(:, 2))

[p,h,stats] = ranksum(exp_coef{1}(setdiff(1:length(exp_coef{1}(:, 2)), outliers_yng), 2),...
    exp_coef{2}(setdiff(1:length(exp_coef{2}(:, 2)), outliers_old ), 2))

%% exclude outliers

[iqr_old, q_old] = iqr(exp_coef{2}(:, 3));
outliers_old = find(exp_coef{2}(:, 3) > q_old(2) + 1.5 * iqr_old | exp_coef{2}(:, 3) < q_old(1) - 1.5 * iqr_old )


[iqr_yng, q_yng] = iqr(exp_coef{1}(:, 3));
outliers_yng = find(exp_coef{1}(:, 3) > q_yng(2) + 1.5 * iqr_yng | exp_coef{1}(:, 3) < q_yng(1) - 1.5 * iqr_yng)


plot_2groups_boxplot(exp_coef{1}(setdiff(1:length(exp_coef{1}(:, 3)), outliers_yng), 3),...
    exp_coef{2}(setdiff(1:length(exp_coef{2}(:, 3)), outliers_old ), 3), {'Time constant'}, {'YA', 'OA'},...
   [1.5] , '')
hold on

axis([0.5 2.5 -inf inf]); ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])


[p,h,stats] = ranksum(exp_coef{1}(:, 3), exp_coef{2}(:, 3))

figure; boxplot(exp_coef{2}(:, 3))

%% plot data + fitted data
 
 % calculate average of individual fitted curves
 fitted_data = cell(2, 1);
 for grp = 1:2
     for s = 1:size(exp_coef{grp}, 1)
        fitted_data{grp} = [fitted_data{grp}; exp_coef{grp}(s, 1)-exp_coef{grp}(s, 2)*exp(-(1/exp_coef{grp}(s, 3)).*[1:30])];
     end
 end

x_samples = [-10:29];
figure;
for grp = 1:2
    data_mean = mean(acc_rule_switch{grp}.*100, 1, 'omitnan');
    data_se = std(acc_rule_switch{grp}.*100, [],  1, 'omitnan')/sqrt(size(acc_rule_switch{grp}, 1));

    if grp == 1
        plot(x_samples, data_mean, 'k', 'LineWidth', 1.5)
        hold on
        jbfill(x_samples, data_mean + data_se, data_mean - data_se, 'k', 'k', 1, 0.25)
        hold on
    else
        plot(x_samples, data_mean, 'Color', [.75 0 0], 'LineWidth', 1.5)
        hold on
        jbfill(x_samples, data_mean + data_se, data_mean - data_se, [.75 0 0], [.75 0 0], 1, 0.25)
        hold on
    end
end

% plot fitted curves
plot([0:29], mean(fitted_data{1}, 1), '--k', 'LineWidth', 1.5)
hold on; 
plot([0:29], mean(fitted_data{2}, 1), '--', 'Color', [.75 0 0], 'LineWidth', 1.5)

hold off
ax = gca; box off
ax.LineWidth = 2.5; 
c = ax.Color; ylim padded
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';
%     axis([-200 2000 -inf inf])
xlabel('Position relative to rule-switch', 'FontSize', 24, 'FontWeight','normal')
ylabel('Accuracy (%)', 'FontSize', 30, 'FontWeight','normal')



 %% sig difference across groups
[pval, t_orig, crit_t] = mult_comp_perm_t2(acc_rule_switch{1}, acc_rule_switch{2});
sig_samples = find(pval < .05); % figure; plot(t_orig)


x_samples = [-10:-1 1:30];
figure;
for grp = 1:2
    data_mean = mean(acc_rule_switch{grp}.*100, 1, 'omitnan');
    data_se = std(acc_rule_switch{grp}.*100, [],  1, 'omitnan')/sqrt(size(acc_rule_switch{grp}, 1));

    if grp == 1
        plot(x_samples, data_mean, 'k')
        hold on
        jbfill(x_samples, data_mean + data_se, data_mean - data_se, 'k', 'k', 1, 0.25)
        hold on
    else
        plot(x_samples, data_mean, '--r')
        hold on
        jbfill(x_samples, data_mean + data_se, data_mean - data_se, 'r', 'r', 1, 0.25)
        hold on
    end
end

% plot sig samples
if ~isempty(sig_samples)
    plot(x_samples(sig_samples), ones(length(sig_samples), 1)*10, 's', 'color', 'k', 'MarkerFaceColor','k', 'MarkerSize', 10);
    
end

hold off
ax = gca; box off
c = ax.Color; ylim padded
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';
%     axis([-200 2000 -inf inf])
xlabel('Sample relative to rule-switch', 'FontSize', 24, 'FontWeight','normal')
ylabel('Accuracy (%)', 'FontSize', 24, 'FontWeight','normal')

%% plot all participants individual data

x_samples = [-10:-1 0:29];
figure;
for grp = 1:2

    if grp == 1

        for s = 1:size(acc_rule_switch{grp}, 1)
            plot(x_samples, acc_rule_switch{grp}(s,:).*100, 'color', [.7 .7 .7]);
            hold on
        end
        
    else

        for s = 1:size(acc_rule_switch{grp}, 1)
            plot(x_samples, acc_rule_switch{grp}(s,:).*100, 'color', [1 .7 .7]);
            hold on
        end
    end
    
end


for grp = 1:2
    data_mean = mean(acc_rule_switch{grp}.*100, 1, 'omitnan');

    if grp == 1

        plot(x_samples, data_mean, 'k', 'LineWidth', 1.5)
        hold on
        
    else
        plot(x_samples, data_mean, '--r', 'LineWidth', 1.5)
        hold on
    end
    
end


hold off
ax = gca; box off
c = ax.Color; ylim padded
ax.FontSize = 24; ax.FontName = 'Arial'; ax.Color = 'none';
%     axis([-200 2000 -inf inf])
xlabel('Sample relative to rule-switch', 'FontSize', 24, 'FontWeight','normal')
ylabel('Accuracy (%)', 'FontSize', 24, 'FontWeight','normal')



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
