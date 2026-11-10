% perseveration - inference task
clear
load('DSet.mat')

num_rep_responses = cell(2,1); perc_rep_responses_inf = cell(2,1);
perc_rep_responses_hd = cell(2,1); perc_rep_rule_hd = cell(2,1);
for p = 1:length(DSet.P)
    
    if strcmp(DSet.P(p).Spec.Group, 'older_adults')
        grp = 2;
    else
        grp = 1;
    end
    
    inf_trls = find(~isnan(DSet.P(p).Data.DistIsUpperForTrial));
    hd_trls = find(isnan(DSet.P(p).Data.DistIsUpperForTrial));
    
    if ~isempty(inf_trls) % inference only task
        
        % calculate repeated button presses in inference-only task
        inf_accuracy = DSet.P(p).Data.Acc(inf_trls);
        resp_up = DSet.P(p).Data.RespIsLeftOrUp(inf_trls);
        repeated_responses = diff(resp_up); % repeated responses coded as zeros
        repeated_responses = [1; repeated_responses]; % add first trial as not repeated
        
        % delete first response of each block - different block, different
        % session
        % session_run = DSet.P(p).Data.SessionNum(inf_trls)+DSet.P(p).Data.BlockNum(inf_trls);
        % run_change = diff(session_run);
        % run_change = [0; run_change];
        
        % repeated_responses(run_change ~= 0) = NaN;
        repeated_responses(DSet.P(p).Data.TrialNum(inf_trls) == 1) = NaN;
        
        num_rep_responses{grp} = [num_rep_responses{grp}; length(find(repeated_responses == 0))];
        perc_rep_responses_inf{grp} = [perc_rep_responses_inf{grp}; length(find(repeated_responses == 0))/length(repeated_responses(~isnan(repeated_responses)))*100];
        % perc_rep_responses_inf{grp} = [perc_rep_responses_inf{grp}; length(find(repeated_responses == 0))/length(repeated_responses)*100];
        
        % calculate repeated button presses in two-level decisions task
        % (hierarchical decisions) for participants that also did
        % inference-only task
        hd_accuracy = DSet.P(p).Data.Acc(hd_trls);
        resp_left = DSet.P(p).Data.RespIsLeftOrUp(hd_trls);
        repeated_responses = diff(resp_left); % repeated responses coded as zeros
        repeated_responses = [1; repeated_responses]; % add first trial as not repeated
        
        % delete first response of each block - different block, different
        % session
        % session_run = DSet.P(p).Data.SessionNum(hd_trls)+DSet.P(p).Data.BlockNum(hd_trls);
        % run_change = diff(session_run);
        % run_change = [0; run_change];
        
        % repeated_responses(run_change ~= 0) = NaN;
        repeated_responses(DSet.P(p).Data.TrialNum(hd_trls) == 1) = NaN;
        
%         num_rep_responses{grp} = [num_rep_responses{grp}; length(find(repeated_responses == 0))];
        perc_rep_responses_hd{grp} = [perc_rep_responses_hd{grp}; length(find(repeated_responses == 0))/length(repeated_responses(~isnan(repeated_responses)))*100];
        % perc_rep_responses_hd{grp} = [perc_rep_responses_hd{grp}; length(find(repeated_responses == 0))/length(repeated_responses)*100];
        
        % repeated rule
%         rule = DSet.P(p).Data.RuleIsHouseToLeftForTrial(fulltask_trls);
        
        house = DSet.P(p).Data.StimIsHouse(hd_trls);
        
        rule_accord_response = zeros(length(hd_trls), 1);
        
        for trl = 1:length(house)
            if house(trl) == resp_left(trl)
                rule_accord_response(trl) = 1;
            end
        end
        
        rule_repetition = diff(rule_accord_response);
        rule_repetition = [1; rule_repetition];
        % rule_repetition(run_change ~= 0) = NaN;
        rule_repetition(DSet.P(p).Data.TrialNum(hd_trls) == 1) = NaN;
        
        perc_rep_rule_hd{grp} = [perc_rep_rule_hd{grp}; length(find(rule_repetition == 0))/length(rule_repetition(~isnan(rule_repetition)))*100];
        % perc_rep_rule_hd{grp} = [perc_rep_rule_hd{grp}; length(find(rule_repetition == 0))/length(rule_repetition)*100];
    end
