function projectRoot = setup_project()
%SETUP_PROJECT Add this V0 audit project's folders to the current session.
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
