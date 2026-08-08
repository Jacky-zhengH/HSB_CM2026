function projectRoot = setup_project()
%SETUP_PROJECT Add the formal Q1 validation folders to this MATLAB session.
%   This function does not modify the permanent MATLAB path.

projectRoot = fileparts(mfilename('fullpath'));

addpath(fullfile(projectRoot, 'src'));
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'tests'));

outputDir = fullfile(projectRoot, 'output');
if exist(outputDir, 'dir') ~= 7
    mkdir(outputDir);
end
end