end

%% comparison inference with two-levels task
% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
plot_2groups_variables([perc_rep_responses_inf{1}, perc_rep_responses_hd{1}],...
    [perc_rep_responses_inf{2}, perc_rep_responses_hd{2}],{'Action repetitions (%)'},...
    {'YA', 'OA', 'YA', 'OA'}, [1, 2, 4, 5], '')
axis([0 6 -inf inf]);

[h,p,ci,stats] = ttest2(perc_rep_responses_inf{1}, perc_rep_responses_inf{2})
[h,p,ci,stats] = ttest2(perc_rep_responses_hd{1}, perc_rep_responses_hd{2})


plot_2groups_variables(perc_rep_rule_hd{1}, perc_rep_rule_hd{2},{'Rule repetitions (%)'},...
    {'YA', 'OA'}, [1, 2], '')
axis([0 3 -inf inf]);

[h,p,ci,stats] = ttest2(perc_rep_rule_hd{1}, perc_rep_rule_hd{2})



[h,p,ci,stats] = ttest(perc_rep_responses_inf{1}, perc_rep_rule_hd{1})

[h,p,ci,stats] = ttest(perc_rep_responses_inf{2}, perc_rep_rule_hd{2})

%% calculate repeated responses in normative fit
load('D:\Project_LC_fMRI\analyses\behaviour\Josh\simulationsDec2024\SimTrlDSet_infOnly_miscal-h-normative-lapse_forExport.mat')

num_rep_resp_normfit = cell(2,1); perc_rep_resp_normfit = cell(2,1);
for p = 1:length(SimTrlDSet.P)
    
    if strcmp(SimTrlDSet.P(p).Spec.Group, 'older_adults')
        grp = 2;
    else
        grp = 1;
    end
    
    inf_trls = find(~isnan(SimTrlDSet.P(p).Data.DistIsUpperForTrial));
    
    if ~isempty(inf_trls) % inference only task
       
        inf_accuracy = SimTrlDSet.P(p).Data.Acc(inf_trls);
        resp_up = SimTrlDSet.P(p).Data.RespIsLeftOrUp(inf_trls);
        
        repeated_responses = diff(resp_up); % repeated responses coded as zeros
        
        repeated_responses = [1; repeated_responses]; % add first trial as not repeated

        
        % delete first response of each block - different block, different
        % session
        % session_run = SimTrlDSet.P(p).Data.SessionNum(inf_trls)+SimTrlDSet.P(p).Data.BlockNum(inf_trls);
        % run_change = diff(session_run);
        % run_change = [0; run_change];
        % repeated_responses(run_change ~= 0) = NaN;
        repeated_responses(SimTrlDSet.P(p).Data.TrialNum(inf_trls) == 1) = NaN;
        
        num_rep_resp_normfit{grp} = [num_rep_resp_normfit{grp}; length(find(repeated_responses == 0))];
        perc_rep_resp_normfit{grp} = [perc_rep_resp_normfit{grp}; length(find(repeated_responses == 0))/length(repeated_responses(~isnan(repeated_responses)))*100];
        
    end
end
%
[h,p,ci,stats] = ttest(perc_rep_responses_inf{1}, perc_rep_resp_normfit{1})
[h,p,ci,stats] = ttest(perc_rep_responses_inf{2}, perc_rep_resp_normfit{2})

[h,p,ci,stats] = ttest2(perc_rep_responses_inf{1}, perc_rep_responses_inf{2})
[h,p,ci,stats] = ttest2(perc_rep_resp_normfit{1}, perc_rep_resp_normfit{2})

%%
% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
plot_2groups_variables([perc_rep_responses_inf{1},perc_rep_resp_normfit{1} ],...
    [perc_rep_responses_inf{2}, perc_rep_resp_normfit{2}],{'Action repetition (%)'},...
    {'YA', 'OA', 'YA', 'OA'}, [1, 2, 4, 5], '')
