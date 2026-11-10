
clear; close all
% create variable with parameters from young and older group
load([pwd, filesep, 'model_resultsSep2024\TrlDSet_forExport_240911.mat']);
H =cell(2, 1); Beta = cell(2, 1); DecisionNoiseSigma = cell(2, 1); LapseRate = cell(2, 1);
AccumLeak = cell(2, 1); %'leaky-acc'
AccumBound = cell(2, 1); % 'bound-acc'

accuracy = cell(2, 1);
goodness_of_fit = cell(2, 1);
AIC = cell(2, 1); 
BIC = cell(2, 1);

subj_yng = {}; subj_old = {};

% order of models analysed
% model names from variable
model_names = {};
for m = 1:length(TrlDSet.P(1).Models)
    model_names = [model_names, TrlDSet.P(1).Models(m).Settings.ModelName];
end

yng = 0; old = 0;
for p = 1:length(TrlDSet.P)
%    ['young_adults']['older_adults']
    
   if strcmp(TrlDSet.P(p).Spec.Group, 'young_adults')
       grp = 1; yng = yng +1;
       a = yng;
       subj_yng = [subj_yng; TrlDSet.P(p).Spec.SubjID];
   else
       grp = 2; old = old + 1;
       a = old;
       subj_old = [subj_old; TrlDSet.P(p).Spec.SubjID];
   end
    accuracy{grp}= [accuracy{grp}; mean(TrlDSet.P(p).Data.Acc(contains(TrlDSet.P(p).Data.BlockType, 'full_task')), 'omitnan')];

% 'last-sample' 'perfect-acc' 'bound-acc' 'leaky-acc' 'normative' 'miscal-h-normative'  'miscal-h-b-normative' 
    for m = 1:length(TrlDSet.P(p).Models)
        
        if contains(TrlDSet.P(p).Models(m).Settings.ModelName, 'last-sample')
            b = 1;
        elseif contains(TrlDSet.P(p).Models(m).Settings.ModelName, 'perfect-acc')      
            b = 2;
        elseif contains(TrlDSet.P(p).Models(m).Settings.ModelName, 'bound-acc')
            b = 3;
            AccumBound{grp}(a, 1) = TrlDSet.P(p).Models(m).BestFit.Params.AccumBound;
        elseif contains(TrlDSet.P(p).Models(m).Settings.ModelName, 'leaky-acc')
            b = 4;
            AccumLeak{grp}(a, 1) = TrlDSet.P(p).Models(m).BestFit.Params.AccumLeak;
        elseif strcmp(TrlDSet.P(p).Models(m).Settings.ModelName, 'normative-lapse')        
            b = 5;
        elseif strcmp(TrlDSet.P(p).Models(m).Settings.ModelName, 'miscal-h-normative-lapse' )
            b = 6;
            H{grp}(a, 1) = TrlDSet.P(p).Models(m).BestFit.Params.ObserverH;            
        elseif strcmp(TrlDSet.P(p).Models(m).Settings.ModelName, 'miscal-h-b-normative-lapse')
            b = 7;
            H{grp}(a, 2) = TrlDSet.P(p).Models(m).BestFit.Params.ObserverH;
            Beta{grp} = [Beta{grp}; TrlDSet.P(p).Models(m).BestFit.Params.ObserverBeta];
        end
        
        goodness_of_fit{grp}(a, b) = TrlDSet.P(p).Models(m).BestFit.LL/TrlDSet.P(p).Models(m).BestFit.SampleSize;
        AIC{grp}(a, b) = TrlDSet.P(p).Models(m).BestFit.Aic;
        BIC{grp}(a, b) = TrlDSet.P(p).Models(m).BestFit.Bic;    
        DecisionNoiseSigma{grp}(a, b) = TrlDSet.P(p).Models(m).BestFit.Params.DecisionNoiseSigma;
        LapseRate{grp}(a, b) = TrlDSet.P(p).Models(m).BestFit.Params.LapseRate;
        
    end
end

%% save excel files with data
filename = 'model_fit_lapse.xlsx';
group = [ones(length(subj_yng), 1); ones(length(subj_old), 1).*2];

%AIC
filename = 'model_fit_lapse_AIC.xlsx';
fit_variable = [group, [AIC{1}; AIC{2}]];

