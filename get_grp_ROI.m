function get_grp_ROI(p_thresh)
% Start marsbar to make sure spm_get works
marsbar('on')
[img_num, tmp_num] = find_diff_act_area('Num', 'easy_hard_grp', p_thresh);
[img_rhy, tmp_rhy] = find_diff_act_area('Rhyming', 'word_symbol_grp', p_thresh);

intsec = intersect(tmp_num, tmp_rhy);

XYZ = mars_utils('e2xyz', intsec, V.dim(1:3));





spm_file = fullfile(second_level_dir, task, 'SPM.mat');
roi_file = fullfile(second_level_dir, task, 'roi.mat');

marsbar('on')

D = mardo(spm_file);

% Get t threshold of uncorrected p < 0.05
erdf = error_df(D);
t_thresh = spm_invTcdf(1-p_thresh, erdf);

% get all voxels from t image above threshold
t_con = get_contrast_by_name(D, con_name);
t_con_fname = t_con.Vspm.fname;
V = spm_vol(t_con_fname);
img = spm_read_vols(V);
tmp = find(img(:) > t_thresh);
img = img(tmp);
XYZ = mars_utils('e2xyz', tmp, V.dim(1:3));

% find the most active voxel and set this as the center of spherical ROI
cluster_nos = spm_clusters(XYZ);
[mx, max_index] = max(img);
max_cluster = cluster_nos(max_index);
cluster_XYZ = XYZ(:, cluster_nos == max_cluster);

% Make ROI from max cluster
act_roi = maroi_pointlist(struct('XYZ', cluster_XYZ, ...
				 'mat', V.mat), 'vox');
             
% Make marsbar ROI object
R  = maroi(roi_file);
% Fetch data into marsbar data object
Y  = get_marsy(R, D, 'mean');
% Get contrasts from original design
xCon = get_contrasts(D);
% Estimate design on ROI data
E = estimate(D, Y);
% Put contrasts from original design back into design object
E = set_contrasts(E, xCon);
% get design betas
b = betas(E);
% get stats and stuff for all contrasts into statistics structure
marsS = compute_contrasts(E, 1:length(xCon));

end


