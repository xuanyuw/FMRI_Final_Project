function fMRIPreprocess(sid)
 %This file is for fMRI preprocess which does not any other parameter files  
 %procedure: slice timing -> realign&unwrap(geomatric distortion correction by using field map) -> coregister -> segmentation -> normalization -> smooth
 %By Wang Han, 11/26/2022 
 
    %fmri data preprocess
    
    %%%cluster code
%     rawDataDir='/gpfs1/lushazhu_pkuhpc/wanghan/fMRI/fMRI_course/rawData/';   %% rawdata dir for speaker
%     outputDir='/gpfs1/lushazhu_pkuhpc/wanghan/fMRI/fMRI_course/preprocessedData/';  %% output dir for speaker
%     toolbox = '/gpfs1/lushazhu_pkuhpc/wanghan/toolbox/spm12';
%     addpath(genpath(toolbox));
    
    %%%pc code
    rawDataDir='F:\fMRI_course\final_project\raw_data\';   %% rawdata dir for speaker
    outputDir='F:\fMRI_course\final_project\preprocessed_data\';
    toolbox = 'F:\fMRI_course\spm12\';
    addpath(genpath(toolbox));
    
    sid = num2str(sid);
    conditionName = 'sub-';
    rawDataName = [conditionName,sid];
    outputDirSID = fullfile(outputDir,sid);
    
    
   %% creat new directory
   mkdir(outputDir,sid);
   task_names = {'Mult_run-01','Mult_run-02','Num_run-01','Num_run-02','Rhyming','Sub_run-01','Sub_run-02'};
   mkdir(fullfile(outputDirSID,'func'));
   mkdir(fullfile(outputDirSID,'anat'));
   for i = 1:length(task_names)
     mkdir(fullfile(outputDirSID,'func'),task_names{i});
   end
    
   %% unzip the nii.gz files
   [anatFiles, ~]=spm_select('FPList',fullfile(rawDataDir,rawDataName,cell2mat({'anat'})),'^sub.*\.gz$');
   if size(anatFiles,1)>0
    gunzip(anatFiles)
   end
   [funcFiles, ~]=spm_select('FPList',fullfile(rawDataDir,rawDataName,cell2mat({'func'})),'^sub.*\.gz$');
   if size(funcFiles,1)>0
       for i = 1:size(funcFiles,1)
           gunzip(cellstr(funcFiles(i,:)));
       end
   end 
   %% copy raw data files to the new dictory
   copyfile(fullfile(rawDataDir,rawDataName,'anat',['sub-',sid,'_T1w.nii']),fullfile(outputDirSID,'anat'));
   for i = 1:length(task_names)
       copyfile(fullfile(rawDataDir,rawDataName,'func',[rawDataName,'_task-',task_names{i},'_bold.nii']),fullfile(outputDirSID,'func',task_names{i}));
   end
   
    %% open the spm
    spm('defaults', 'FMRI');
    spm_jobman('initcfg');
    
    
    %%  ----------------------------slice timing-------------------------
       for i=1:length(task_names)
           
            funcDir = fullfile(outputDirSID,'func',task_names{i});
            [st_files, ~]=spm_select('FPList',funcDir,'^sub.*\.nii$');
           
            matlabbatch{1}.spm.temporal.st.scans = {cellstr(st_files)};
            matlabbatch{1}.spm.temporal.st.nslices = 32;
            matlabbatch{1}.spm.temporal.st.tr = 2;
            matlabbatch{1}.spm.temporal.st.ta = 2-2/32;
            matlabbatch{1}.spm.temporal.st.so = [2:2:32,1:2:32];
            matlabbatch{1}.spm.temporal.st.refslice = 32;
            matlabbatch{1}.spm.temporal.st.prefix = 'a';
            spm_jobman('run',matlabbatch); 
            clear matlabbatch*;
            
       end
 
            
   %% --------------------------------realign&estimate-------------------------------
       for i =1:length(task_names)
            funcDir = fullfile(outputDirSID,'func',task_names{i});
            [re_files, ~]=spm_select('FPList',funcDir,'^as.*\.nii$');
            matlabbatch{1}.spm.spatial.realign.estwrite.data = {cellstr(re_files)};
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep = 4;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 0;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp = 2;
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
            matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight = '';
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which = [2 1];
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp = 4;
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 1;
            matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix = 'r';
            spm_jobman('run',matlabbatch);
            clear matlabbatch*;  
       end
    
    %% ------------------------------coregister--------------------------
         for i =1:length(task_names) 

            % get the mean functional image
            funcDir = fullfile(outputDirSID,'func',task_names{i});
            [meanImage, ~]=spm_select('FPList',funcDir,'^mean.*\.nii$');

            %get the anatomical image
            anatDir = fullfile(outputDirSID,'anat');
            [anatImage, ~]=spm_select('FPList',anatDir,'^s.*\.nii$');

            matlabbatch{1}.spm.spatial.coreg.estimate.ref = cellstr(meanImage);
            matlabbatch{1}.spm.spatial.coreg.estimate.source = cellstr(anatImage);
            matlabbatch{1}.spm.spatial.coreg.estimate.other = {''};
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
            matlabbatch{1}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7]; 
            spm_jobman('run',matlabbatch);
            clear matlabbatch*;
            
         end

   %% ------------------------------------segmentation-------------------------- 
        anatDir = fullfile(outputDirSID,'anat');
        [segmFiles, ~]=spm_select('FPList',anatDir,'^s.*\.nii$');  %%generally, one participants only has one anatomical image

        matlabbatch{1}.spm.spatial.preproc.channel.vols =cellstr(segmFiles);
        matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
        matlabbatch{1}.spm.spatial.preproc.channel.write = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {fullfile(toolbox,'tpm','TPM.nii,1')};
        matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
        matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {fullfile(toolbox,'tpm','TPM.nii,2')};
        matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
        matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {fullfile(toolbox,'tpm','TPM.nii,3')};
        matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
        matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {fullfile(toolbox,'tpm','TPM.nii,4')};
        matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
        matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {fullfile(toolbox,'tpm','TPM.nii,5')};
        matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
        matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {fullfile(toolbox,'tpm','TPM.nii,6')};
        matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
        matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
        matlabbatch{1}.spm.spatial.preproc.warp.write = [1 1];   
        spm_jobman('run',matlabbatch);
        clear matlabbatch*; 

     
     %% -----------------------------------normalization----------------------------------     
        for i =1:length(task_names)
         % get TRANSFORMATION data from SEGMENTATION step
            anatDir = fullfile(outputDirSID,'anat');
            [normTransFiles, ~]=spm_select('FPList',anatDir, '^y.*\.nii$');

            %get MOTION CORRECTED data from REALIGN step
            funcDir = fullfile(outputDirSID,'func',task_names{i});
            [normMotionCorrFiles, ~]=spm_select('FPList',funcDir,'^ra.*\.nii$');

            matlabbatch{1}.spm.spatial.normalise.write.subj.def = cellstr(normTransFiles);
            matlabbatch{1}.spm.spatial.normalise.write.subj.resample = cellstr(normMotionCorrFiles);
            matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70; 78 76 85];
            matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [3 3 3];
            matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';
            spm_jobman('run',matlabbatch);

            clear matlabbatch*;
        end
        
            anatDir = fullfile(outputDirSID,'anat');
            [normTransFiles, ~]=spm_select('FPList',anatDir, '^y.*\.nii$');

            [normanatFiles, ~]=spm_select('FPList',anatDir,'^sub.*\.nii$');

            matlabbatch{1}.spm.spatial.normalise.write.subj.def = cellstr(normTransFiles);
            matlabbatch{1}.spm.spatial.normalise.write.subj.resample = cellstr(normanatFiles);
            matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70; 78 76 85];
            matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [3 3 3];
            matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';
            spm_jobman('run',matlabbatch);

            clear matlabbatch*;
     %% -----------------------------------smooth-----------------------------
         for i = 1:length(task_names)

            %get NORMALIZED data from normalization step, session1
            funcDir = fullfile(outputDirSID,'func',task_names{i});
            [smoothFiles, ~]=spm_select('FPList',funcDir,'^wra.*\.nii$');

            matlabbatch{1}.spm.spatial.smooth.data = cellstr(smoothFiles);
            matlabbatch{1}.spm.spatial.smooth.fwhm = [6 6 6];
            matlabbatch{1}.spm.spatial.smooth.dtype = 0;
            matlabbatch{1}.spm.spatial.smooth.im = 0;
            matlabbatch{1}.spm.spatial.smooth.prefix = 's';
            spm_jobman('run',matlabbatch);
            clear matlabbatch*;
         end  
end    