T = array2table(fit_variable,...
    'VariableNames',{'Group', 'last-sample' 'perfect-acc' 'bound-acc' 'leaky-acc' 'normative' 'miscal-h-normative'  'miscal-h-b-normative'});
T.subjID = [subj_yng; subj_old];

% writetable(T,filename);

%% BIC
fit_variable = [group, [BIC{1}; BIC{2}]];

T = array2table(fit_variable,...
    'VariableNames',{'Group', 'last-sample' 'perfect-acc' 'bound-acc' 'leaky-acc' 'normative' 'miscal-h-normative'  'miscal-h-b-normative'});
T.subjID = [subj_yng; subj_old];

% writetable(T,filename,'Sheet','BIC');

% goodness of fit
fit_variable = [group, [goodness_of_fit{1}; goodness_of_fit{2}]];

T = array2table(fit_variable,...
    'VariableNames',{'Group', 'last-sample' 'perfect-acc' 'bound-acc' 'leaky-acc' 'normative' 'miscal-h-normative'  'miscal-h-b-normative'});
T.subjID = [subj_yng; subj_old];

% writetable(T,filename,'Sheet','goodness_fit');


%% free parameters vs accuracy
free_params = [group, [accuracy{1}; accuracy{2}], [DecisionNoiseSigma{1}; DecisionNoiseSigma{2}], [LapseRate{1}; LapseRate{2}], ...
    [AccumBound{1}; AccumBound{2}], [AccumLeak{1}; AccumLeak{2}],[H{1}; H{2}], [Beta{1}; Beta{2}]];

var_names = {'Group', 'Accuracy', 'DN_last-sample' 'DN_perfect-acc' 'DN_bound-acc' 'DN_leaky-acc' 'DN_normative' 'DN_miscal-h-normative'  'DN_miscal-h-b-normative', ...
    'LR_last-sample' 'LR_perfect-acc' 'LR_bound-acc' 'LR_leaky-acc' 'LR_normative' 'LR_miscal-h-normative'  'LR_miscal-h-b-normative', ...
    'Height_bound-acc', 'Leak_leaky-acc', 'H_miscal-h-normative', 'H_miscal-h-b-normative', 'Beta_miscal-h-b-normative'};

T = array2table(free_params,...
    'VariableNames',var_names);

T.subjID = [subj_yng; subj_old];

% writetable(T, 'model_free_parameters.xlsx');



%% log free parameters vs accuracy
free_params = [group, [accuracy{1}; accuracy{2}], log([DecisionNoiseSigma{1}; DecisionNoiseSigma{2}]), log([LapseRate{1}; LapseRate{2}]), ...
    log([AccumBound{1}; AccumBound{2}]), log([AccumLeak{1}; AccumLeak{2}]),log([H{1}; H{2}]), log([Beta{1}; Beta{2}])];

var_names = {'Group', 'Accuracy', 'DN_last-sample' 'DN_perfect-acc' 'DN_bound-acc' 'DN_leaky-acc' 'DN_normative' 'DN_miscal-h-normative'  'DN_miscal-h-b-normative', ...
    'LR_last-sample' 'LR_perfect-acc' 'LR_bound-acc' 'LR_leaky-acc' 'LR_normative' 'LR_miscal-h-normative'  'LR_miscal-h-b-normative', ...
    'Height_bound-acc', 'Leak_leaky-acc', 'H_miscal-h-normative', 'H_miscal-h-b-normative', 'Beta_miscal-h-b-normative'};

T = array2table(free_params,...
    'VariableNames',var_names);

T.subjID = [subj_yng; subj_old];

% writetable(T, 'model_free_parameters_log.xlsx');

%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative free H'  'normative free H & B'};
plot_2groups_variables(goodness_of_fit{1}, goodness_of_fit{2},'Goodn of fit',...
    models_name , ...
   [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5] , '')
axis([0 21 -inf inf]);

%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
for grp = 1:2
    models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative free H'  'normative miscal H & B'};
    % plot_1group_variables(data_grp1, y_label_text, x_label_text, x_ticks, title_text)
    bg = plot_1group_variables(AIC{grp}(:, 1:6)-AIC{grp}(:, 6),'\Delta AIC', models_name , ...
       [1 2 3 4 5 6] , '');

    hold on
