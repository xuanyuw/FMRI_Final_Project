% to extract beta/BOLD values within ROI
clear

% % add toolboxes and functions to path -----
% spmDir = 'XXX';    
% marsDir = 'XXX';
% funcDir = 'XXX';
% addpath(genpath(spmDir));
% addpath(genpath(marsDir));
% addpath(genpath(funcDir));

% files and paths -------------
Mask_file = 'F:\fMRI_course\final_project\ROI\test_ROI.mat';
contrast_file = "F:\fMRI_course\final_project\model_estimation\1001\Rhyming\con_0001.nii";

% ---------------
% % Make marsbar design object
% D  = mardo(SPM_file);   
% 
% % Make marsbar ROI object
% R  = maroi(Mask_file);
% 
% % Fetch data into marsbar data object
% Y  = get_marsy(R, D, 'mean');
% 
% Y = struct(Y);
% 
% Neural_Y = Y.y_struct.Y;

%%%%
rois = maroi('load_cell', Mask_file);  % make maroi ROI objects
mY = get_marsy(rois{:}, contrast_file, 'mean');  % extract data into marsy data object
y = summary_data(mY); % get summary time course(s)
mY = struct(mY);
Contrast_mY = mY.y_struct.regions{1,1}.Y;
Contrast_sort = sort(Contrast_mY,'descend');
Contrast_th = Contrast_sort(50);


% get all voxels from roi image above threshold
index = find(Contrast_mY >= Contrast_th); 

MTG_max50_XYZ = mY.y_struct.regions{1, 1}.vXYZ(:,index);

MTG_max50_roi = maroi_pointlist(struct('XYZ', MTG_max50_XYZ, 'mat', mY.y_struct.regions{1, 1}.mat), 'vox');

% Give it a name
MTG_max50_roi = label(MTG_max50_roi, 'MTG_max50_roi');

% save ROI to MarsBaR ROI file, in current directory, just to show how
saveroi(MTG_max50_roi, '/Users/wanghan/Documents/fMRI_course/ROI/MTG_max50_roi.mat');

% Save as image
save_as_image(MTG_max50_roi, '/Users/wanghan/Documents/fMRI_course/ROI/MTG_max50_roi.img');
