clear; close all
% create variable with parameters from young and older group

H =cell(2, 1); DecisionNoiseSigma = cell(2, 1); LapseRate = cell(2, 1);

accuracy = cell(2, 1);
goodness_of_fit = cell(2, 1);
AIC = cell(2, 1); 
BIC = cell(2, 1);

subj_yng = {}; subj_old = {};


load([pwd, filesep, 'model_resultsSep2024\TrlDSet_infOnly_forExport.mat']);
TrlDSet_inf = TrlDSet;
load([pwd, filesep, 'model_resultsSep2024\TrlDSet_twoLvl_forExport.mat']);
TrlDSet_fulltask = TrlDSet;

yng = 0; old = 0;
for p = 1:length(TrlDSet_inf.P)
    
    for pf = 1:length(TrlDSet_fulltask.P)
        if strcmp(TrlDSet_fulltask.P(pf).Spec.SubjID, TrlDSet_inf.P(p).Spec.SubjID)
            p_fulltask = pf;
        end
    end

   if strcmp(TrlDSet_inf.P(p).Spec.Group, 'young_adults')
       grp = 1; yng = yng +1;
       a = yng;
       subj_yng = [subj_yng; TrlDSet_inf.P(p).Spec.SubjID];
   else
       grp = 2; old = old + 1;
       a = old;
       subj_old = [subj_old; TrlDSet_inf.P(p).Spec.SubjID];
   end
    accuracy{grp}= [accuracy{grp}; mean(TrlDSet_inf.P(p).Data.Acc, 'omitnan'), mean(TrlDSet_fulltask.P(p_fulltask).Data.Acc, 'omitnan')];

% 'last-sample' 'perfect-acc' 'bound-acc' 'leaky-acc' 'normative' 'miscal-h-normative'  'miscal-h-b-normative' 
    for m = 1:length(TrlDSet_inf.P(p).Models)

        goodness_of_fit{grp}(a, 1) = TrlDSet_inf.P(p).Models(m).BestFit.LL/TrlDSet_inf.P(p).Models(m).BestFit.SampleSize;
        AIC{grp}(a, 1) = TrlDSet_inf.P(p).Models(m).BestFit.Aic;
        BIC{grp}(a, 1) = TrlDSet_inf.P(p).Models(m).BestFit.Bic;    
        DecisionNoiseSigma{grp}(a, 1) = TrlDSet_inf.P(p).Models(m).BestFit.Params.DecisionNoiseSigma;
        LapseRate{grp}(a, 1) = TrlDSet_inf.P(p).Models(m).BestFit.Params.LapseRate;
        H{grp}(a, 1) = TrlDSet_inf.P(p).Models(m).BestFit.Params.ObserverH; 
        
        goodness_of_fit{grp}(a, 2) = TrlDSet_fulltask.P(p_fulltask).Models(m).BestFit.LL/TrlDSet_fulltask.P(p_fulltask).Models(m).BestFit.SampleSize;
        AIC{grp}(a, 2) = TrlDSet_fulltask.P(p_fulltask).Models(m).BestFit.Aic;
        BIC{grp}(a, 2) = TrlDSet_fulltask.P(p_fulltask).Models(m).BestFit.Bic;    
        DecisionNoiseSigma{grp}(a, 2) = TrlDSet_fulltask.P(p_fulltask).Models(m).BestFit.Params.DecisionNoiseSigma;
        LapseRate{grp}(a, 2) = TrlDSet_fulltask.P(p_fulltask).Models(m).BestFit.Params.LapseRate;
        H{grp}(a, 2) = TrlDSet_fulltask.P(p_fulltask).Models(m).BestFit.Params.ObserverH;   
        
    end
end

%% save excel files with data

% free parameters vs accuracy
group = [ones(length(subj_yng), 1); ones(length(subj_old), 1).*2];
free_params = [group, [accuracy{1}; accuracy{2}], [DecisionNoiseSigma{1}; DecisionNoiseSigma{2}], [LapseRate{1}; LapseRate{2}], ...
        [H{1}; H{2}], [AIC{1}; AIC{2}], [BIC{1}; BIC{2}], [goodness_of_fit{1}; goodness_of_fit{2}]];

var_names = {'Group', 'Acc_inf', 'Acc_fulltask', 'DN_inf', 'DN_fulltask', ...
    'LR_inf', 'LR_fulltask', ...
    'H_inf', 'H_fulltask', 'AIC_inf', 'AIC_fulltask', 'BIC_inf', 'BIC_fulltask','GOF_inf', 'GOF_fulltask',};