axis([0 6 30 70]);

mean(perc_rep_responses_inf{1})
mean(perc_rep_responses_inf{2})
mean(perc_rep_resp_normfit{1})
mean(perc_rep_resp_normfit{2})


%% including markers with model fits over bar
% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
plot_2groups_variables([perc_rep_responses_inf{1}],...
    [perc_rep_responses_inf{2}],{'Repeated', 'button presses (%)'},...
    {'YA', 'OA'}, [1, 2], '')
ax = gca;ax.XAxis.FontSize = 24;
axis([0.5 2.5 45 67]);

hold on
errorbar([1.2 2.2], [mean(perc_rep_responses_inf{1}) , mean(perc_rep_resp_normfit{2})],...
    [std(perc_rep_responses_inf{1})/sqrt(length(perc_rep_responses_inf{1})), std(perc_rep_resp_normfit{2})/sqrt(length(perc_rep_resp_normfit{2}))],...
    'o', 'color', 'k', 'LineWidth', 1.5,...
    'MarkerFaceColor', 'g', 'MarkerEdgeColor','k')

x0=10;
y0=10;
width=350;
height=400;
set(gcf,'position',[x0,y0,width,height])

%% hierarchical task - perseveration on response button + perseveration on rule
clear
load('DSet.mat')

num_rep_button = cell(2,1);
num_rep_rule = cell(2,1);
perc_rep_button = cell(2,1);
perc_rep_rule = cell(2,1);
accuracy_hd = cell(2,1);
invalid_responses = cell(2,1);
subject = cell(2,1);

for p = 1:length(DSet.P)
    
    if strcmp(DSet.P(p).Spec.Group, 'older_adults')
        grp = 2;
    else
        grp = 1;
    end
    
    fulltask_trls = find(contains(DSet.P(p).Data.BlockType, 'full_task'));
    
    if ~isempty(fulltask_trls) % hierarchical decisions task

        subject{grp} = [subject{grp}; DSet.P(p).Spec.SubjID];
       
        fulltask_accuracy = DSet.P(p).Data.Acc(fulltask_trls);

        accuracy_hd{grp} = [accuracy_hd{grp}; mean(fulltask_accuracy, 'omitnan')];
        invalid_responses{grp} = [invalid_responses{grp}; length(find(isnan(fulltask_accuracy)))];

        resp_left = DSet.P(p).Data.RespIsLeftOrUp(fulltask_trls);
        
        repeated_responses = diff(resp_left); % repeated responses coded as zeros
        
        repeated_responses = [1; repeated_responses]; % add first trial as not repeated
        
        % delete first response of each block - different block, different
        % session - can also use DSet.P(p).Data.TrialNum
        % session_run = DSet.P(p).Data.SessionNum(fulltask_trls)+DSet.P(p).Data.BlockNum(fulltask_trls);
        % run_change = diff(session_run);
        % run_change = [0; run_change];
        % 
        repeated_responses(DSet.P(p).Data.TrialNum(fulltask_trls) == 1) = NaN;
        % repeated_responses(run_change ~= 0) = NaN;
        num_rep_button{grp} = [num_rep_button{grp}; length(find(repeated_responses == 0))];
        perc_rep_button{grp} = [perc_rep_button{grp}; length(find(repeated_responses == 0))/length(repeated_responses(~isnan(repeated_responses)))*100];
        % perc_rep_button{grp} = [perc_rep_button{grp}; length(find(repeated_responses == 0))/length(repeated_responses)*100];
        
        % repeated rule