%     plot([0 7], [min(mean(AIC{grp}(:, 1:6), 1)) min(mean(AIC{grp}(:, 1:6), 1))], '--r', 'LineWidth', 1.5)
    % yscale('log')
    axis([0 7 -inf inf]); ylim padded
    set(bg,'edgecolor', [0.4660 0.6740 0.1880])
    %'\color[rgb]{0,1,0}green\color{orange}?';

end

% calculate which model has lower AIC
mean_AIC_yng = mean(AIC{1}(:, 1:6), 1)
mean_AIC_old = mean(AIC{2}(:, 1:6), 1)

mean_AIC = mean([AIC{1}(:, 1:6); AIC{2}(:, 1:6)], 1)

mean_AIC_yng - mean_AIC_yng(6)
mean_AIC_old - mean_AIC_old(6)
mean_AIC_yng(6) - mean_AIC_yng(4)
mean_AIC_old(6) - mean_AIC_old(4)


data_young = AIC{1}(:, 1:6)-AIC{1}(:, 6);
[H,P,CI,STATS] = ttest(data_young) 

data_older = AIC{2}(:, 1:6)-AIC{2}(:, 6);
[H,P,CI,STATS] = ttest(data_older) 


%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
for grp = 1:2
    models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative free H'  'normative miscal H & B'};
    % plot_1group_variables(data_grp1, y_label_text, x_label_text, x_ticks, title_text)
    bg = plot_1group_variables(BIC{grp}(:, 1:6)-BIC{grp}(:, 6),'\Delta BIC', models_name(1:6) , ...
       [1 2 3 4 5 6] , '');

    hold on
%     plot([0 5], [min(mean(BIC{grp}(:, 3:6), 1)) min(mean(BIC{grp}(:, 3:6), 1))], '--r', 'LineWidth', 1.5)
    axis([0 7 -inf inf]); ylim padded
    set(bg,'edgecolor', [0.4660 0.6740 0.1880])
end

% calculate which model has lower BIC
mean_BIC_yng = mean(BIC{1}(:, 1:6), 1)
mean_BIC_old = mean(BIC{2}(:, 1:6), 1)

mean_BIC = mean([BIC{1}(:, 1:6); BIC{2}(:, 1:6)], 1)

mean_BIC_yng - mean_BIC_yng(6)
mean_BIC_old - mean_BIC_old(6)


data_young = BIC{1}(:, 1:6)-BIC{1}(:, 6);
[H,P,CI,STATS] = ttest(data_young) 

data_older = BIC{2}(:, 1:6)-BIC{2}(:, 6);
[H,P,CI,STATS] = ttest(data_older) 

%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative miscal H'  'normative miscal H & B'};
plot_2groups_variables(BIC{1}, BIC{2},'BIC',...
    models_name , ...
   [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5] , '')
hold on
plot([0 18], [min(mean(BIC{1}(:, 1:6), 1)) min(mean(BIC{1}(:, 1:6), 1))], '--k', 'LineWidth', 1.5)
axis([0 18 -inf inf]); ylim padded

%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% plot decision noise group comparison for 5 best models

plot_2groups_variables(DecisionNoiseSigma{1}, DecisionNoiseSigma{2},'Decision noise',...
    '', ...
   [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5] , '')
axis([15.5 17.5 -inf 18]);

%%
plot_2groups_variables(DecisionNoiseSigma{1}, DecisionNoiseSigma{2},'Decision noise',...
    '', ...
   [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5] , '')
axis([15.5 17.5 -inf 20]);
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0);
xticks([16 17])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])

    
 %%   
plot_2groups_variables(LapseRate{1}, LapseRate{2},'Lapse Rate',...
    '', ...
   [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5] , '')
axis([15.5 17.5 -inf inf]); ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0);
    xticks([16 17])
    xticklabels({'YA', 'OA'});
    x0=10;
    y0=10;
    width=300;
    height=400;
    set(gcf,'position',[x0,y0,width,height])
    
    

%% accuracy    
plot_2groups_variables(accuracy{1}.*100, accuracy{2}.*100,'Accuracy (%)',...
    '', ...
   [1.5] , '')
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

%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% plot lapse rate group comparison for 5 best models

plot_2groups_variables(LapseRate{1}, LapseRate{2},'Lapse rate',...
    models_name , ...
   [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5] , '')
axis([6 21 -inf inf]);


%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% plot lapse rate group comparison for 5 best models

