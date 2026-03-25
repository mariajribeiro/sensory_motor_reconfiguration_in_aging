% analyse cognitiva evaluation data
% NOTES:
% AB123 - Cantab was recorded with code AB999
% AB124 - Cantab data was recorded as AB123. Cantab re-evaluation data was recorded as AB666
% AB136 - Cognitive evaluation (3Nov2022), Cantab test 2 (MTT), iPad was not registering the responses although participant was responding right – possibly discard results.
% AB104 - Second Cantab visit recorded as AB777

clear; close all

[AnalysesFolder] = fileparts(pwd);

addpath(AnalysesFolder);

group = participants_included;

data_dir = pwd;

data_file = 'cognitive_assessment_analyses_LCproject.xlsx';

Tcog = readtable(data_file);
% missing = setdiff([group{1}, group{2}], Tcog.ParticipantID);

Tcantab = readtable('cantab_analyses_LCproject.xlsx');
% delete visit 2
idx_v2 = find(strcmp(Tcantab.VisitIdentifier, 'V2'));
Tcantab(idx_v2, :) = [];

Tcogall = Tcog;

% create table with cog tests + cantab
cantab_names = Tcantab.Properties.VariableNames;


for s = 1:length(Tcogall.ParticipantID)
    % populate group column
    if strcmp(Tcog.ParticipantID(s), 'AB123')
        Index = find(contains(Tcantab.newSubjectID, 'AB999'));
    elseif strcmp(Tcog.ParticipantID(s), 'AB124')
        Index = find(contains(Tcantab.newSubjectID, 'AB123')); % recorded with wrong code by mistake
    else 
        Index = find(contains(Tcantab.newSubjectID, Tcog.ParticipantID(s)));
    end
     
    Tcogall.Group(s) = Tcantab.Group(Index);

    % add cantab results to cog table
    for c =1:length(cantab_names)
        if contains(cantab_names(c), 'MTT') || contains(cantab_names(c), 'OTS') || contains(cantab_names(c), 'RTI')
            eval(['Tcogall.', cantab_names{c}, '(s)= Tcantab.', cantab_names{c}, '(Index);'])
        end
        
        if contains(cantab_names(c), 'MTT') && strcmp(Tcog.ParticipantID(s), 'AB136') % problem with registration of results
            eval(['Tcogall.', cantab_names{c}, '(s)= NaN;'])
        end  
    end
end

% save excel file for SPSS analysis
filename = 'cog_data_visit1.xlsx';
% writetable(Tcogall,filename);



% include centered variables for PCA analyses and zscored variable for
% composite creation

cogtest_names = Tcogall.Properties.VariableNames;

cogtests = Tcogall{:, 6:end};

for c = 1:size(cogtests, 2)
    cogtests_centered(:, c) = cogtests(:, c)-mean(cogtests(:, c), 'omitnan');
end

for c = 1:size(cogtests, 2)
    for ln = 1:size(cogtests, 1)
        cogtests_zscore(ln, c) = (cogtests(ln, c)-mean(cogtests(:, c), 'omitnan'))./std(cogtests(:, c), 'omitnan');
    end
end

% create table including all cognitive tests + scores centered + scores
% z-scored
cogtest_names_centered = {};
for t = 6:length(cogtest_names)
    cogtest_names_centered = [cogtest_names_centered, ['c_', cogtest_names{t}]];
end

cogtest_names_zscored = {};
for t = 6:length(cogtest_names)
    cogtest_names_zscored = [cogtest_names_zscored, ['zs_', cogtest_names{t}]];
end


Tcogcentzsc_tmp = array2table([cogtests, cogtests_centered, cogtests_zscore],...
    'VariableNames',[cogtest_names{6:end}, cogtest_names_centered, cogtest_names_zscored]);


%% include age and sex 
TPart = readtable('D:\Project_LC_fMRI\participants\participants_characterization.xlsx', 'Sheet', 'included');
%%
age = [];
sex = [];
for p = 1:size(Tcogall, 1)
    idx = find(strcmp(Tcogall.ParticipantID(p), TPart.ParticipantID));
    age = [age; TPart.Age(idx)];
    if strcmp(TPart.Sex{idx}, 'M')
        sex = [sex; 1];
    else
        sex = [sex; 2];
    end
end

Tage_sex = array2table([age, sex]);

Tage_sex.Properties.VariableNames = [{'age', 'sex'}];



%%


clear Tcogcentzsc

Tcogcentzsc(:, 1:5) = Tcogall(:, 1:5);
Tcogcentzsc(:, 6:7) = Tage_sex;
Tcogcentzsc(:, 8:size(Tcogcentzsc_tmp, 2)+7) = Tcogcentzsc_tmp;
Tcogcentzsc.Properties.VariableNames = [cogtest_names(1:5), 'age', 'sex', cogtest_names(6:end), cogtest_names_centered, cogtest_names_zscored];

% save excel file for SPSS analysis
filename = 'cog_data_visit1_centzsc_corrected.xlsx';
writetable(Tcogcentzsc,filename);