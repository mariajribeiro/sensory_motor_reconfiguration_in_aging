% analyses of behaviour from visual categorization task - testign responses
% to faces and houses using only one rule (counterbalanced across participants)
clear
group = cell(2, 1);
group{1} = {'AB193', 'AB194', 'AB197', 'AB199', 'AB203', 'AB204'};
group{2} = {'AB190', 'AB191', 'AB192','AB195', 'AB196', 'AB198', ...
    'AB200', 'AB201', 'AB202', 'AB205', 'AB206'};

parentFolder = fileparts(pwd);
parentFolder_2 = fileparts(parentFolder);

data_dir = [parentFolder_2, '\VisualCategorizationTask_lab94\exp_data\'];
VisualCat_RT = cell(2, 1);
for grp = 1:2
    for sbj = 1:length(group{grp})
        subject = char(group{grp}(sbj));
        S = dir([parentFolder_2, '\VisualCategorizationTask_lab94\exp_data\', subject]);
        sessions = [];
        for f = 1:length(S)
            if contains(S(f).name, 'session')
                sessions = [sessions, str2num(S(f).name(8))];
            end
        end
        response_trials = [];  choice_numb = 0; accuracy = []; stim_id = [];
        for session = sessions

            folder_session = [parentFolder_2, '\VisualCategorizationTask_lab94\exp_data\', char(subject), '\session', num2str(session)];
            MyFolderInfo = dir(folder_session);
            runs = size(MyFolderInfo, 1)-2;
            for run = 1:runs
                sample_dir = [data_dir, subject, '\session', num2str(session),'\run', num2str(run)];
                Files=dir(fullfile(sample_dir,'*.mat'));
                for fl=1:size(Files, 1)
                    if contains(Files(fl).name, subject)
                        filename = Files(fl).name;
                    end
                end
                
                load([sample_dir filesep filename]);
                rule = p.rule_visual_categorization; % rule = 0 face left, house right; 
                % rule = 1 house left, face right
                
                for j=1:length(p.out.log)
                    wrong_button = 0;
                    if strcmp(p.out.log{j}(2), 'CHOICE_TRIAL_STIMOFF')
                        % face - stim_id = 0; house - stim_id = 1 
                        stim_id = cell2mat(p.out.log{j-1}(3));
                        if strcmp(p.out.log{j+1}(2), 'BUTTON_PRESS')
                        % time, reaction time, response side (1 - left response; 2 - right response), choice trial number, validity
                        % for inference only task - 3 - upper response; 4 - lower response
                        
                            reaction_time = p.out.log{j+1}{1};
                            
                            if j+3 <= length(p.out.log)
                                if strcmp(p.out.log{j+3}(2), 'BUTTON_PRESS')
                                    repeated_response = 1;
                                else
                                    repeated_response = 0;
                                end
                            end
                            if contains({'z'}, p.out.log{j+1}(3))
                                response_side = 1; % left response
                            elseif contains({'m'}, p.out.log{j+1}(3))
                                response_side = 0; % right response
                            else
                                response_side = NaN; reaction_time = NaN;
                                wrong_button = 1;
                            end

                            no_response = 0;
                        elseif strcmp(p.out.log{j+1}(2), 'NO_RESPONSE')
                                no_response = 1;
                                reaction_time = NaN;
                                response_side = NaN;
                        end
%                         reaction time, response side (1 - left response;
%                         2 - right response), repeated_response, no
%                         response
                        % if size(response_trials, 1) == 178
                        %     a = 0;
                        % end


                        response_trials = [response_trials; stim_id, reaction_time, response_side,  repeated_response, no_response, wrong_button];
                        
                   elseif strcmp(p.out.log{j}(2), 'CHOICE_TRIAL_ACCURACY')
                       if strcmp(subject, 'AB192') && run == 2
                           acc = 0;
                            if cell2mat(p.out.log{j-4}(3)) == 0 && strcmp(p.out.log{j-2}(3), 'm')
                                acc = 1;
                            elseif cell2mat(p.out.log{j-4}(3)) == 1 && strcmp(p.out.log{j-2}(3), 'z')
                                acc = 1;
                            end
                            accuracy = [accuracy; acc];
                       else
                            accuracy = [accuracy; p.out.log{j}{3}];
                       end
                   end
                end
            end
        end


        % outputs - median reaction time faces; median reaction time houses;
        % total median reaction time; 
        % percentage repeated responses 
        % accuracy without repeated responses or very fast < 150
        % ms responses
        VisualCat_Missed{grp}(sbj, :) = length( find(response_trials(:, 5) == 1));
        VisualCat_Rep{grp}(sbj, :) = length( find(response_trials(:, 4) == 1));
        trials2exclude = [find(response_trials(:, 4) == 1)', find(response_trials(:, 2) < .150), find(response_trials(:, 5) == 1)', find(response_trials(:, 6) == 1)'];
        response_trials(trials2exclude, :) = [];
        % total, faces, houses
        VisualCat_RT{grp}(sbj, :) = [median(response_trials(:, 2)), median(response_trials(response_trials(:, 1) == 0, 2)), ...
            median(response_trials(response_trials(:, 1) == 1, 2))];
        
        accuracy(trials2exclude) = [];
        VisualCat_Acc{grp}(sbj, :) = [mean(accuracy), mean(accuracy(response_trials(:, 1) == 0)), mean(accuracy(response_trials(:, 1) == 1))];
        VisualCat_Errors{grp}(sbj, :) = length(find(accuracy == 0));
    end
end

save_folder = [pwd, '\visual_categorization_results'];
save([save_folder, '\VisualCat_Missed.mat'], 'VisualCat_Missed');
save([save_folder, '\VisualCat_Rep.mat'], 'VisualCat_Rep');
save([save_folder, '\VisualCat_RT.mat'], 'VisualCat_RT');
save([save_folder, '\VisualCat_Acc.mat'], 'VisualCat_Acc');


%% accuracy 
plot_2groups_variables(VisualCat_Acc{1}(:, 1).*100, VisualCat_Acc{2}(:, 1).*100,'Accuracy (%)',...
    '', ...
   1.5 , '')

axis([.5 2.5 95 100.8]);
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0);
    xticks([1 2])
    xticklabels({'YA', 'OA'});
    x0=10;
    y0=10;
    width=300;
    height=400;
    set(gcf,'position',[x0,y0,width,height])


[H,P,CI,STATS] = ttest2(VisualCat_Acc{1}(:, 1).*100, VisualCat_Acc{2}(:, 1).*100)


    %% reaction time
plot_2groups_variables(VisualCat_RT{1}(:, 1), VisualCat_RT{2}(:, 1),'Reaction time (s)',...
    '', ...
   1.5 , '')

axis([.5 2.5 0 inf]);
ax = gca;ax.XAxis.FontSize = 24;
xtickangle(0);
    xticks([1 2])
    xticklabels({'YA', 'OA'});
    x0=10;
    y0=10;
    width=300;
    height=400;
    set(gcf,'position',[x0,y0,width,height])

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