%         rule = DSet.P(p).Data.RuleIsHouseToLeftForTrial(fulltask_trls);
        
        house = DSet.P(p).Data.StimIsHouse(fulltask_trls);
        
        rule_accord_response = zeros(length(fulltask_trls), 1);
        
        for trl = 1:length(house)
            if house(trl) == resp_left(trl)
                rule_accord_response(trl) = 1;
            end
        end
        
        rule_repetition = diff(rule_accord_response);
        rule_repetition = [1; rule_repetition];
        rule_repetition(DSet.P(p).Data.TrialNum(fulltask_trls) == 1) = NaN;
        % rule_repetition(run_change ~= 0) = NaN;
        
        num_rep_rule{grp} = [num_rep_rule{grp}; length(find(rule_repetition == 0))];
        perc_rep_rule{grp} = [perc_rep_rule{grp}; length(find(rule_repetition == 0))/length(rule_repetition(~isnan(rule_repetition)))*100];
        % perc_rep_rule{grp} = [perc_rep_rule{grp}; length(find(rule_repetition == 0))/length(rule_repetition)*100];
    end
    
end


[h,p_value,ci,stats] = ttest2(perc_rep_rule{1}, perc_rep_rule{2})
[h,p_value,ci,stats] = ttest2(perc_rep_button{1}, perc_rep_button{2})

[h,p_value,ci,stats] = ttest2(num_rep_rule{1}, num_rep_rule{2})
[h,p_value,ci,stats] = ttest2(num_rep_button{1}, num_rep_button{2})


[h,p_value,ci,stats] = ttest2(invalid_responses{1}, invalid_responses{2})
mean(invalid_responses{1})
mean(invalid_responses{2})

% save data in table
PersevTab = table([subject{1}; subject{2}], [ones(length(subject{1}), 1); ones(length(subject{2}), 1)*2],...
    [accuracy_hd{1}; accuracy_hd{2}],  [perc_rep_rule{1}; perc_rep_rule{2}], [perc_rep_button{1}; perc_rep_button{2}], ...
    'VariableNames', {'subjID', 'group', 'accuracy', 'RuleRep', 'KeyRep'});

% save PersevTab PersevTab

%% correlation between task accuracy and tendency for repetition
[r, p] = corrcoef(accuracy_hd{1}, perc_rep_rule{1})
[r, p] = corrcoef(accuracy_hd{2}, perc_rep_rule{2})

[r, p] = corrcoef([accuracy_hd{1}; accuracy_hd{2}], [perc_rep_rule{1}; perc_rep_rule{2}])

figure; plot([accuracy_hd{1}; accuracy_hd{2}], [perc_rep_rule{1}; perc_rep_rule{2}], 'o')
lsline


[h,p_value,ci,stats] = ttest2(accuracy_hd{1}, accuracy_hd{2})

% correlation between button repetition and rule repetition
[r, p] = corrcoef(perc_rep_button{1}, perc_rep_rule{1})
[r, p] = corrcoef(perc_rep_button{2}, perc_rep_rule{2})

[r, p] = corrcoef([perc_rep_button{1}; perc_rep_button{2}], [perc_rep_rule{1}; perc_rep_rule{2}]);


mean(perc_rep_button{1})
mean(perc_rep_button{2})

std(perc_rep_button{1})
std(perc_rep_button{2})

mean(perc_rep_rule{1})
mean(perc_rep_rule{2})

std(perc_rep_rule{1})
std(perc_rep_rule{2})