plot_2groups_variables(AccumBound{1}, AccumBound{2},'Height',...
   '', ...
   [1.5] , 'Bounded accumulator')
axis([0 3 -inf inf]);


%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% plot lapse rate group comparison for 5 best models

plot_2groups_variables(AccumLeak{1}, AccumLeak{2}, 'Leak',...
    '', ...
   [1.5] , 'Leaky accumulator')
axis([0 3 -inf inf]);


%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% plot hazard rate group comparison for 5 best models

plot_2groups_variables(H{1}(:, 1), H{2}(:, 1), {'Hazard rate'},...
    '', ...
   [1.5] , '')
hold on
plot([0 6], [1/70 1/70], '--k', 'LineWidth', 1.5)
axis([0.5 2.5 -inf inf]); ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=10;
y0=10;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])

%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% plot hazard rate group comparison for 5 best models

plot_2groups_boxplot(H{1}(:, 1), H{2}(:, 1), {'Hazard rate'},...
    '', ...
   [1.5] , '')
hold on
plot([0 6], [1/70 1/70], '--k', 'LineWidth', 1.5)
axis([0.5 2.5 -inf .27]);% ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])

%% 
% models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative miscal H'  'normative miscal H & B'};
plot_2groups_boxplot(LapseRate{1}(:, 6), LapseRate{2}(:, 6), {'Lapse rate'},...
    '', ...
   [1.5] , '')

axis([0.5 2.5 -inf 1]); %ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])


%%
plot_2groups_boxplot(DecisionNoiseSigma{1}(:, 6), DecisionNoiseSigma{2}(:, 6), {'Decision noise'},...
    '', ...
   [1.5] , '')

axis([0.5 2.5 -inf 20]); %ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])

%% Leaky accumulator
% models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative miscal H'  'normative miscal H & B'};
plot_2groups_boxplot(LapseRate{1}(:, 4), LapseRate{2}(:, 4), {'Lapse rate'},...
    '', ...
   [1.5] , '')

axis([0.5 2.5 -inf inf]); %ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])

[p,h,stats] = ranksum(LapseRate{1}(:, 4), LapseRate{2}(:, 4))

%% Leaky accumulator
% models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative miscal H'  'normative miscal H & B'};
plot_2groups_boxplot(DecisionNoiseSigma{1}(:, 4), DecisionNoiseSigma{2}(:, 4), {'Decision noise'},...
    '', ...
   [1.5] , '')

axis([0.5 2.5 -inf inf]); %ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])

[p,h,stats] = ranksum(DecisionNoiseSigma{1}(:, 4), DecisionNoiseSigma{2}(:, 4))

%% Leaky accumulator
% models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative miscal H'  'normative miscal H & B'};
plot_2groups_boxplot(AccumLeak{1}, AccumLeak{2}, {'Leak'},...
    '', ...
   [1.5] , '')

axis([0.5 2.5 -inf inf]); %ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])

[p,h,stats] = ranksum(AccumLeak{1}, AccumLeak{2})

%%
plot_2groups_boxplot(DecisionNoiseSigma{1}(:, 6), DecisionNoiseSigma{2}(:, 6), {'Decision noise'},...
    '', ...
   [1.5] , '')

axis([0.5 2.5 -inf 20]); %ylim padded
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0); 
xticks([1 2])
xticklabels({'YA', 'OA'});
x0=100;
y0=100;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])

%% scatter plots

figure; plot(accuracy{1}, Beta{1}, 'o'); 
ylabel('Beta', 'FontSize', 30, 'FontWeight','normal')
xlabel('Accuracy', 'FontSize', 30, 'FontWeight','normal')
[R,P] = corr(accuracy{1}, Beta{1}, 'Type', 'Spearman')

figure; plot(accuracy{2}, Beta{2}, 'o'); 
ylabel('Beta', 'FontSize', 30, 'FontWeight','normal')
xlabel('Accuracy', 'FontSize', 30, 'FontWeight','normal')
[R,P] = corr(accuracy{2}, Beta{2}, 'Type', 'Spearman')

figure; plot(accuracy{1}, H{1}, 'o'); [R,P] = corr(accuracy{1}, H{1}, 'Type', 'Spearman')
figure; plot(accuracy{2}, H{2}, 'o'); [R,P] = corr(accuracy{2}, H{2}, 'Type', 'Spearman')

%% decision noise x accuracy
models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative free H'  'normative free B and H'};

