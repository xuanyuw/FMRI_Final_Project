global root_dir spm_rootdir raw_func_rootdir preproc_func_rootdir second_level_dir
root_dir = 'F:\fMRI_course\final_project';
run_preproc = true;

spm_rootdir = fullfile(root_dir, 'model_estimation');
raw_func_rootdir = fullfile(root_dir, 'raw_data');
preproc_func_rootdir = fullfile(root_dir, 'preprocessed_data');
second_level_dir = fullfile(root_dir, 'model_estimation', 'second_level');

sub_li = [1022 1025 1026 1027 1029 1030 1031 1032 1034];
if run_preproc
    for sub=sub_li
        fMRIPreprocess(sub)
    end
end

% for sub=sub_li
%     estimate_GLM_model(sub, 'Num', [1 2])
%     create_contrast(sub, 'Num', 'easy_hard', [0 1 -1 0])
% end
% estimate_GLM_model(1001, 'Mult', [1, 2])
% estimate_GLM_model(1002, 'Num', [1, 2])
% estimate_GLM_model(1001, 'Sub', [1, 2])
% estimate_GLM_model(1001, 'Rhyming', [])
% 
% create_contrast(1001, 'Num', 'easy_hard', [0 1 -1 0])
% create_contrast(1002, 'Num', 'easy_hard', [0 1 -1 0])
% 
% second_level(sub_li, 'Num', 'con_0001')
% create_contrast('grp', 'Num', 'easy_hard_grp', [1])
% get_grp_ROI('Num', 'easy_hard_grp', 0.005)
% get_subject_ROI(1001, 'Num', 'easy_hard - All Sessions', 0.005)
