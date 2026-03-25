% analyse cognitive evaluation data
% NOTES:
% AB123 - Cantab was recorded with code AB999
% AB124 - Cantab data was recorded as AB123. Cantab re-evaluation data was recorded as AB666
% AB136 - Cognitive evaluation (3Nov2022), Cantab test 2 (MTT), iPad was not registering the responses although participant was responding right – possibly discard results.
% AB104 - Second Cantab visit recorded as AB777


% latency measures should not be used in the OTS task because it was
% interrupted during assessment
% cog domains based on output from factor analyses, Método de Extração: análise de Componente Principal. 
% Método de Rotação: Varimax com Normalização de Kaiser
% grouped in 4 domains:
% working memory - SpatialSpan_direct, SpatialSpan_inverse,
% DigitSpan_direct, DigitSpan_inverse, LetterNumberSequence

% executive function/inhibitory control/control of
% impulsivity - MTTICMD, MTTTIC, OTSMCC, OTSPSFC

% processing speed - MTTLMD, RTIFMDRT, RTIFRTSD

% episodic memory - LogicalMemoryI, LogicalMemoryII
  
clear; close all

[AnalysesFolder] = fileparts(pwd);

addpath(AnalysesFolder);

group = participants_included;

data_dir = pwd;

% load data calculated here D:\Project_LC_fMRI\analyses\cognition\cogscores_composite_executive_scores.m
data_file = 'cog_data_visit1_centzsc_corrected.xlsx';
Tcog = readtable(data_file);
% missing = setdiff([group{1}, group{2}], Tcog.ParticipantID);

% create table with cog tests + cantab
cogtest_names = Tcog.Properties.VariableNames;

cogtests = table2array(Tcog(:, 8:end));

% create overallcognitive score - mean of z-scores - higher scores represent better performance

% The composite variables are: 

% working memory - SpatialSpan_direct, SpatialSpan_inverse, DigitSpan_direct, DigitSpan_inverse, LetterNumberSequence

% executive function/inhibitory control/control of
% impulsivity - MTTICMD, MTTTIC, OTSMCC, OTSPSFC (OTSPSFC Problems Solved on First Choice; OTSMCC Mean Choices to
% Correct) - OTSMCC Mean Choices to Correct should be the inverse

% Processing speed - MTTLMD, RTIFMDRT, RTIFRTSD

% episodic memory - LogicalMemoryI, LogicalMemoryII
% Processing Speed - reaction time and movement time, median and standard
% deviation


idx = find(contains(cogtest_names, 'zs_LogicalMemory'));
EpisodicMemory = mean(cogtests(:, idx-7), 2, 'omitnan');

idx = find(strcmp(cogtest_names, 'zs_RTIFMDRT') | strcmp(cogtest_names, 'zs_RTIFRTSD') | strcmp(cogtest_names, 'zs_MTTLMD')); % higher scores = worse performance{'RTIFMDRT'}{'RTIFRTSD'}
ProcessingSpeed = -mean(cogtests(:, idx-7), 2, 'omitnan');

idx = find((contains(cogtest_names, 'Span') | contains(cogtest_names, 'Letter')) & ~contains(cogtest_names, 'Total') & contains(cogtest_names, 'zs_'));
WorkingMemory = mean(cogtests(:, idx-7), 2, 'omitnan');

% idx_mtt = find(strcmp(cogtest_names, 'zs_MTTICMD') | strcmp(cogtest_names, 'zs_MTTTIC') ); % higher scores = worse performance
idx_mtt = find(strcmp(cogtest_names, 'zs_MTTTIC')); % higher scores = worse performance
idx1 = find(contains(cogtest_names, 'zs_OTSPSFC')); 
idx2 = find(contains(cogtest_names, 'zs_OTSMCC'));
Resistence2Interference = mean([-cogtests(:, idx_mtt-7), cogtests(:, idx1-7), -cogtests(:, idx2-7)], 2, 'omitnan');


% overall cognitive score
cog_score = mean([EpisodicMemory, ProcessingSpeed, WorkingMemory, Resistence2Interference],  2, 'omitnan');

% add columns with age, education and inference task accuracy
load([AnalysesFolder, filesep, 'behaviour/AccuracyTable.mat']);