for mdl = [4, 6]
    figure; plot(DecisionNoiseSigma{1}(:, mdl), accuracy{1}*100, 'o', 'color', [.8 .8 .8], ...
                    'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',8, 'LineWidth', 1.5); lsline
    box off
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    xlabel('Decision Noise', 'FontSize', 28, 'FontWeight','normal')
    ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')
    title([models_name{mdl} ' - young'], 'FontSize', 28, 'FontWeight','normal')
    [R,P] = corr(accuracy{1}, DecisionNoiseSigma{1}(:, mdl), 'Type', 'Spearman')
%     text(80, max(DecisionNoiseSigma{2}(:, mdl)), ['R=', num2str(R)]); 
%     text(80, max(DecisionNoiseSigma{2}(:, mdl))-1, ['P=', num2str(P)])


    figure; plot(DecisionNoiseSigma{2}(:, mdl), accuracy{2}*100, 'o', 'color', [.8 .8 .8], ...
                    'MarkerEdgeColor',[.5 0 0],'MarkerSize',8, 'LineWidth', 1.5); lsline
    box off
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    xlabel('Decision Noise', 'FontSize', 28, 'FontWeight','normal')
    ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')
    title([models_name{mdl} ' - older'], 'FontSize', 28, 'FontWeight','normal')
    [R,P] = corr(accuracy{2}, DecisionNoiseSigma{2}(:, mdl), 'Type', 'Spearman')
%     text(80, max(DecisionNoiseSigma{2}(:, mdl)), ['R=', num2str(R)]); 
%     text(80,max(DecisionNoiseSigma{2}(:, mdl))-1, ['P=', num2str(P)])
end


%% lapse rate x accuracy
models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative free H'  'normative free B and H'};

for mdl = [4, 6]
    figure; plot(LapseRate{1}(:, mdl), accuracy{1}*100, 'o', 'color', [.8 .8 .8], ...
                    'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',8, 'LineWidth', 1.5); lsline
    box off
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    xlabel('Lapse rate', 'FontSize', 28, 'FontWeight','normal')
    ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')
    title([models_name{mdl} ' - young'], 'FontSize', 28, 'FontWeight','normal')
    [R,P] = corr(accuracy{1}, DecisionNoiseSigma{1}(:, mdl), 'Type', 'Spearman')
%     text(80, max(DecisionNoiseSigma{2}(:, mdl)), ['R=', num2str(R)]); 
%     text(80, max(DecisionNoiseSigma{2}(:, mdl))-1, ['P=', num2str(P)])


    figure; plot(LapseRate{2}(:, mdl), accuracy{2}*100, 'o', 'color', [.8 .8 .8], ...
                    'MarkerEdgeColor',[.5 0 0],'MarkerSize',8, 'LineWidth', 1.5); lsline
    box off
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    xlabel('Lapse rate', 'FontSize', 28, 'FontWeight','normal')
    ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')
    title([models_name{mdl} ' - older'], 'FontSize', 28, 'FontWeight','normal')
    [R,P] = corr(accuracy{2}, DecisionNoiseSigma{2}(:, mdl), 'Type', 'Spearman')
%     text(80, max(DecisionNoiseSigma{2}(:, mdl)), ['R=', num2str(R)]); 
%     text(80,max(DecisionNoiseSigma{2}(:, mdl))-1, ['P=', num2str(P)])
end

%% H x accuracy
models = {'miscal-h-normative'  'miscal-h-b-normative'};
for mdl = 1:2
    figure; plot(accuracy{1}*100, abs(H{1}(:, mdl)-0.0143), 'o', 'color', [.8 .8 .8], ...
                    'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',8, 'LineWidth', 1.5);
    box off
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    ylabel('\Delta H', 'FontSize', 28, 'FontWeight','normal')
    xlabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')
    title([models(mdl) ' young'], 'FontSize', 28, 'FontWeight','normal')
    [R,P] = corr(accuracy{1}, H{1}(:, mdl), 'Type', 'Spearman');
    text(80, max(abs(H{1}(:, mdl)-0.0143)), ['R=', num2str(R), '  P=', num2str(P)]); 

    figure; plot(accuracy{2}*100, abs(H{2}(:, mdl)-.0143), 'o', 'color', [.8 .8 .8], ...
                    'MarkerEdgeColor',[.5 0 0],'MarkerSize',8, 'LineWidth', 1.5);
    box off
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    ylabel('\Delta H', 'FontSize', 28, 'FontWeight','normal')
    xlabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')
    title([models(mdl) ' older'], 'FontSize', 28, 'FontWeight','normal')
    [R,P] = corr(accuracy{2}, H{2}(:, mdl), 'Type', 'Spearman');
    text(80, max(abs(H{2}(:, mdl)-.0143)), ['R=', num2str(R), '  P=', num2str(P)]); 