T = array2table(free_params,...
    'VariableNames',var_names);

T.subjID = [subj_yng; subj_old];

% writetable(T, 'model_inf_fulltask.xlsx');

%%
% plot_2groups_2conditions(data_grp1_cond1,data_grp1_cond2, data_grp2_cond1, data_grp2_cond2, y_label_text, title_text, xaxis_text)

plot_2groups_2conditions(DecisionNoiseSigma{1}(:, 1),DecisionNoiseSigma{1}(:, 2),...
    DecisionNoiseSigma{2}(:, 1),DecisionNoiseSigma{2}(:, 2), 'Decision Noise', '', {'Infer-only', 'Two-level'})
axis([0 6, 0, 20]);

%% boxplots
% plot_2groups_2conds_boxplot(data_grp1_cond1,data_grp1_cond2, data_grp2_cond1, data_grp2_cond2, y_label_text, title_text, xaxis_text)
plot_2groups_2conds_boxplot(DecisionNoiseSigma{1}(:, 1),DecisionNoiseSigma{1}(:, 2),...
    DecisionNoiseSigma{2}(:, 1),DecisionNoiseSigma{2}(:, 2), 'Decision Noise', '', {'Infer-only', 'Two-level'})
axis([0 6, 0, 20]); box off
%%
plot_2groups_2conditions(LapseRate{1}(:, 1),LapseRate{1}(:, 2),...
    LapseRate{2}(:, 1),LapseRate{2}(:, 2), 'Lapse Rate', '', {'Infer-only', 'Two-level'})
axis([0 6, 0, .4]);

%% boxplots
plot_2groups_2conds_boxplot(LapseRate{1}(:, 1),LapseRate{1}(:, 2),...
    LapseRate{2}(:, 1),LapseRate{2}(:, 2), 'Lapse Rate', '', {'Infer-only', 'Two-level'})
axis([0 6, 0, .4]);

%%
plot_2groups_2conditions(H{1}(:, 1),H{1}(:, 2),...
    H{2}(:, 1),H{2}(:, 2), 'Hazard Rate', '', {'Infer-only', 'Two-level'})
hold on
plot([0 6], [1/70 1/70], '--k', 'LineWidth', 1.5)
axis([0 6, 0, .25]);

%% boxplots
plot_2groups_2conds_boxplot(H{1}(:, 1),H{1}(:, 2),...
    H{2}(:, 1),H{2}(:, 2), 'Hazard Rate', '', {'Infer-only', 'Two-level'})
hold on
plot([0 6], [1/70 1/70], '--k', 'LineWidth', 1.5)
axis([0 6, 0, .25]);

%%
plot_2groups_2conditions(AIC{1}(:, 1),AIC{1}(:, 2),...
    AIC{2}(:, 1),AIC{2}(:, 2), {'AIC'}, '', {'Inference', 'Full Task'})

%%
plot_2groups_2conditions(BIC{1}(:, 1),BIC{1}(:, 2),...
    BIC{2}(:, 1),BIC{2}(:, 2), {'BIC'}, '', {'Inference', 'Full Task'})

%%
plot_2groups_2conditions(accuracy{1}(:, 1).*100,accuracy{1}(:, 2).*100,...
    accuracy{2}(:, 1).*100, accuracy{2}(:, 2).*100, {'Accuracy (%)'}, '', {'Infer-only', 'Two-level'})
axis([0 6, 60, 95]);

[h,p,ci,stats] = ttest2(accuracy{1}(:, 1), accuracy{2}(:, 1))

[h,p,ci,stats] = ttest2(accuracy{1}(:, 2), accuracy{2}(:, 2))

[h,p,ci,stats] = ttest(accuracy{1}(:, 1), accuracy{1}(:, 2))

[h,p,ci,stats] = ttest(accuracy{2}(:, 1), accuracy{2}(:, 2))

%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative free H'  'normative free H & B'};
plot_2groups_variables(goodness_of_fit{1}, goodness_of_fit{2},'Goodn of fit',...
    models_name , ...
   [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5] , '')
axis([0 21 -inf inf]);

%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative miscal H'  'normative miscal H & B'};
plot_2groups_variables(AIC{1}, AIC{2},'AIC',...
    models_name , ...
   [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5] , '')
axis([0 21 -inf inf]);