accuracy = NaN(size(Tcog, 1), 1);
for s = 1:size(Tcog, 1)
    idx = find(strcmp(Tcog.ParticipantID(s), AccuracyTable.SubjID));
    accuracy(s) = AccuracyTable.Accuracy(idx);
end
% 
% figure; plot(accuracy, cog_score, 'o'); lsline
% [R,P] = corrcoef(accuracy, cog_score)

% % add age and sex to table
% [HomeDir] = fileparts(AnalysesFolder);
% file_charateristics = ([HomeDir, filesep, 'participants\participants_characterization.xlsx']);
% Tcharact = readtable(file_charateristics, 'Sheet', 'included');
% 
% for p = 1:size(Tcog, 1)
%     for pc = 1:size(Tcharact, 1)
%         
%     end
% end

% create table including task accuracy plus composite scores
Tcogscores_tmp = array2table([accuracy, cog_score, EpisodicMemory, ProcessingSpeed,...
    WorkingMemory, Resistence2Interference],...
    'VariableNames',{'InfAccuracy', 'overall_cog_score', 'EpisodicMemory', 'ProcessingSpeed',...
    'WorkingMemory', 'Resistence2Interference'});

Tcogscores(:, 1:7) = Tcog(:, 1:7);
Tcogscores(:, 8:size(Tcogscores_tmp, 2)+7) = Tcogscores_tmp;
Tcogscores.Properties.VariableNames = [cogtest_names(1:7), 'InfAccuracy',...
    'overall_cog_score', 'EpisodicMemory', 'ProcessingSpeed',...
    'WorkingMemory', 'Resistence2Interference'];

% save excel file for SPSS analysis
filename = 'cogdomains_3FactorsPCA_visit1.xlsx';
% writetable(Tcogscores,filename);

%% multiple regressions for each group separately

% young
% y = Tcogscores.InfAccuracy(Tcogscores.Group == 1);
% X = [Tcogscores.ProcessingSpeed(Tcogscores.Group == 1),...
%     Tcogscores.WorkingMemory(Tcogscores.Group == 1),...
%     Tcogscores.Resistence2Interference(Tcogscores.Group == 1),...
%     ones(length(find(Tcogscores.Group == 1)), 1)]
% [b,bint,~,~,stats] = regress(y,X)

% young - standardized
y = zscore(Tcogscores.InfAccuracy(Tcogscores.Group == 1));
X = [zscore([Tcogscores.ProcessingSpeed(Tcogscores.Group == 1),...
    Tcogscores.WorkingMemory(Tcogscores.Group == 1),...
    Tcogscores.Resistence2Interference(Tcogscores.Group == 1)]),...
    ones(length(find(Tcogscores.Group == 1)), 1)]
[b_stand_yng,bint_stand_yng,~,~,stats] = regress(y,X)


% older
% y = Tcogscores.InfAccuracy(Tcogscores.Group == 2);
% X = [Tcogscores.ProcessingSpeed(Tcogscores.Group == 2),...
%     Tcogscores.WorkingMemory(Tcogscores.Group == 2),...
%     Tcogscores.Resistence2Interference(Tcogscores.Group == 2),...
%     ones(length(find(Tcogscores.Group == 2)), 1)]
% [b,bint,~,~,stats] = regress(y,X)

% older- standardized
y = zscore(Tcogscores.InfAccuracy(Tcogscores.Group == 2));
X = [zscore([Tcogscores.ProcessingSpeed(Tcogscores.Group == 2),...
    Tcogscores.WorkingMemory(Tcogscores.Group == 2),...
    Tcogscores.Resistence2Interference(Tcogscores.Group == 2)]),...
    ones(length(find(Tcogscores.Group == 2)), 1)]
[b_stand_old,bint_stand_old,~,~,stats] = regress(y,X)

Told_zscore = [Tcogscores((Tcogscores.Group == 2), 11:13), Tcogscores((Tcogscores.Group == 2), 8)];
oldzscore = table2array(Told_zscore);
oldzscore = zscore(oldzscore)

Told_zscore.ProcessingSpeed = oldzscore(:, 1);
Told_zscore.WorkingMemory = oldzscore(:, 2);
Told_zscore.Resistence2Interference = oldzscore(:, 3);
Told_zscore.InfAccuracy = oldzscore(:, 4);

LM_older = fitlm([Tcogscores((Tcogscores.Group == 2), 11:13), Tcogscores((Tcogscores.Group == 2), 8)])