end

%% Beta x accuracy
models = {'miscal-h-b-normative'};
for mdl = 1
    figure; plot(accuracy{1}*100, Beta{1}, 'o', 'color', [.8 .8 .8], ...
                    'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',8, 'LineWidth', 1.5);
    box off
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    ylabel('Beta', 'FontSize', 28, 'FontWeight','normal')
    xlabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')
    title([models(mdl) ' young'], 'FontSize', 28, 'FontWeight','normal')
    % [R,P] = corr(accuracy{1}, DecisionNoiseSigma{1}(:, 5), 'Type', 'Spearman')

    figure; plot(accuracy{2}*100, Beta{2}, 'o', 'color', [.8 .8 .8], ...
                    'MarkerEdgeColor',[.5 0 0],'MarkerSize',8, 'LineWidth', 1.5);
    box off
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    ylabel('Beta', 'FontSize', 28, 'FontWeight','normal')
    xlabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')
    title([models(mdl) ' older'], 'FontSize', 28, 'FontWeight','normal')
    [R,P] = corr(accuracy{2}, DecisionNoiseSigma{2}(:, 5), 'Type', 'Spearman');
    text(80, 3, ['R=', num2str(R)]); text(80, 2, ['P=', num2str(P)])

    figure; plot(accuracy{1}*100, abs(Beta{1}-3.125), 'o', 'color', [.8 .8 .8], ...
                    'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',8, 'LineWidth', 1.5);
    box off
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    ylabel('\Delta Beta', 'FontSize', 28, 'FontWeight','normal')
    xlabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')
    title([models(mdl) ' young'], 'FontSize', 28, 'FontWeight','normal')
    % [R,P] = corr(accuracy{1}, DecisionNoiseSigma{1}(:, 5), 'Type', 'Spearman')

    figure; plot(accuracy{2}*100, abs(Beta{2}-3.125), 'o', 'color', [.8 .8 .8], ...
                    'MarkerEdgeColor',[.5 0 0],'MarkerSize',8, 'LineWidth', 1.5);
    box off
    ax = gca;
    ax.LineWidth = 2.5; 
    ax.FontSize = 24;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    ylabel('\Delta Beta', 'FontSize', 28, 'FontWeight','normal')
    xlabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')
    title([models(mdl) ' older'], 'FontSize', 28, 'FontWeight','normal')
%             [R,P] = corr(accuracy{2}, DecisionNoiseSigma{2}(:, 5), 'Type', 'Spearman')


end



%%
% [h,p,ci,stats] = ttest2(H{1}, H{2})
% [h,p,ci,stats] = ttest2(Beta{1}, Beta{2})
% [h,p,ci,stats] = ttest2(DecisionNoiseSigma{1}, DecisionNoiseSigma{2})



[~, pValue, SWstatistic] = swtest(H{1})
[~, pValue, SWstatistic] = swtest(H{2})
[~, pValue, SWstatistic] = swtest(Beta{1})
[~, pValue, SWstatistic] = swtest(Beta{2})
[~, pValue, SWstatistic] = swtest(DecisionNoiseSigma{1})
[~, pValue, SWstatistic] = swtest(DecisionNoiseSigma{2})

[P_H,~,STATS] = ranksum(H{1}, H{2})

[P_Beta,~,STATS] = ranksum(Beta{1}, Beta{2})

[P_Noise,~,STATS] = ranksum(DecisionNoiseSigma{1}(DecisionNoiseSigma{1}<40), DecisionNoiseSigma{2})

%%
figure;
[p_star,p_value] = boxplot_sigstar([DecisionNoiseSigma{1}(:, 3), DecisionNoiseSigma{2}(:, 3)],{'Young', 'Older'})

%%
figure;
[p_star,p_value] = boxplot_sigstar({Beta{1}, Beta{2}},{'Young', 'Older'})


