

% INPUT:
%  rootDir        - Path to where subjects are located
%  subjects       - Vector containing list of subjects (can concatenate with brackets)
%  spmDir         - Path to folder where you want to move the multiple conditions .mat files and where to the output SPM file (directory is created if it doesn't
%  exist)
%  timingDir      - Path to timing directory, relative to rootDir
%  timingSuffix   - Suffix appended to timing files
%  matPrefix      - Will be prefixed to output .mat files.
%  dataDir        - Directory storing functional runs.
%
% OUTPUT:
%  One multiple condition .mat file per run. Also specifies the GLM and runs
%  beta estimation.
%
%
%       Note that this script assumes that your timing files are organized
%       with columns in the following order: Run, ConditionName, Onset (in
%       seconds), Duration (in seconds)
%
%       Ideally, this timing file should be written out from your
%       presentation software, e.g., E-Prime
%
%       Also note how the directory tree is structured in the following example. You may have to
%       change this script to reflect your directory structure.
%
%       Assume that:
%         rootdir = '/server/studyDirectory/'
%         spmDir = '/modelOutput/'
%         timingDir = '/timings/onsets/'
%         subjects = [101]
%         timingSuffix = '_timing.txt'
%       1) Sample path to SPM directory:
%       '/server/studyDirectory/101/modelOutput/'
%       2) Sample path to timing file in the timing directory:
%       '/server/studyDirectory/timings/onsets/101_timing.txt'
%
% Andrew Jahn, Indiana University, June 2014
% andysbrainblog.blogspot.com


function estimate_GLM_model(sid, task, run_nums)
% TODO: Add head movement (txt file starts with rp) to multiple regressor 
global spm_rootdir raw_func_rootdir preproc_func_rootdir
%%%-----------------------------------------------------%%%
spm_dir = fullfile(spm_rootdir, num2str(sid), task);
raw_func_dir = fullfile(raw_func_rootdir, ['sub-', num2str(sid)], 'func');
preproc_func_dir = fullfile(preproc_func_rootdir, num2str(sid), 'func');


%Change these parameters to reflect study-specific information about number
%of scans and discarded acquisitions (disacqs) per run
funcs = {};
task_dirs = {};
if isempty(run_nums)
    fn = ['swrasub-', num2str(sid), '_task-', task, '_bold.nii'];
    funcs{end+1} = fullfile(preproc_func_dir, task, fn);
    task_dirs{end+1} = fullfile(preproc_func_dir, task);
else
    for run_idx=run_nums
        fdir = [task, '_run-0', num2str(run_idx)];
        fn = ['swrasub-', num2str(sid), '_task-', task, '_run-0' num2str(run_idx), '_bold.nii'];
        funcs{end+1} = fullfile(preproc_func_dir, fdir, fn);
        task_dirs{end+1} = fullfile(preproc_func_dir, fdir);
    end
end


events = {};
if isempty(run_nums)
    efn = ['sub-', num2str(sid), '_task-', task, '_events.tsv'];
    events{end+1} = fullfile(raw_func_dir, efn);
else
    for run_idx=run_nums
        efn = ['sub-', num2str(sid), '_task-', task, '_run-0',num2str(run_idx), '_events.tsv'];
        events{end+1} = fullfile(raw_func_dir, efn);
    end
    
end



TR = 2; %Repetition time, in seconds

ESTIMATE_GLM = 1;


%%%-----------------------------------------------------%%%



%See whether output directory exists; if it doesn't, create it

if ~isfolder(spm_dir)
    mkdir(spm_dir)
end

for idx=1:length(events)
    if contains(events{idx}, 'run')
        temp_idx = extractBetween(events{idx}, '_run-0', '_events.tsv');
        run_idx = str2num(temp_idx{1});
    else
        run_idx = 1;
    end
    
    %Begin creating jobs structure
    jobs{1}.stats{1}.fmri_spec.dir = cellstr(spm_dir);
    jobs{1}.stats{1}.fmri_spec.timing.units = 'secs';
    jobs{1}.stats{1}.fmri_spec.timing.RT = TR;
    jobs{1}.stats{1}.fmri_spec.timing.fmri_t = 16;
    jobs{1}.stats{1}.fmri_spec.timing.fmri_t0 = 1;
    
    fid = fopen(events{idx}, 'rt');
    T = textscan(fid, '%s %s %s %s %s %s %s', 'HeaderLines', 1, 'Delimiter', '\t');
    fclose(fid);
    T = horzcat(T{1:4});
    % remove rows n/a values
    T = T(~any(strcmp(T,'n/a'), 2),:);
    accuracy = cellfun(@str2num, T(:, 4));
    % keep only correct trials
    corr_idx = accuracy==1;
    T = T(corr_idx, :);    
    onsets = cellfun(@str2num, T(:, 1));
    durations = cellfun(@str2num, T(:, 2));
    names = T(:, 3);
    % deal with rhyming parameters
    if strcmp(task, 'Rhyming')
        names(~contains(names, '6')) = {'word'};
        names(contains(names, '6')) = {'symbol'};     
    end
%     save (fullfile(spm_dir, ['testMulti_' num2str(sid) '_' num2str(run_idx)]), 'names', 'onsets', 'durations')
    
    %Grab frames for each run using spm_select, and fill in session
    %information within jobs structure
    files = spm_select('expand', funcs{idx});
    
    jobs{1}.stats{1}.fmri_spec.sess(run_idx).scans = cellstr(files);
    unq_names = unique(names);
    for nid = 1:length(unq_names)
        temp_idx = strcmp(names, unq_names{nid});
        n_onsets = onsets(temp_idx);
        n_durations = durations(temp_idx);
        jobs{1}.stats{1}.fmri_spec.sess(run_idx).cond(nid).name = unq_names{nid};
        jobs{1}.stats{1}.fmri_spec.sess(run_idx).cond(nid).onset = n_onsets;
        jobs{1}.stats{1}.fmri_spec.sess(run_idx).cond(nid).duration = n_durations;
        jobs{1}.stats{1}.fmri_spec.sess(run_idx).cond(nid).tmod = 0;
        jobs{1}.stats{1}.fmri_spec.sess(run_idx).cond(nid).pmod = struct('name', {}, 'param', {}, 'poly', {});
    end
%     jobs{1}.stats{1}.fmri_spec.sess(run_idx).multi = {[]};
    jobs{1}.stats{1}.fmri_spec.sess(run_idx).regress = struct('name', {}, 'val', {});
    jobs{1}.stats{1}.fmri_spec.sess(run_idx).multi_reg = cellstr(spm_select('FPList', task_dirs{run_idx},'^rp_.*\.txt$'));
    jobs{1}.stats{1}.fmri_spec.sess(run_idx).hpf = 128;
    
end


%Fill in the rest of the jobs fields
jobs{1}.stats{1}.fmri_spec.fact = struct('name', {}, 'levels', {});
jobs{1}.stats{1}.fmri_spec.bases.hrf = struct('derivs', [0 0]);
jobs{1}.stats{1}.fmri_spec.volt = 1;
jobs{1}.stats{1}.fmri_spec.global = 'None';
jobs{1}.stats{1}.fmri_spec.mask = {''};
jobs{1}.stats{1}.fmri_spec.cvi = 'AR(1)';

%Navigate to output directory, specify and estimate GLM
cd(spm_dir);
spm_jobman('run', jobs)

if ESTIMATE_GLM == 1
    load SPM;
    spm_spm(SPM);
end

end