LM_older_stand = fitlm(Told_zscore)

%%
Tyng_zscore = [Tcogscores((Tcogscores.Group == 1), 11:13), Tcogscores((Tcogscores.Group == 1), 8)];
yngzscore = table2array(Tyng_zscore);
yngzscore = zscore(yngzscore);

Tyng_zscore.ProcessingSpeed = yngzscore(:, 1);
Tyng_zscore.WorkingMemory = yngzscore(:, 2);
Tyng_zscore.Resistence2Interference = yngzscore(:, 3);
Tyng_zscore.InfAccuracy = yngzscore(:, 4);

LM_ynger = fitlm([Tcogscores((Tcogscores.Group == 2), 11:13), Tcogscores((Tcogscores.Group == 2), 8)])

LM_ynger_stand = fitlm(Tyng_zscore)

%% plot standardized coefficients
% 95% confidence intervals
figure; 
bar([1, 2, 3], [b_stand_yng(1:3)'], 'FaceColor','None','EdgeColor',[0 0 0],'LineWidth',1.5);
hold on
errorbar([1, 2, 3], [b_stand_yng(1:3)''],...
    [b_stand_yng(1:3)' - bint_stand_yng(1:3, 1)'],...
    [b_stand_yng(1:3)' + bint_stand_yng(1:3, 2)'],...
    ".", 'LineWidth', 1.5, 'color', 'k')

hold on
bar([5, 6, 7], [b_stand_old(1:3)'], 'FaceColor','None','EdgeColor',[.75 0.5 0.5],'LineWidth',1.5);
hold on
errorbar([5, 6, 7], [b_stand_old(1:3)'],...
    [b_stand_old(1:3)' - bint_stand_old(1:3, 1)'],...
    [b_stand_old(1:3)' + bint_stand_old(1:3, 2)'],...
    ".", 'LineWidth', 1.5, 'color', [.75 0.5 0.5])

box off
hold off;
% axis([0 6 -inf inf]);
ax = gca;
ax.LineWidth = 2.5; 
ax.FontSize = 24;
ax.FontName = 'Arial';
ax.Color = 'none';
% ylim padded

ax.XAxis.FontSize = 14;
xticks([1, 2, 3, 5, 6, 7])
ax.XTickLabel= {'Processing Speed', 'Working Memory', 'Executive Control'};
xtickangle(45)
ylabel('Standardized Betas', 'FontSize', 27, 'FontWeight','normal')
% title(title_text, 'FontSize', 32, 'FontWeight','normal')


%% standard errors
figure; 
bar([1, 2, 3], [LM_ynger_stand.Coefficients.Estimate(2:4)'], 'FaceColor','None','EdgeColor',[0 0 0],'LineWidth',1.5);
hold on
errorbar([1, 2, 3], [LM_ynger_stand.Coefficients.Estimate(2:4)'],...
    [LM_ynger_stand.Coefficients.SE(2:4)'],...
    ".", 'LineWidth', 1.5, 'color', 'k')

hold on
bar([5, 6, 7], [LM_older_stand.Coefficients.Estimate(2:4)'], 'FaceColor','None','EdgeColor',[.75 0.5 0.5],'LineWidth',1.5);
hold on
errorbar([5, 6, 7], [LM_older_stand.Coefficients.Estimate(2:4)'],...
    [LM_older_stand.Coefficients.SE(2:4)'],...
    ".", 'LineWidth', 1.5, 'color', [.75 0.5 0.5])

box off
hold off;
% axis([0 6 -inf inf]);
ax = gca;
ax.LineWidth = 2.5; 
ax.FontSize = 24;
ax.FontName = 'Arial';
ax.Color = 'none';
% ylim padded

ax.XAxis.FontSize = 14;
xticks([1, 2, 3, 5, 6, 7])
ax.XTickLabel= {'Processing Speed', 'Working Memory', 'Executive Control'};
xtickangle(45)
ylabel('Standardized Betas', 'FontSize', 27, 'FontWeight','normal')
% title(title_text, 'FontSize', 32, 'FontWeight','normal')

%% t-tests across groups 

[H,P,CI,STATS] = ttest2(Tcogscores.EpisodicMemory(Tcogscores.Group == 1),...
    Tcogscores.EpisodicMemory(Tcogscores.Group == 2))

[H,P,CI,STATS] = ttest2(Tcogscores.ProcessingSpeed(Tcogscores.Group == 1),...
    Tcogscores.ProcessingSpeed(Tcogscores.Group == 2))

[H,P,CI,STATS] = ttest2(Tcogscores.WorkingMemory(Tcogscores.Group == 1),...
    Tcogscores.WorkingMemory(Tcogscores.Group == 2))

[H,P,CI,STATS] = ttest2(Tcogscores.Resistence2Interference(Tcogscores.Group == 1),...
    Tcogscores.Resistence2Interference(Tcogscores.Group == 2))


%% comparing group difference in accuracy on the residuals after accounting for executive control 
% [b,bint,r,rint,stats] = regress(y,X,alpha)
[B,BINT,R,RINT,STATS] = regress(Tcogscores.InfAccuracy, [Tcogscores.Resistence2Interference,...
    ones(length(Tcogscores.Resistence2Interference), 1)])  

figure; plot(Tcogscores.InfAccuracy, Tcogscores.Resistence2Interference, 'o') 

[H,P,CI,STATS] = ttest2(R(Tcogscores.Group == 1),...
    R(Tcogscores.Group == 2))



%% plot inference accuracy vs executive cognitive scores

figure
plot(Tcogscores.overall_cog_score(Tcogscores.Group == 2), Tcogscores.InfAccuracy(Tcogscores.Group == 2).*100, 'd',...
    'MarkerEdgeColor',[.75 0.5 0.5],'MarkerFaceColor',[.75 0.5 0.5],'MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(Tcogscores.InfAccuracy(Tcogscores.Group == 2), Tcogscores.overall_cog_score(Tcogscores.Group == 2))
if P(1, 2) < .05
    h2 = lsline; set(h2(1),'color',[.75 0.5 0.5], 'LineWidth', 2)
end

hold on
plot(Tcogscores.overall_cog_score(Tcogscores.Group == 1),Tcogscores.InfAccuracy(Tcogscores.Group == 1).*100, 'o',...
    'MarkerEdgeColor', 'k','MarkerFaceColor', 'k','MarkerSize',6, 'LineWidth', 1); 
[R,P] = corrcoef(Tcogscores.InfAccuracy(Tcogscores.Group == 1), Tcogscores.overall_cog_score(Tcogscores.Group == 1))
if P(1, 2) < .05
    h1 = lsline; set(h1(1),'color','k')
end
hold on


% [R,P] = corrcoef(LC_memory_older(:, 6), LC_memory_older(:, scr+1));
% if P(1, 2) < .05
%     lsline
% end
box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
ylabel('Accuracy (%)', 'FontSize', 28, 'FontWeight','normal')
xlabel({'Global cognition (z-score)'}, 'FontSize', 28, 'FontWeight','normal')


% [H,P,CI,STATS] = ttest2(Tcogscores.overall_cog_score(Tcogscores.Group == 1), Tcogscores.overall_cog_score(Tcogscores.Group == 2));

% %%
% 
% figure; plot(LC_memory_older(:, 1), LC_memory_older(:, end), 'o',  'color', [.8 .8 .8], ...
%             'MarkerFaceColor',[.8 .8 .8], 'MarkerEdgeColor','k','MarkerSize',8, 'LineWidth', 1); lsline
% ax = gca;
% c = ax.Color;
% ax.FontSize = 22;
% ax.FontName = 'Arial';
% ax.Color = 'none';
% xlabel('LC MRI contrast', 'FontSize', 24, 'FontWeight','normal')
% ylabel('Memory score', 'FontSize', 24, 'FontWeight','normal')

%% compare cognitive score across groups
% plot_all_data_2groups(data_grp1, data_grp2, y_label_text, title_text)
% 
% plot_all_data_2groups(Tcogscores.overall_cog_score(Tcogscores.Group == 1),...
%     Tcogscores.overall_cog_score(Tcogscores.Group == 2), {'Global cognition', '(z-score)'}, '')

% plot_2groups_errorbars(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
plot_2groups_errorbars(Tcogscores.overall_cog_score(Tcogscores.Group == 1),...
    Tcogscores.overall_cog_score(Tcogscores.Group == 2), {'Global cognition', '(z-score)'}, {'YA', 'OA'}, [1, 2], '')
axis([0 3 -inf inf]);
ylim padded
x0=10;
y0=10;
width=300;
height=400;
set(gcf,'position',[x0,y0,width,height])


[~, pvaluecog] = ttest2(Tcogscores.overall_cog_score(Tcogscores.Group == 1),...
    Tcogscores.overall_cog_score(Tcogscores.Group == 2))
  
%% effect of age on global cognition

% [R,P]= corrcoef(Tcogscores.overall_cog_score(Tcogscores.Group == 1), Tcogscores.age(Tcogscores.Group == 1)) 
% [R,P]= corrcoef(Tcogscores.overall_cog_score(Tcogscores.Group == 2), Tcogscores.age(Tcogscores.Group == 2)) 


figure; 
plot(Tcogscores.age(Tcogscores.Group == 2), Tcogscores.overall_cog_score(Tcogscores.Group == 2), 'd', 'color', 'k',...
    'MarkerEdgeColor','r','MarkerSize',8, 'LineWidth', 1); 
[R,P] = corrcoef(Tcogscores.overall_cog_score(Tcogscores.Group == 2), Tcogscores.age(Tcogscores.Group == 2));
if P(1, 2) < .05
    h2 = lsline; set(h2(1),'color','r')
end
hold on
plot(Tcogscores.age(Tcogscores.Group == 1), Tcogscores.overall_cog_score(Tcogscores.Group == 1), 'o', 'color', 'k',...
    'MarkerEdgeColor','k','MarkerSize',8, 'LineWidth', 1); 
[R,P] = corrcoef(Tcogscores.overall_cog_score(Tcogscores.Group == 1), Tcogscores.age(Tcogscores.Group == 1));
if P(1, 2) < .05
    h1 = lsline; set(h1(1),'color','k')
end



% [R,P] = corrcoef(LC_memory_older(:, 6), LC_memory_older(:, scr+1));
% if P(1, 2) < .05
%     lsline
% end
box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel('Age (years)', 'FontSize', 28, 'FontWeight','normal')
ylabel({'Global cognition', '(z-score)'}, 'FontSize', 28, 'FontWeight','normal')


%% effect of age on inference task accuracy

% [R,P]= corrcoef(Tcogscores.overall_cog_score(Tcogscores.Group == 1), Tcogscores.age(Tcogscores.Group == 1)) 
% [R,P]= corrcoef(Tcogscores.overall_cog_score(Tcogscores.Group == 2), Tcogscores.age(Tcogscores.Group == 2)) 


figure; 
plot(Tcogscores.age(Tcogscores.Group == 2), Tcogscores.InfAccuracy(Tcogscores.Group == 2).*100, 'd', 'color', 'k',...
    'MarkerEdgeColor','r','MarkerSize',8, 'LineWidth', 1); 
[R,P] = corrcoef(Tcogscores.InfAccuracy(Tcogscores.Group == 2), Tcogscores.age(Tcogscores.Group == 2))
if P(1, 2) < .05
    h2 = lsline; set(h2(1),'color','r')
end
hold on
plot(Tcogscores.age(Tcogscores.Group == 1), Tcogscores.InfAccuracy(Tcogscores.Group == 1).*100, 'o', 'color', 'k',...
    'MarkerEdgeColor','k','MarkerSize',8, 'LineWidth', 1); 
[R,P] = corrcoef(Tcogscores.InfAccuracy(Tcogscores.Group == 1), Tcogscores.age(Tcogscores.Group == 1))
if P(1, 2) < .05
    h1 = lsline; set(h1(1),'color','k')
end



% [R,P] = corrcoef(LC_memory_older(:, 6), LC_memory_older(:, scr+1));
% if P(1, 2) < .05
%     lsline
% end
box off
ax = gca; ax.LineWidth = 2.5;
ax.FontSize = 20; ax.FontName = 'Arial'; ax.Color = 'none';
ylim padded; xlim padded;
xlabel('Age (years)', 'FontSize', 28, 'FontWeight','normal')
ylabel({'Accuracy (%)'}, 'FontSize', 28, 'FontWeight','normal')

%% function plot data 2 groups 1 task
function plot_all_data_2groups(data_grp1, data_grp2, y_label_text, title_text)
       figure;
    % plot data for group 1
        yMean=mean(data_grp1, 'omitnan');
    y_se = std(data_grp1, 'omitnan')/sqrt(length(data_grp1));
    
        %plot the mean+-SEM box
        %   RECTANGLE('Position',pos) creates a rectangle in 2-D coordinates.
%   Specify pos as a four-element vector of the form [x y w h] in data
%   units. The x and y elements determine the location and the w and h
%   elements determine the size. The function plots into the current axes
%   without clearing existing content from the axes.
    box on
    rectangle('Position',[1-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1);
    hold on
    for y=1:length(data_grp1)
        plot(1+rand*0.2-0.1, data_grp1(y),'-o', 'color', [.8 .8 .8], ...
            'MarkerEdgeColor','k','MarkerSize',8, 'LineWidth', 1);
        hold on;
    end
%     %plot line at zero    
%     plot([0 4],[0 0],'--k','LineWidth', 1);
     %plot the mean line    
    plot([1-0.3 1+0.3],[yMean yMean] ,'Color','k','LineWidth',5);
   

    % group 2
    yMean = mean(data_grp2, 'omitnan');
    y_se = std(data_grp2, 'omitnan')/sqrt(length(data_grp2));
   rectangle('Position',[2-0.3,yMean-y_se, 0.6, 2*y_se ],'FaceColor',[.7 .7 .7],'EdgeColor', [.7 .7 .7],'LineWidth',0.1)
   
    for y=1:length(data_grp2)
        plot(2+rand*0.2-0.1, [data_grp2(y)] ,'-d', 'color', [.8 .8 .8], ...
            'MarkerEdgeColor','r','MarkerSize',8, 'LineWidth', 1);
        hold on;  
    end

     %plot the mean line
    plot([2-0.3 2+0.3],[yMean yMean] ,'Color','k','LineWidth',5);
    

    % axes('XColor','none');
    hold off; box off
    axis([0.5 2.5 -inf inf]);
    ax = gca; ax.LineWidth = 2.5;
    ax.FontSize = 28;
    ax.FontName = 'Arial';
    ax.Color = 'none';
    xticks([1 2])
    ax.XTickLabel= {'YA' 'OA'};

    ylabel(y_label_text, 'FontSize', 28, 'FontWeight','normal')
    title(title_text, 'FontSize', 24, 'FontWeight','normal')
    
%     x0=10;
%     y0=10;
%     width=400;
%     height=400;
%     set(gcf,'position',[x0,y0,width,height])
end

%%
function plot_2groups_errorbars(data_grp1, data_grp2, y_label_text, x_label_text, x_ticks, title_text)
% data with observations x variables
    figure;
    % plot data for group 1
    yMean=nanmean(data_grp1, 1);
    y_se = std(data_grp1,[], 1, 'omitnan')/sqrt(size(data_grp1, 1));
    
    pst = -2;
    for v = 1:size(data_grp1, 2)
        pst = pst + 3;
        for y=1:size(data_grp1, 1)
            plot(pst+(rand-0.5)*0.2, data_grp1(y, v),'-o', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.75 .75 .75],'MarkerSize', 8, 'LineWidth', 1.5);
            hold on;
        end

        errorbar(pst, yMean(v), y_se(v),"_","MarkerSize", 25,...
            "MarkerEdgeColor","k","MarkerFaceColor","k", 'LineWidth', 1.5, 'color', 'k'); 
    end
    
    % group 2
    yMean=nanmean(data_grp2, 1);
    y_se = std(data_grp2,[], 1, 'omitnan')/sqrt(size(data_grp2, 1));
    
    pst = -1;
    for v = 1:size(data_grp2, 2)
        pst = pst + 3;

        for y=1:size(data_grp2, 1)
            plot(pst+(rand-0.5)*0.2, data_grp2(y, v),'-d', 'color', [.8 .8 .8], ...
                'MarkerEdgeColor',[.75 0.5 0.5],'MarkerSize',8, 'LineWidth', 1.5);
            hold on;
        end

        errorbar(pst, yMean(v), y_se(v),"_","MarkerSize",25,...
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
    ax.XAxis.FontSize = 18;
    xticks(x_ticks);
    ax.XTickLabel= x_label_text;
    xtickangle(0)
    ylabel(y_label_text, 'FontSize', 28, 'FontWeight','normal')
    title(title_text, 'FontSize', 24, 'FontWeight','normal')

%     x0=10;
%     y0=10;
%     width=400;
%     height=400;
%     set(gcf,'position',[x0,y0,width,height])
end