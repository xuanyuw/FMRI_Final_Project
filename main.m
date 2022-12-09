global root_dir spm_rootdir raw_func_rootdir preproc_func_rootdir second_level_dir
root_dir = 'F:\fMRI_course\FMRI_Final_Project\data';
run_preproc = false;
run_first_level = false;
run_second_level = true;
run_locate_ROI = false;

spm_rootdir = fullfile(root_dir, 'model_estimation');
raw_func_rootdir = fullfile(root_dir, 'raw_data');
preproc_func_rootdir = fullfile(root_dir, 'preprocessed_data');
second_level_dir = fullfile(root_dir, 'model_estimation', 'second_level');

% get all subject IDs
d = dir(raw_func_rootdir);
d = {d.name};
d = d(contains(d, 'sub-'));
sub_li = extractAfter(d, 'sub-');
sub_li = cellfun(@str2num, sub_li);

%% preprocess
if run_preproc
    for sub=sub_li
        fMRIPreprocess(sub)
    end
end
%% 1st level analysis
if run_first_level
    for sub=sub_li
        estimate_GLM_model(sub, 'Num', [1 2])
        create_contrast(sub, 'Num', 'easy_hard', [0 1 -1 0])
        estimate_GLM_model(sub, 'Rhyming', [])
        create_contrast(sub, 'Rhyming', 'word_symbol', [-1 1])
    end
end
%% second level analysis
if run_second_level
    second_level(sub_li, 'Num', 'con_0001')
    create_contrast('grp', 'Num', 'easy_hard_grp', [1])

    second_level(sub_li, 'Rhyming', 'con_0001')
    create_contrast('grp', 'Rhyming', 'word_symbol_grp', [1])
end
%% find group ROI and subject ROI
if run_locate_ROI
    get_grp_ROI('Num', 'easy_hard_grp', 0.005)
    get_grp_ROI('Rhyming', 'word_symbol_grp', 0.005)
end
