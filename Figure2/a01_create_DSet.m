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
                for j=1:size(p.out.log)
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
%                         reaction time, response side (1 - left response; 2 - right response), repeated_response
                        response_trials = [response_trials; reaction_time, response_side,  repeated_response];
                        
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

save DSet DSet

