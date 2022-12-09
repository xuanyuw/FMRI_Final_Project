function [img,tmp] = find_diff_act_area(task, con_name, p_thresh)

global second_level_dir
spm_file = fullfile(second_level_dir, task, 'SPM.mat');
D = mardo(spm_file);

erdf = error_df(D);
t_thresh = spm_invTcdf(1-p_thresh, erdf);

% get all voxels from t image above threshold
t_con = get_contrast_by_name(D, con_name);
t_con_fname = t_con.Vspm.fname;
V = spm_vol(t_con_fname);
img = spm_read_vols(V);
tmp = find(img(:) > t_thresh);
img = img(tmp);

end