figure; 

boxplot(Beta{1}, Beta{2})

%%
plot_all_data_2groups(DecisionNoiseSigma{1}(DecisionNoiseSigma{1}<40), DecisionNoiseSigma{2}, 'Decision Noise Sigma', 'miscal-h-b-normative')

%%
plot_all_data_2groups(H{1}(:, 1), H{2}(:, 1), 'Observer H', 'Normative: H free param')
[P_H1,~,STATS] = ranksum(H{1}(:, 1), H{2}(:, 1))
%%
plot_all_data_2groups(H{1}(:, 2), H{2}(:, 2), 'Observer H', 'Normative: H&B free param')
[P_H2,~,STATS] = ranksum(H{1}(:, 2), H{2}(:, 2))

%%
plot_all_data_2groups(DecisionNoiseSigma{1}(:, 1), DecisionNoiseSigma{2}(:, 1), 'Decision Noise', 'Normative')
[P_DN1,~,STATS] = ranksum(DecisionNoiseSigma{1}(:, 1), DecisionNoiseSigma{2}(:, 1))

%
plot_all_data_2groups(DecisionNoiseSigma{1}(:, 2), DecisionNoiseSigma{2}(:, 2), 'Decision Noise', 'Normative: H free param')
[P_DN2,~,STATS] = ranksum(DecisionNoiseSigma{1}(:, 2), DecisionNoiseSigma{2}(:, 2))

%
plot_all_data_2groups(DecisionNoiseSigma{1}(:, 3), DecisionNoiseSigma{2}(:, 3), 'Decision Noise', 'Normative: H&B free param')
[P_DN3,~,STATS] = ranksum(DecisionNoiseSigma{1}(:, 3), DecisionNoiseSigma{2}(:, 3))


%% goodness of fitness
models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative miscal H'  'normative miscal H & B'};
for mdl = 1:length(models)
    plot_all_data_2groups(goodness_of_fit{1}(:, mdl), goodness_of_fit{2}(:, mdl), 'Goodness of fit', models_name(mdl))
    [P_GF(mdl),~,STATS] = ranksum(goodness_of_fit{1}(:, mdl), goodness_of_fit{2}(:, mdl))
end

%% 
models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative miscal H'  'normative miscal H & B'};
plot_2groups_variables(DecisionNoiseSigma{1}, DecisionNoiseSigma{2},'Decision Noise',...
    models_name, ...
   [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5] , '')
axis([6 21 0 20]);
%% 
plot_2groups_variables(log(H{1}), log(H{2}),'log(Observer H)',...
    {'normative miscal H'  'normative miscal H & B'}, ...
   [1.5, 4.5] , ''); hold on
% axis([6 inf 0 20]);
plot([0 6], log([1/70, 1/70]), '--k', 'LineWidth', 2)

%% plot only for normative miscal H
plot_2groups_variables(log(H{1}(:, 1)), log(H{2}(:, 1)),'Log(observer H)',...
    '', ...
   [1.5] , {'normative miscal H'}); hold on
% axis([6 inf 0 20]);
plot([0 3], log([1/70, 1/70]), '--k', 'LineWidth', 2)
[P_logH,~,STATS] = ranksum(log(H{1}(:, 1)), log(H{2}(:, 1)))
[P_H,~,STATS] = ranksum((H{1}(:, 1)),H{2}(:, 1))
%% 
plot_2groups_variables(Beta{1}, Beta{2},'Beta',...
    {'miscal-h-b-normative'}, ...
   [1.5] , '')

%% 
plot_2groups_variables(AccumLeak{1}, AccumLeak{2},'Leak',...
    '', ...
   [1.5] , 'Leak Accumulation')
[P_Leak,~,STATS] = ranksum(AccumLeak{1}, AccumLeak{2})

%% 
plot_2groups_variables(AccumBound{1}, AccumBound{2},'Boundary',...
    '', ...
   [1.5] , '')
[P_Bound,~,STATS] = ranksum(AccumBound{1}, AccumBound{2})

%% function plot data 2 groups 1 task
function plot_all_data_2groups(data_grp1, data_grp2, y_label_text, title_text)
       figure;
    % plot data for group 1
    yMean=nanmean(data_grp1);
    y_se = std(data_grp1,'omitnan')/sqrt(length(data_grp1));
    
        %plot the mean+-SEM box
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
