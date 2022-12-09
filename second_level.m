%-----------------------------------------------------------------------
% Job saved on 07-Dec-2022 21:45:04 by cfg_util (rev $Rev: 7345 $)
% spm SPM - SPM12 (7771)
% cfg_basicio BasicIO - Unknown
%-----------------------------------------------------------------------
function second_level(sub_li, task, con_fn)
global second_level_dir spm_rootdir
matlabbatch{1}.spm.stats.factorial_design.dir = {fullfile(second_level_dir, task)};

scan_li = {};
for sub = sub_li
    scan_li{end+1} = fullfile(spm_rootdir, num2str(sub), task, [con_fn '.nii,1']);
end

matlabbatch{1}.spm.stats.factorial_design.des.t1.scans = scan_li';
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

spm('defaults', 'FMRI');
spm_jobman('run', matlabbatch);
cd(fullfile(second_level_dir, task))
load SPM;
spm_spm(SPM);
end
