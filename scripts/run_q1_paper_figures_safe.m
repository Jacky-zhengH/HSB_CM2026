%RUN_Q1_PAPER_FIGURES_SAFE Load paper_state.mat and render selected PNGs.
% Optional caller variables: paperFigureIDs, forceRegenerate,
% paperFigureLogName.  No reconstruction, GJK, or graph build occurs here.

scriptPath = mfilename('fullpath');
projectRoot = fileparts(fileparts(scriptPath));
addpath(projectRoot);
projectRoot = setup_project();
try
    opengl('software');
catch
end
if ~exist('paperFigureIDs', 'var'), paperFigureIDs = 1:10; end
if ~exist('forceRegenerate', 'var'), forceRegenerate = false; end
if ~exist('paperFigureLogName', 'var'), paperFigureLogName = 'figures_safe.log'; end

outputDir = fullfile(projectRoot, 'output', 'Q1_paper_final');
figureDir = fullfile(outputDir, 'figures');
logDir = fullfile(outputDir, 'logs');
if exist(figureDir, 'dir') ~= 7, mkdir(figureDir); end
if exist(logDir, 'dir') ~= 7, mkdir(logDir); end
logPath = fullfile(logDir, paperFigureLogName);
if exist(logPath, 'file') == 2, delete(logPath); end
diary(logPath);
diaryCleanup = onCleanup(@() diary('off'));

statePath = fullfile(outputDir, 'paper_state.mat');
assert(exist(statePath, 'file') == 2, ...
    'paper_state.mat is required before figure generation.');
loaded = load(statePath, 'paperState');
paperState = loaded.paperState;
clear loaded;
paperFont = getChineseFontName();
set(0, 'DefaultAxesFontName', paperFont);
set(0, 'DefaultTextFontName', paperFont);
set(0, 'DefaultUicontrolFontName', paperFont);
fprintf('Software OpenGL requested. Paper font: %s.\n', paperFont);

names = paperFigureNames();
template = struct('Index', 0, 'FigureName', '', 'Status', 'PENDING', ...
    'FileExists', false, 'FileSizeBytes', 0, 'ErrorMessage', '');
manifest = repmat(template, numel(names), 1);
for index = 1:numel(names)
    manifest(index).Index = index;
    manifest(index).FigureName = names{index};
    path = fullfile(figureDir, [names{index} '.png']);
    if exist(path, 'file') == 2
        info = dir(path);
        manifest(index).FileExists = true;
        manifest(index).FileSizeBytes = info.bytes;
        if info.bytes > 10000
            manifest(index).Status = 'PASS';
            manifest(index).ErrorMessage = '';
        end
    end
end
manifestPath = fullfile(figureDir, 'figure_manifest.csv');
writeFigureManifest(manifestPath, manifest);

paperFigureIDs = unique(paperFigureIDs(:).');
for taskIndex = 1:numel(paperFigureIDs)
    figureID = paperFigureIDs(taskIndex);
    assert(figureID >= 1 && figureID <= 10 && figureID == floor(figureID), ...
        'paperFigureIDs must contain integers 1 through 10.');
    path = fullfile(figureDir, [names{figureID} '.png']);
    if strcmp(manifest(figureID).Status, 'PASS') && ~forceRegenerate
        manifest(figureID).ErrorMessage = '';
        writeFigureManifest(manifestPath, manifest);
        fprintf('FIGURE %d %s SKIP_EXISTING\n', figureID, names{figureID});
        continue;
    end
    close all force;
    drawnow;
    try
        output = generateOnePaperFigure(paperState, figureID, figureDir, paperFont);
        manifest(figureID).Status = 'PASS';
        manifest(figureID).FileExists = true;
        manifest(figureID).FileSizeBytes = output.FileSizeBytes;
        manifest(figureID).ErrorMessage = '';
        fprintf('FIGURE %d %s PASS bytes=%d\n', figureID, ...
            names{figureID}, output.FileSizeBytes);
    catch figureError
        manifest(figureID).Status = 'FAILED';
        manifest(figureID).FileExists = exist(path, 'file') == 2;
        if manifest(figureID).FileExists
            info = dir(path);
            manifest(figureID).FileSizeBytes = info.bytes;
        else
            manifest(figureID).FileSizeBytes = 0;
        end
        manifest(figureID).ErrorMessage = getReport(figureError, ...
            'extended', 'hyperlinks', 'off');
        fprintf('FIGURE %d %s FAILED\n%s\n', figureID, ...
            names{figureID}, manifest(figureID).ErrorMessage);
    end
    writeFigureManifest(manifestPath, manifest);
    close all force;
    drawnow;
end

requestedStatus = {manifest(paperFigureIDs).Status};
if any(~strcmp(requestedStatus, 'PASS'))
    error('run_q1_paper_figures_safe:FigureFailed', ...
        'At least one requested figure failed. See figure_manifest.csv.');
end
if all(strcmp({manifest.Status}, 'PASS'))
    fprintf('Q1 PAPER FIGURES SAFE COMPLETE\n');
else
    fprintf('Q1 PAPER FIGURE BATCH COMPLETE\n');
end
diary('off');
clear diaryCleanup;
