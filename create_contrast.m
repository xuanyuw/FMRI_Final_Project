function create_contrast(sid, task, con_name, con_vec)
global root_dir spm_rootdir second_level_dir
if isnumeric(sid)
    spm_dir = fullfile(spm_rootdir, num2str(sid), task);
elseif strcmp(sid, 'grp')
    spm_dir = fullfile(second_level_dir, task);
else
    print("invalid subject id, input a number of 'grp'")
    return
end
contrast_dir = fullfile(root_dir, 'contrasts', task);
if ~isfile(fullfile(contrast_dir, [con_name '_contrast.mat']))
    mkdir(contrast_dir)
    matlabbatch = [];
    matlabbatch{1}.spm.stats.con.spmmat = cellstr(fullfile(spm_dir,'SPM.mat'));
    matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = con_name;
    matlabbatch{1}.spm.stats.con.consess{1}.tcon.convec = con_vec;
    matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'repl';
    matlabbatch{1}.spm.stats.con.delete = 1;
    save(fullfile(contrast_dir, [con_name '_contrast.mat']), 'matlabbatch')
else
    fn = [con_name '_contrast.mat'];
    load(fullfile(contrast_dir,fn))
    matlabbatch{1}.spm.stats.con.spmmat = cellstr(fullfile(spm_dir,'SPM.mat'));
end
spm_jobman('run', matlabbatch);
end