%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% models_name = {'last sample' 'perfect acc' 'bound acc' 'leaky acc' 'normative' 'normative miscal H'  'normative miscal H & B'};
plot_2groups_variables(BIC{1}, BIC{2},'BIC',...
    models_name , ...
   [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5] , '')
axis([0 21 -inf inf]);

%% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% plot decision noise group comparison for 5 best models

plot_2groups_variables(DecisionNoiseSigma{1}, DecisionNoiseSigma{2},'Decision noise',...
    models_name , ...
   [1.5, 4.5, 7.5, 10.5, 13.5, 16.5, 19.5] , '')
axis([6 21 -inf 18]);

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

plot_2groups_variables(H{1}, H{2}, {'Observers', 'hazard rate'},...
    models_name(6:7) , ...
   [1.5 4.5] , '')
hold on
plot([0 6], [1/70 1/70], '--k')
axis([0 6 -inf inf]);

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
        rectangle('Position',[pst-0.3,yMean(v)-y_se(v), 0.6, 2*y_se(v) ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
        hold on
        for y=1:size(data_grp1, 1)
            plot(pst+rand*0.2-0.1, data_grp1(y, v),'-o', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.5 .5 .5],'MarkerSize', 4, 'LineWidth', 1.5);
            hold on;
        end

        % plot the mean line    
        plot([pst-0.3 pst+0.3],[yMean(v) yMean(v)] ,'Color','k','LineWidth',2);
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
        rectangle('Position',[pst-0.3,yMean(v)-y_se(v), 0.6, 2*y_se(v) ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
        hold on
        for y=1:size(data_grp2, 1)
            plot(pst+rand*0.2-0.1, data_grp2(y, v),'-o', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.5 0 0],'MarkerSize',4, 'LineWidth', 1.5);
            hold on;
        end

        % plot the mean line    
        plot([pst-0.3 pst+0.3],[yMean(v) yMean(v)] ,'Color','k','LineWidth',2);
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


%% function plot data 2 groups, 2 conditions
function plot_2groups_2conds_boxplot(data_grp1_cond1,data_grp1_cond2, data_grp2_cond1, data_grp2_cond2, y_label_text, title_text, xaxis_text)
    figure;
    % plot data for group 1
    yMean1=nanmean(data_grp1_cond1);
    y_se1 = std(data_grp1_cond1,'omitnan')/sqrt(length(data_grp1_cond1));
    
    % condition 2
    yMean2=nanmean(data_grp1_cond2);
    y_se2 = std(data_grp1_cond2,'omitnan')/sqrt(length(data_grp1_cond2));
    hold on
    for y=1:length(data_grp1_cond1)
        plot([1+rand*0.2-0.1, 2+rand*0.2-0.1], [data_grp1_cond1(y), data_grp1_cond2(y)], '-o', 'color', [.8 .8 .8], ...
            'MarkerEdgeColor',[.75 .75 .75],'MarkerSize',6, 'LineWidth', 1);
        hold on;
    end
    
    bx2 = boxplot([data_grp1_cond1, data_grp1_cond2, NaN(length(data_grp1_cond1), 1), NaN(length(data_grp1_cond1), 1), NaN(length(data_grp1_cond1), 1)],...
        'whisker', 30, 'notch', 'on','colors','k');
    set(bx2,'LineWidth',1.5);

    hold on
    
    
    % group 2
    % condition 1
    yMean1=nanmean(data_grp2_cond1);
    y_se1 = std(data_grp2_cond1,'omitnan')/sqrt(length(data_grp2_cond1));
        % condition 2
    yMean2=nanmean(data_grp2_cond2);
    y_se2 = std(data_grp2_cond2,'omitnan')/sqrt(length(data_grp2_cond2));
    
    for y=1:length(data_grp2_cond1)
        plot([4+rand*0.2-0.1, 5+rand*0.2-0.1], [data_grp2_cond1(y), data_grp2_cond2(y)], '-d', 'color', [.8 .8 .8], ...
            'MarkerEdgeColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1);
        hold on;
    end
    
    bx2 = boxplot([NaN(length(data_grp2_cond1), 1),NaN(length(data_grp2_cond1), 1), NaN(length(data_grp2_cond1), 1), data_grp2_cond1, data_grp2_cond2],...
        'whisker', 30, 'notch', 'on','colors','k');
    set(bx2,'LineWidth',1.5);
    %plot line between conditions  
%     plot([4 5],[yMean1 yMean2] ,'Color','k','LineWidth',2);
    
    % axes('XColor','none');
    hold off; box off
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
