% create variable with task and behavioural data from all participants
% Maria Ribeiro - April2023
clear; close all

parentFolder = fileparts(pwd);

addpath(parentFolder);
group = participants_included;

parentFolder_2 = fileparts(parentFolder);

data_dir = [parentFolder_2, '\data\ET_data\'];
group_name = {'young_adults', 'older_adults'};

DSet.Spec.CueMeanDiff = .5;
DSet.Spec.CueSigma = .4;

i = 0;
for grp = 1:2
    for sbj = 1:length(group{grp})
        i = i+1; 
        subject = char(group{grp}(sbj));
        
        DSet.P(i).Spec.Group = group_name{grp};
        DSet.P(i).Spec.SubjID = subject;
        
        % initialize fields
        DSet.P(i).Data.RespIsLeftOrUp = [];
        DSet.P(i).Data.Acc = [];
        DSet.P(i).Data.RT = [];
        DSet.P(i).Data.RepeatedResp = [];
        DSet.P(i).Data.NoResponse = [];
        DSet.P(i).Data.RtIsValid = [];
        DSet.P(i).Data.HazardRate = [];
        DSet.P(i).Data.CueLoc = {};
        DSet.P(i).Data.SessionNum = [];
        DSet.P(i).Data.BlockNum = [];
        DSet.P(i).Data.TrialNum = [];
        DSet.P(i).Data.BlockType = {};
        DSet.P(i).Data.NumCuesInTrial = [];
        DSet.P(i).Data.StimIsHouse = [];
        DSet.P(i).Data.RuleIsHouseToLeftForTrial = [];
        DSet.P(i).Data.RuleIsHouseToLeftForCue = [];
        DSet.P(i).Data.DistIsUpperForTrial = [];
        DSet.P(i).Data.DistIsUpperForCue = [];
        DSet.P(i).Spec.RuleConfiguration = [];
        
        
        % each subject has at least one session outside the scanner (sessions 1 and 2 and 4) and one inside
        % the scanner (session 3)
        S = dir([parentFolder_2, '\data\ET_data\', char(subject)]);
        sessions = []; % sessions = sum([S(~ismember({S.name},{'.','..'})).isdir]);
        for f = 1:length(S)
            if contains(S(f).name, 'session')
                sessions = [sessions, str2num(S(f).name(8))];
            end
        end
        acc_runs = cell(3, 1); acc_runs_last_sample = cell(3, 1); sbjacc_vs_idealobserver_tmp = cell(3, 1); sbjacc_vs_lastsample_tmp = cell(3, 1);
        for session = sessions
            
            if ismember(session, [1, 2]) 
                cond = 1; % outside scanner
                cond_name = 'full_task_lab';
            elseif session == 3
                cond = 2; % inside scanner
                cond_name = 'full_task_scanner';
            elseif session == 4
                cond = 3; % inference-only task
                cond_name = 'inference-only';
            end
            
            
            folder_session = [parentFolder_2, '\data\ET_data\', char(subject), '\session', num2str(session)];
            MyFolderInfo = dir(folder_session);
            runs = size(MyFolderInfo, 1)-2;
            for run = 1:runs
                clear p
                % for accuracy measurements which runs not to consider         
                if ismember(subject, {'AB057', 'AB100', 'AB101', 'AB067', 'AB112', 'AB174', 'AB176'}) && session == 1 && run == 1
                % AB112 - did not understand the task until run2
                % AB057, AB100, AB101, AB067 - first run stopped prematurely by mistake
                % 'AB174' - had difficulty seeing the stimulus - wore
                % glasses for the next runs
                % 'AB176' - forgot the rule and asked to restart
                    continue
                elseif strcmp(subject, 'AB132') && (session == 1 && ismember(run, [1, 2, 3]))
                    % this participant did not understand the task up to
                    % the last run of session1
                    continue
                elseif strcmp(subject, 'AB134') && session == 3 && ismember(run, 1)
                    % problems with using the response boxes in the scanner
                    % during the first run
                    continue
               elseif strcmp(subject, 'AB140') && session == 4 && run == 2 % by mistake was responding with opposite keys
                    continue
                elseif strcmp(subject, 'AB144') && session == 1 && run == 3 % did not remember task instructions - had to repeat training
                    continue
                elseif strcmp(subject, 'AB144') && session == 3 % could not see stimulus in the scanner - not feeling well
                    continue
                elseif strcmp(subject, 'AB148') && session == 1 % had not understood task instructions properly ok in session 2
                    continue
                elseif strcmp(subject, 'AB152') && session == 1 && run  == 3 % mistake with rule setting
                    continue
                elseif strcmp(subject, 'AB158') && session == 3 && run  == 1 % response boxes in the scanner got stuck 
                    continue
                elseif strcmp(subject, 'AB161') && session == 3 && run  == 1 % was using the wrong response buttons in the scanner
                    continue
                elseif strcmp(subject, 'AB174') && session == 1 && run  == 1 % could not see stimulus properly - used reading glasses from then on
                    continue
                elseif strcmp(subject, 'AB176') && session == 1 && run  == 1 % was applying the rule wrongly, asked to restart
                    continue
                elseif strcmp(subject, 'AB178') && session == 3 && run  == 1 % aborted run
                    continue
                elseif strcmp(subject, 'AB181') && session == 3 && run  == 1 % aborted run
                    continue
                end
                
                sample_dir = [data_dir, subject, '\session', num2str(session),'\run', num2str(run)];
                Files=dir(fullfile(sample_dir,'*.mat'));
                for fl=1:size(Files, 1)
                    if contains(Files(fl).name, subject)
                        filename = Files(fl).name;
                    end
                end
                

                load([sample_dir filesep filename]);
                if isempty(DSet.P(i).Spec.RuleConfiguration)
                    DSet.P(i).Spec.RuleConfiguration = p.rule_hierarchical_decision;
                end
                %%
                response_trials = [];  choice_numb = 0; accuracy = [];
                for j=1:length(p.out.log)
                    if strcmp(p.out.log{j}(2), 'CHOICE_TRIAL_STIMOFF')
                        % face - stim_id = 0; house - stim_id = 1 
                        choice_numb = choice_numb + 1;
                        % choice_trials} = [choice_trials; session, run, cell2mat(p.out.log{i}(1))-start_time, cell2mat(p.out.log{i}(3))];
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
                            if session == 4
                                if any(contains({'UpArrow'}, p.out.log{j+1}(3)))
                                    response_side = 1; % upper response
                                elseif any(contains({'LeftArrow'}, p.out.log{j+1}(3)))
                                    response_side = 0; % lower response
                                else
                                    response_side = NaN;
                                end
                            else
                                if ismember(subject, {'AB142', 'AB152'}) && session == 3 && run == 1 % response boxes switched need to analyse responses as opposite
                                    if any(contains({'z', '49', '50'}, p.out.log{j+1}(3)))
                                        response_side = 0; % right response
                                    elseif any(contains({'m', '51', '52'}, p.out.log{j+1}(3)))
                                        response_side = 1; % left response
                                    else
                                        response_side = NaN; reaction_time = NaN;
                                    end
                                else
                                    if any(contains({'z', '49', '50', '250'}, p.out.log{j+1}(3)))
                                        response_side = 1; % left response
                                    elseif any(contains({'m', '51', '52', '253'}, p.out.log{j+1}(3)))
                                        response_side = 0; % right response
                                    else
                                        response_side = NaN; reaction_time = NaN;
                                    end
                                end
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
                        response_trials = [response_trials; reaction_time, response_side,  repeated_response, no_response];
                        
                    elseif strcmp(p.out.log{j}(2), 'CHOICE_TRIAL_ACCURACY')
                        if ismember(subject, {'AB142', 'AB152'}) && session == 3 && run == 1 % response boxes switched need to analyse responses as opposite
                            accuracy = [accuracy; abs(p.out.log{j}{3}-1)];
                        else
                            accuracy = [accuracy; p.out.log{j}{3}];
%                             if isempty(p.out.log{j}{3})
%                                stop = 1 
%                             end
                        end
                   end
                end
                
                %% for trials where there were two or more responses do not
                % use response and accuracy data
                invalid_trials = find(response_trials(:, 3) == 1);
                no_response_trials = find(isnan(response_trials(:, 1))); % NO RESPONSE OR PRESSED THE WRONG KEY
                accuracy([invalid_trials; no_response_trials]) = NaN;
                response_trials([invalid_trials; no_response_trials], 1:2) = NaN;
                
                DSet.P(i).Data.RespIsLeftOrUp = [DSet.P(i).Data.RespIsLeftOrUp; response_trials(:, 2)];
                DSet.P(i).Data.Acc = [DSet.P(i).Data.Acc; accuracy];
                DSet.P(i).Data.RT = [DSet.P(i).Data.RT; response_trials(:, 1)];
                DSet.P(i).Data.RepeatedResp = [DSet.P(i).Data.RepeatedResp; response_trials(:, 3)];
                DSet.P(i).Data.NoResponse = [DSet.P(i).Data.NoResponse; response_trials(:, 4)];
                % DSet.P(i).Data.RtIsValid: Contains a 1 if the response time was in the permitted window, and contains a 0 if the response time was outside the permitted window. 
                % Also contains 0 if there was more than one button press in trial within the permitted time window. Permitted time window was 2 s.
                RtIsValid = ones(length(accuracy), 1);
                RtIsValid([invalid_trials; no_response_trials]) = 0;
                DSet.P(i).Data.RtIsValid = [DSet.P(i).Data.RtIsValid; RtIsValid];
                
                DSet.P(i).Data.HazardRate = [DSet.P(i).Data.HazardRate; ones(length(accuracy), 1).*(1/70)];
                
                % define trials for this run
                choice_trials = find(isnan(p.sequence.sample));
                for c = 1:length(choice_trials)
                    if c == 1
                        DSet.P(i).Data.CueLoc = [DSet.P(i).Data.CueLoc; {p.sequence.sample(1:choice_trials(c)-1)}];  
                        DSet.P(i).Data.NumCuesInTrial = [DSet.P(i).Data.NumCuesInTrial; length(p.sequence.sample(1:choice_trials(c)-1))];
                    else
                        DSet.P(i).Data.CueLoc = [DSet.P(i).Data.CueLoc; {p.sequence.sample(choice_trials(c-1)+1:choice_trials(c)-1)}];
                        DSet.P(i).Data.NumCuesInTrial = [DSet.P(i).Data.NumCuesInTrial; length(p.sequence.sample(choice_trials(c-1)+1:choice_trials(c)-1))];
                    end
                    DSet.P(i).Data.SessionNum = [DSet.P(i).Data.SessionNum; session];
                    DSet.P(i).Data.BlockNum = [DSet.P(i).Data.BlockNum; run];
                    DSet.P(i).Data.TrialNum = [DSet.P(i).Data.TrialNum; c];
                    DSet.P(i).Data.BlockType = [DSet.P(i).Data.BlockType; cond_name];
                    
                    if ~strcmp(cond_name, 'inference-only')
                        DSet.P(i).Data.StimIsHouse = [DSet.P(i).Data.StimIsHouse; p.sequence.stim(choice_trials(c))];
                        if p.sequence.generating_side(choice_trials(c)) > 0 && p.rule_hierarchical_decision == 0
                            DSet.P(i).Data.RuleIsHouseToLeftForTrial = [DSet.P(i).Data.RuleIsHouseToLeftForTrial; 1];
                        elseif p.sequence.generating_side(choice_trials(c)) < 0 && p.rule_hierarchical_decision == 1
                            DSet.P(i).Data.RuleIsHouseToLeftForTrial = [DSet.P(i).Data.RuleIsHouseToLeftForTrial; 1];
                        else
                            DSet.P(i).Data.RuleIsHouseToLeftForTrial = [DSet.P(i).Data.RuleIsHouseToLeftForTrial; 0];
                        end
                        DSet.P(i).Data.DistIsUpperForTrial = [DSet.P(i).Data.DistIsUpperForTrial; NaN];
                    else
                        DSet.P(i).Data.StimIsHouse = [DSet.P(i).Data.StimIsHouse; NaN];
                        DSet.P(i).Data.RuleIsHouseToLeftForTrial = [DSet.P(i).Data.RuleIsHouseToLeftForTrial; NaN];
                        if p.sequence.generating_side(choice_trials(c)) > 0
                            DSet.P(i).Data.DistIsUpperForTrial = [DSet.P(i).Data.DistIsUpperForTrial; 0];
                        else
                            DSet.P(i).Data.DistIsUpperForTrial = [DSet.P(i).Data.DistIsUpperForTrial; 1];
                        end
                    end
                end
                
                % RuleIsHouseToLeftForCue
                for c = 1:length(choice_trials)
                    if c == 1
                        generating_side = p.sequence.generating_side(1:choice_trials(c)-1);
                    else
                        generating_side = p.sequence.generating_side(choice_trials(c-1)+1:choice_trials(c)-1);
                    end
                    RuleIsHouseToLeftForCue = zeros(size(generating_side));

                    if ~strcmp(cond_name, 'inference-only')
                        if p.rule_hierarchical_decision == 0
                            RuleIsHouseToLeftForCue(generating_side > 0) = 1;
                        else
                            RuleIsHouseToLeftForCue(generating_side < 0) = 1;
                        end
                        DSet.P(i).Data.RuleIsHouseToLeftForCue = [DSet.P(i).Data.RuleIsHouseToLeftForCue; {RuleIsHouseToLeftForCue}];  
                        DSet.P(i).Data.DistIsUpperForCue = [DSet.P(i).Data.DistIsUpperForCue; {NaN}];
                    else    
                        DSet.P(i).Data.RuleIsHouseToLeftForCue = [DSet.P(i).Data.RuleIsHouseToLeftForCue; {NaN}];
                        DistIsUpperForCue = zeros(size(generating_side));
                        DistIsUpperForCue(generating_side < 0) = 1;
                        DSet.P(i).Data.DistIsUpperForCue = [DSet.P(i).Data.DistIsUpperForCue; {DistIsUpperForCue}];
                    end
                end
                
                
                %% correct accuracy for AB165 due to different coding of
                % response buttons in the scanner first 2 runs
                if strcmp(subject, 'AB165') && session == 3 && run < 3
                    trl_ses = find(DSet.P(i).Data.SessionNum == 3);
                    trl_run = find(DSet.P(i).Data.BlockNum == run);
                    trl = intersect(trl_ses, trl_run);
                    
                    for t = trl'
                        if DSet.P(i).Data.RespIsLeftOrUp(t) == 1 && (DSet.P(i).Data.RuleIsHouseToLeftForTrial(t) == DSet.P(i).Data.StimIsHouse(t))
                            DSet.P(i).Data.Acc(t) = 1;
                        elseif DSet.P(i).Data.RespIsLeftOrUp(t) == 0 && (DSet.P(i).Data.RuleIsHouseToLeftForTrial(t)*DSet.P(i).Data.StimIsHouse(t) == 0)
                            DSet.P(i).Data.Acc(t) = 1;
                        elseif isnan(DSet.P(i).Data.RespIsLeftOrUp(t))
                            DSet.P(i).Data.Acc(t) = NaN;
                        else
                            DSet.P(i).Data.Acc(t) = 0;
                        end
                    end
                end
                
            end
        end
    end
end

save DSet_withRT DSet

%% calculate intervals between choice trials
load DSet_withRT.mat

min_max_mean_ITI = [];

for p = 1:length(DSet.P)

    number_cues_tmp = DSet.P(p).Data.CueLoc(contains(DSet.P(p).Data.BlockType, 'full_task'));

    number_cues_trl = [];
    for c = 1:length(number_cues_tmp)
        number_cues_trl(c) = length(number_cues_tmp{c});
    end

    min_max_mean_ITI = [min_max_mean_ITI; min(number_cues_trl), max(number_cues_trl), mean(number_cues_trl)];


end



%% compare accuracy in the lab vs scanner
load DSet_withRT.mat
subj_yng = {}; subj_old = {};
yng = 0; old = 0; acc_HD = cell(2, 1); 
for p = 1:length(DSet.P)
    
   if strcmp(DSet.P(p).Spec.Group, 'young_adults')
       grp = 1; yng = yng + 1;
       a = yng;
       subj_yng = [subj_yng; DSet.P(p).Spec.SubjID];
   else
       grp = 2; old = old + 1;
       a = old;
       subj_old = [subj_old; DSet.P(p).Spec.SubjID];
   end

    accuracy = DSet.P(p).Data.Acc(contains(DSet.P(p).Data.BlockType, 'full_task'));
    
    acc_HD{grp}(a, 1) = mean(accuracy, 'omitnan');

end

[h, p, ~, stats] = ttest2(acc_HD{1}, acc_HD{2})


%% calculate how many choice trials with double button presses
% calculate how many valid trials per participants
load DSet_withRT.mat
subj_yng = {}; subj_old = {};
yng = 0; old = 0; RT_HD = cell(2, 1); RT_inf= cell(2, 1);
RT_HD_house_face = cell(2, 1);
DoubleResp_HD = cell(2, 1); DoubleResp_inf= cell(2, 1); 
NoResp_HD = cell(2, 1); NoResp_inf = cell(2, 1);
valid_trls = cell(2, 1); total_trls = cell(2, 1); 
for p = 1:length(DSet.P)
    
   if strcmp(DSet.P(p).Spec.Group, 'young_adults')
       grp = 1; yng = yng + 1;
       a = yng;
       subj_yng = [subj_yng; DSet.P(p).Spec.SubjID];
   else
       grp = 2; old = old + 1;
       a = old;
       subj_old = [subj_old; DSet.P(p).Spec.SubjID];
   end

    accuracy = DSet.P(p).Data.Acc(contains(DSet.P(p).Data.BlockType, 'full_task'));
    total_trls{grp, 1} = [total_trls{grp, 1}; length(accuracy)];
    valid_trls{grp, 1} = [valid_trls{grp, 1}; length(accuracy(~isnan(accuracy)))];
    RT_HD_tmp = DSet.P(p).Data.RT(contains(DSet.P(p).Data.BlockType, 'full_task'));
    RT_HD{grp, 1} = [RT_HD{grp, 1}; median(RT_HD_tmp, 'omitmissing'), min(RT_HD_tmp)];

    RT_HD_tmp = DSet.P(p).Data.RT(contains(DSet.P(p).Data.BlockType, 'full_task'));
    RT_HD_house_tmp = DSet.P(p).Data.RT(DSet.P(p).Data.StimIsHouse == 1);
    RT_HD_face_tmp = DSet.P(p).Data.RT(DSet.P(p).Data.StimIsHouse == 0);
    RT_HD_house_face{grp, 1} = [RT_HD_house_face{grp, 1}; mean(RT_HD_house_tmp, 'omitnan'), mean(RT_HD_face_tmp, 'omitnan')];
    
    DoubleResp_HD_tmp = DSet.P(p).Data.RepeatedResp(contains(DSet.P(p).Data.BlockType, 'full_task'));
    DoubleResp_HD{grp, 1} = [DoubleResp_HD{grp, 1}; length(find(DoubleResp_HD_tmp == 1))];

    NoResp_HD_tmp = DSet.P(p).Data.NoResponse(contains(DSet.P(p).Data.BlockType, 'full_task'));
    NoResp_HD{grp, 1} = [NoResp_HD{grp, 1}; length(find(NoResp_HD_tmp == 1))];

    if ~isempty(find(contains(DSet.P(p).Data.BlockType, 'inf')))
        RT_inf_tmp = DSet.P(p).Data.RT(contains(DSet.P(p).Data.BlockType, 'inf'));
        RT_inf{grp, 1} = [RT_inf{grp, 1}; median(RT_inf_tmp, 'omitmissing'), min(RT_inf_tmp)];

        DoubleResp_inf_tmp = DSet.P(p).Data.RepeatedResp(contains(DSet.P(p).Data.BlockType, 'inf'));
        DoubleResp_inf{grp, 1} = [DoubleResp_inf{grp, 1}; length(find(DoubleResp_inf_tmp == 1))];

        NoResp_inf_tmp = DSet.P(p).Data.NoResponse(contains(DSet.P(p).Data.BlockType, 'inf'));
        NoResp_inf{grp, 1} = [NoResp_inf{grp, 1}; length(find(NoResp_inf_tmp == 1))];

    end

end

% valid trials per participant
[h,p_value,ci,stats] = ttest2(valid_trls{1}(:, 1), valid_trls{2}(:, 1))

mean(valid_trls{1})
mean(valid_trls{2})
std(valid_trls{1})
std(valid_trls{2})


% total trials per participant
[h,p_value,ci,stats] = ttest2(total_trls{1}(:, 1), total_trls{2}(:, 1))

mean(total_trls{1})
mean(total_trls{2})
std(total_trls{1})
std(total_trls{2})


[p_value,h,stats] = ranksum(DoubleResp_HD{1},DoubleResp_HD{2})

[p_value,h,stats] = ranksum(DoubleResp_HD{1}./total_trls{1},DoubleResp_HD{2}./total_trls{2})

median(DoubleResp_HD{1}./total_trls{1})
median(DoubleResp_HD{2}./total_trls{2})
iqr(DoubleResp_HD{1}./total_trls{1})
iqr(DoubleResp_HD{2}./total_trls{2})


% percentage of participants that responded at least once with a double
% button press in the hierarchical task
perc_part_doubleresp_yng = length(find(DoubleResp_HD{1}>0))/length(DoubleResp_HD{1})
perc_part_doubleresp_old = length(find(DoubleResp_HD{2}>0))/length(DoubleResp_HD{2})

mediantrls_doubleresp_yng = median(DoubleResp_HD{1})
mediantrls_doubleresp_old = median(DoubleResp_HD{2})

r = iqr(DoubleResp_HD{1})
iqr(DoubleResp_HD{2})

meantrls_doubleresp_yng = mean(DoubleResp_HD{1})
meantrls_doubleresp_old = mean(DoubleResp_HD{2})



perc_part_noresp_yng = length(find(NoResp_HD{1}>0))/length(NoResp_HD{1})
perc_part_noresp_old = length(find(NoResp_HD{2}>0))/length(NoResp_HD{2})

meantrls_noresp_yng = mean(NoResp_HD{1})
meantrls_noresp_old = mean(NoResp_HD{2})

mediantrls_noresp_yng = median(NoResp_HD{1}./total_trls{1})
mediantrls_noresp_old = median(NoResp_HD{2}./total_trls{2})

iqrtrls_noresp_yng = iqr(NoResp_HD{1}./total_trls{1})
iqrtrls_noresp_old = iqr(NoResp_HD{2}./total_trls{2})

[p_value,h,stats] = ranksum(NoResp_HD{1}./total_trls{1}, NoResp_HD{2}./total_trls{2})


% reaction time

[h,p_value,ci,stats] = ttest2(RT_HD{1}(:, 1), RT_HD{2}(:, 1))

mean(RT_HD{1}(:, 1))
mean(RT_HD{2}(:, 1))
std(RT_HD{1}(:, 1))
std(RT_HD{2}(:, 1))


[h,p_value,ci,stats] = ttest2(RT_HD_house_face{1}(:, 1), RT_HD_house_face{2}(:, 1))
[h,p_value,ci,stats] = ttest2(RT_HD_house_face{1}(:, 2), RT_HD_house_face{2}(:, 2))

[h,p_value,ci,stats] = ttest(RT_HD_house_face{1}(:, 1), RT_HD_house_face{1}(:, 2))
[h,p_value,ci,stats] = ttest(RT_HD_house_face{2}(:, 1), RT_HD_house_face{2}(:, 2))

mean(RT_HD_house_face{1}(:, 1))
mean(RT_HD_house_face{1}(:, 2))


figure; plot(RT_HD{1}(:, 1), acc_HD{1}, 'o')

figure; plot(RT_HD{2}(:, 1), acc_HD{2}, 'o')

[r, p] = corrcoef(RT_HD{1}(:, 1), acc_HD{1})
[r, p] = corrcoef(RT_HD{2}(:, 1), acc_HD{2})

%% calculate how many valid runs per participant and per group in the lab and scanner
load DSet_withRT.mat
subj_yng = {}; subj_old = {};
yng = 0; old = 0;
valid_runs_lab = cell(2, 1); valid_runs_scanner = cell(2, 1); 
for p = 1:length(DSet.P)
    
   if strcmp(DSet.P(p).Spec.Group, 'young_adults')
       grp = 1; yng = yng + 1;
       a = yng;
       subj_yng = [subj_yng; DSet.P(p).Spec.SubjID];
   else
       grp = 2; old = old + 1;
       a = old;
       subj_old = [subj_old; DSet.P(p).Spec.SubjID];
   end

   valid_runs_lab_all = [];
   if ~isempty(find(contains(DSet.P(p).Data.BlockType, 'full_task_lab')))
       valid_runs_lab_all = DSet.P(p).Data.BlockNum(contains(DSet.P(p).Data.BlockType, 'full_task_lab'));
   end

   valid_runs_lab{grp, 1}(a, 1) = length(unique(valid_runs_lab_all));

   valid_runs_scanner_all = [];
   if ~isempty(find(contains(DSet.P(p).Data.BlockType, 'full_task_scanner')))
       valid_runs_scanner_all = DSet.P(p).Data.BlockNum(contains(DSet.P(p).Data.BlockType, 'full_task_scanner'));
   end

   valid_runs_scanner{grp, 1}(a, 1) = length(unique(valid_runs_scanner_all));

end


mean(valid_runs_lab{1})
mean(valid_runs_lab{2})

mean(valid_runs_scanner{1})
mean(valid_runs_scanner{2}(valid_runs_scanner{2}>0))