figure; 
plot(perc_rep_rule{1}, accuracy_hd{1}, 'o',...
    'MarkerEdgeColor', 'k','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(accuracy_hd{1}, perc_rep_rule{1})
if P(1, 2) < .05
    h2 = lsline; set(h2(1),'color','k')
end
hold on
plot( perc_rep_rule{2}, accuracy_hd{2}, 'd', 'color', 'r',...
    'MarkerEdgeColor','r','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(accuracy_hd{2}, perc_rep_rule{2})
if P(1, 2) < .05
    h1 = lsline; set(h1(1),'color','r') 
end

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel('Repeated rules (%)', 'FontSize', 28, 'FontWeight','normal')
ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')



%% assess correlation between hazard rate and perseveration

model = readtable('D:\Project_LC_fMRI\analyses\behaviour\Josh\model_free_parameters.xlsx');

H = cell(2, 1);
for grp = 1:2
    for sbj = 1:length(subject{grp})
        for s = 1:size(model, 1)
            if strcmp(subject{grp}(sbj, :), model.subjID(s))
            H{grp} = [H{grp}; model.H_miscal_h_normative(s)];
            end
        end
    end
end

[r, p] = corrcoef(log(H{1}), perc_rep_rule{1})
[r, p] = corrcoef(log(H{2}), perc_rep_rule{2})

[r, p] = corrcoef(log(H{1}(log(H{1})>-10)), perc_rep_rule{1}(log(H{1})>-10))
[r, p] = corrcoef(log(H{2}), perc_rep_rule{2})

[~,P,CI,STATS] = ttest2(log(H{1}), log(H{2}))

figure; 

plot(log(H{2}), perc_rep_rule{2}, 'd', 'color', 'r',...
    'MarkerEdgeColor','r','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(log(H{2}), perc_rep_rule{2});
if P(1, 2) < .05
    h1 = lsline; set(h1(1),'color','r') 
end
hold on
plot(log(H{1}), perc_rep_rule{1}, 'o',...
    'MarkerEdgeColor', 'k','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(log(H{1}), perc_rep_rule{1});
if P(1, 2) < .05
    h2 = lsline; set(h2(1),'color','k')
end

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'log Hazard Rate'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Repeated rules (%)', 'FontSize', 28, 'FontWeight','normal')



figure; 


plot(H{1}, perc_rep_rule{1}, 'o',...
    'MarkerEdgeColor', 'k','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(H{1}, perc_rep_rule{1})
if P(1, 2) < .05
    h2 = lsline; set(h2(1),'color','k')
end
hold on
plot(H{2}, perc_rep_rule{2}, 'd', 'color', 'r',...
    'MarkerEdgeColor','r','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(H{2}, perc_rep_rule{2})
if P(1, 2) < .05
    h1 = lsline; set(h1(1),'color','r') 
end

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'Hazard Rate'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Repeated rules (%)', 'FontSize', 28, 'FontWeight','normal')


[RHO,PVAL] = corr(H{2}, perc_rep_rule{2}, 'Type', 'Spearman')
[RHO,PVAL] = corr(H{1}, perc_rep_rule{1}, 'Type', 'Spearman')

%% plot button repetition and rule repetition

figure; 

plot(perc_rep_button{2}, perc_rep_rule{2}, 'd', 'color', 'r',...
    'MarkerEdgeColor','r','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(perc_rep_button{2}, perc_rep_rule{2});
if P(1, 2) < .05
    h1 = lsline; set(h1(1),'color','r') 
end
hold on
plot(perc_rep_button{1}, perc_rep_rule{1}, 'o',...
    'MarkerEdgeColor', 'k','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(perc_rep_button{1}, perc_rep_rule{1});
if P(1, 2) < .05
    h2 = lsline; set(h2(1),'color','k')
end

box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel({'Repeated', 'button presses (%)'}, 'FontSize', 28, 'FontWeight','normal')
ylabel('Repeated rules (%)', 'FontSize', 28, 'FontWeight','normal')



%% percentage rule repetition in normative fit
load('D:\Project_LC_fMRI\analyses\behaviour\Josh\simulationsDec2024\SimTrlDSet_twoLvlAll_miscal-h-normative-lapse_forExport.mat')

num_rep_button = cell(2,1);
num_rep_rule = cell(2,1);
perc_rep_button_normfit = cell(2,1);
perc_rep_rule_normfit = cell(2,1);

for p = 1:length(SimTrlDSet.P)
    
    if strcmp(SimTrlDSet.P(p).Spec.Group, 'older_adults')
        grp = 2;
    else
        grp = 1;
    end
    
    fulltask_trls = find(contains(SimTrlDSet.P(p).Data.BlockType, 'full_task'));
    
    if ~isempty(fulltask_trls) % hierarchical decisions task
       
        fulltask_accuracy = SimTrlDSet.P(p).Data.Acc(fulltask_trls);
        resp_left = SimTrlDSet.P(p).Data.RespIsLeftOrUp(fulltask_trls);
        
        repeated_responses = diff(resp_left); % repeated responses coded as zeros
        
        repeated_responses = [1; repeated_responses]; % add first trial as not repeated
        
        % delete first response of each block - different block, different
        % session
        % session_run = SimTrlDSet.P(p).Data.SessionNum(fulltask_trls)+SimTrlDSet.P(p).Data.BlockNum(fulltask_trls);
        % run_change = diff(session_run);
        % run_change = [0; run_change];
        % repeated_responses(run_change ~= 0) = NaN;
        repeated_responses(SimTrlDSet.P(p).Data.TrialNum(fulltask_trls) == 1) = NaN;
        num_rep_button{grp} = [num_rep_button{grp}; length(find(repeated_responses == 0))];
        % perc_rep_button_normfit{grp} = [perc_rep_button_normfit{grp}; length(find(repeated_responses == 0))/length(repeated_responses)*100];
        perc_rep_button_normfit{grp} = [perc_rep_button_normfit{grp}; length(find(repeated_responses == 0))/length(repeated_responses(~isnan(repeated_responses)))*100];
        
        
        
        % repeated rule
%         rule = SimTrlDSet.P(p).Data.RuleIsHouseToLeftForTrial(fulltask_trls);
        
        house = SimTrlDSet.P(p).Data.StimIsHouse(fulltask_trls);
        
        rule_accord_response = zeros(length(fulltask_trls), 1);
        
        for trl = 1:length(house)
            if house(trl) == resp_left(trl)
                rule_accord_response(trl) = 1;
            end
        end
        
        rule_repetition = diff(rule_accord_response);
        rule_repetition = [1; rule_repetition];
        % rule_repetition(run_change ~= 0) = NaN;
        rule_repetition(SimTrlDSet.P(p).Data.TrialNum(fulltask_trls) == 1) = NaN;
        
        num_rep_rule{grp} = [num_rep_rule{grp}; length(find(rule_repetition == 0))];
        % perc_rep_rule_normfit{grp} = [perc_rep_rule_normfit{grp}; length(find(rule_repetition == 0))/length(rule_repetition)*100];
        perc_rep_rule_normfit{grp} = [perc_rep_rule_normfit{grp}; length(find(rule_repetition == 0))/length(rule_repetition(~isnan(rule_repetition)))*100];
        
    end
    
end

[h,p,ci,stats] = ttest(perc_rep_button{1}, perc_rep_button_normfit{1})
[h,p,ci,stats] = ttest(perc_rep_button{2}, perc_rep_button_normfit{2})

[h,p,ci,stats] = ttest(perc_rep_rule{1}, perc_rep_rule_normfit{1})
[h,p,ci,stats] = ttest(perc_rep_rule{2}, perc_rep_rule_normfit{2})

%%
[h,p,ci,stats] = ttest2(perc_rep_button_normfit{1}, perc_rep_button_normfit{2})
% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
plot_2groups_variables([perc_rep_button{1}, perc_rep_button_normfit{1}],...
    [perc_rep_button{2}, perc_rep_button_normfit{2}], {'Action repetitions (%)'},{'YA', 'OA', 'YA', 'OA'},...
    [1, 2, 4, 5], '')
ylim padded
axis([0 6 30 inf]);


%% including model fit on top of behavioural data

plot_2groups_variables([perc_rep_button{1}],...
    [perc_rep_button{2}], {'Action repetitions (%)'},{'YA', 'OA'},...
    [1, 2], '')
ax = gca;ax.XAxis.FontSize = 24;
axis([.5 2.5 30 75]);

hold on
errorbar([1.2 2.2], [mean(perc_rep_button_normfit{1}) , mean(perc_rep_button_normfit{2})],...
    [std(perc_rep_button_normfit{1})/sqrt(length(perc_rep_button_normfit{1})), std(perc_rep_button_normfit{2})/sqrt(length(perc_rep_button_normfit{2}))],...
    'o', 'color', 'k', 'LineWidth', 1.5,...
    'MarkerFaceColor', 'g', 'MarkerEdgeColor','k')

x0=10;
y0=10;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])

[h,p,ci,stats] = ttest2(perc_rep_rule{1}, perc_rep_rule{2})
[h,p,ci,stats] = ttest2(perc_rep_button{1}, perc_rep_button{2})

%%
[h,p,ci,stats] = ttest2(perc_rep_rule_normfit{1}, perc_rep_rule_normfit{2})
% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
plot_2groups_variables([perc_rep_rule{1}],...
    [perc_rep_rule{2}], 'Rule repetitions (%)', {'YA', 'OA', 'YA', 'OA'},...
    [1, 2], '')
ax = gca;ax.XAxis.FontSize = 24;
axis([.5 2.5 45 70]);

hold on
errorbar([1.2 2.2], [mean(perc_rep_rule_normfit{1}) , mean(perc_rep_rule_normfit{2})],...
    [std(perc_rep_rule_normfit{1})/sqrt(length(perc_rep_rule_normfit{1})), std(perc_rep_rule_normfit{2})/sqrt(length(perc_rep_rule_normfit{2}))],...
    'o', 'color', 'k', 'LineWidth', 1.5,...
    'MarkerFaceColor', 'g', 'MarkerEdgeColor','k')

x0=10;
y0=10;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])

[h,p,ci,stats] = ttest2(perc_rep_rule{1}, perc_rep_rule{2})

%% including model fit on top of behavioural data
% plot_2groups_variables(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
plot_2groups_variables([perc_rep_rule{1}, perc_rep_rule_normfit{1}],...
    [perc_rep_rule{2}, perc_rep_rule_normfit{2}], 'Rule repetitions (%)', {'YA', 'OA', 'YA', 'OA'},...
    [1, 2, 4, 5], '')
axis([0 6 40 inf]); %ylim padded

%% determine the effect of always repeating rule versus alternating on button press repetitions
clear
load('DSet.mat')

num_keyrep_rulealter =  cell(2, 1); 
perc_keyrep_rulealter =  cell(2, 1); 
num_keyrep_ruleconst =  cell(2, 1); 
perc_keyrep_ruleconst =  cell(2, 1); 

num_rulerep_keyconst =  cell(2, 1); 
perc_rulerep_keyconst =  cell(2, 1); 
num_rulerep_keyalter =  cell(2, 1); 
perc_rulerep_keyalter =  cell(2, 1); 

for p = 1:length(DSet.P)
    
    if strcmp(DSet.P(p).Spec.Group, 'older_adults')
        grp = 2;
    else
        grp = 1;
    end
    
    fulltask_trls = find(contains(DSet.P(p).Data.BlockType, 'full_task'));
    
    if ~isempty(fulltask_trls) % hierarchical decisions task
       

        % if responding always to same rule, percentage fo repeated buton
        % presses
        resp_const_rule = DSet.P(p).Data.StimIsHouse(fulltask_trls);
        keyrep = diff(resp_const_rule);
        keyrep = [NaN; keyrep];

        keyrep(DSet.P(p).Data.TrialNum(fulltask_trls) == 1) = NaN;
        num_keyrep_ruleconst{grp} = [num_keyrep_ruleconst{grp}; length(find(keyrep == 0))];
        perc_keyrep_ruleconst{grp} = [perc_keyrep_ruleconst{grp}; length(find(keyrep == 0))/length(keyrep(~isnan(keyrep)))*100];


        % if alternating the rule, percentage of repeated button presses
        stim = DSet.P(p).Data.StimIsHouse(fulltask_trls);
        rule = zeros(length(stim), 1);
        rule(2:2:end) = 1;

        resp_alter_rule = [];
        for s = 1:length(stim)
            if stim(s) == 1 && rule(s) == 1
                resp_alter_rule = [resp_alter_rule; 1];
            elseif stim(s) == 1 && rule(s) == 0
                resp_alter_rule = [resp_alter_rule; 0];
            elseif stim(s) == 0 && rule(s) == 1
                resp_alter_rule = [resp_alter_rule; 0];
            elseif stim(s) == 0 && rule(s) == 0
                resp_alter_rule = [resp_alter_rule; 1];
            end
        end

        keyrep = diff(resp_alter_rule);
        keyrep = [NaN; keyrep];

        keyrep(DSet.P(p).Data.TrialNum(fulltask_trls) == 1) = NaN;
        num_keyrep_rulealter{grp} = [num_keyrep_rulealter{grp}; length(find(keyrep == 0))];
        perc_keyrep_rulealter{grp} = [perc_keyrep_rulealter{grp}; length(find(keyrep == 0))/length(keyrep(~isnan(keyrep)))*100];


        % if always responding with same key - which rule?
        stim = DSet.P(p).Data.StimIsHouse(fulltask_trls);
        rule = stim;

        rulerep = diff(rule);
        rulerep = [NaN; rulerep];

        rulerep(DSet.P(p).Data.TrialNum(fulltask_trls) == 1) = NaN;
        num_rulerep_keyconst{grp} = [num_rulerep_keyconst{grp}; length(find(rulerep == 0))];
        perc_rulerep_keyconst{grp} = [perc_rulerep_keyconst{grp}; length(find(rulerep == 0))/length(rulerep(~isnan(rulerep)))*100];


        % if alternating key - which rule?
        stim = DSet.P(p).Data.StimIsHouse(fulltask_trls);
        rule = stim;
        for r = 2:2:length(rule)
            rule(r) = abs(rule(r)-1);
        end

        rulerep = diff(rule);
        rulerep = [NaN; rulerep];

        rulerep(DSet.P(p).Data.TrialNum(fulltask_trls) == 1) = NaN;
        num_rulerep_keyalter{grp} = [num_rulerep_keyalter{grp}; length(find(rulerep == 0))];
        perc_rulerep_keyalter{grp} = [perc_rulerep_keyalter{grp}; length(find(rulerep == 0))/length(rulerep(~isnan(rulerep)))*100];



    end
end


mean(perc_keyrep_rulealter{1})
mean(perc_keyrep_rulealter{2})
mean(perc_keyrep_ruleconst{1})
mean(perc_keyrep_ruleconst{2})

[h,p_value,ci,stats] = ttest2([perc_keyrep_rulealter{1}; perc_keyrep_rulealter{2}], [perc_keyrep_ruleconst{1}; perc_keyrep_ruleconst{2}]);


mean(perc_rulerep_keyalter{1})
mean(perc_rulerep_keyalter{2})
mean(perc_rulerep_keyconst{1})
mean(perc_rulerep_keyconst{2})

[h,p_value,ci,stats] = ttest2([perc_rulerep_keyalter{1}; perc_rulerep_keyalter{2}], [perc_rulerep_keyconst{1}; perc_rulerep_keyconst{2}])


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
    ax.XAxis.FontSize = 20;
    ax.XTickLabel= {'Young' 'Older'};
    xticks([1 2])
    ylabel(y_label_text, 'FontSize', 28, 'FontWeight','normal')
    title(title_text, 'FontSize', 22, 'FontWeight','normal')

%     x0=10;
%     y0=10;
%     width=400;
%     height=400;
%     set(gcf,'position',[x0,y0,width,height])
end

%% function plot data 2 groups, 2 conditions
function plot_2groups_2conds_inf_hierar(data_grp1_cond1,data_grp1_cond2, data_grp2_cond1, data_grp2_cond2, y_label_text, title_text)
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
            'MarkerEdgeColor',[.5 .5 .5],'MarkerSize',12, 'LineWidth', 1.5);
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
            'MarkerEdgeColor',[.5 0 0],'MarkerSize',12, 'LineWidth', 1.5);
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
    ax.XAxis.FontSize = 20;
    xticks([1 2 4 5])
    ax.XTickLabel= {'Inference' 'Full task' 'Inference' 'Full task' };
    xtickangle(45)
    ylabel(y_label_text, 'FontSize', 30, 'FontWeight','normal')
    title(title_text, 'FontSize', 32, 'FontWeight','normal')

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