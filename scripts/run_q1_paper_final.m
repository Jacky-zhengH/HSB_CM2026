%RUN_Q1_PAPER_FINAL Validate completed compute, figures, and README outputs.

clearvars;
scriptPath = mfilename('fullpath');
projectRoot = fileparts(fileparts(scriptPath));
addpath(projectRoot);
projectRoot = setup_project();
[~, branchName] = system('git branch --show-current');
branchName = strtrim(branchName);
if ~strcmp(branchName, 'q1-paper-final-redo')
    error('run_q1_paper_final:WrongBranch', ...
        'Run only on q1-paper-final-redo, current=%s.', branchName);
end

outputDir = fullfile(projectRoot, 'output', 'Q1_paper_final');
figureDir = fullfile(outputDir, 'figures');
statePath = fullfile(outputDir, 'paper_state.mat');
assert(exist(statePath, 'file') == 2, 'Missing paper_state.mat.');
loaded = load(statePath, 'paperState');
state = loaded.paperState;
assert(isequal(state.FinalAnswers, [false true true]), ...
    'Final Q1 answers in paper_state.mat are not [0 1 1].');
assert(~state.upper.Conducting && state.graphs{2}.Conducting && ...
    state.graphs{3}.Conducting, 'Final lower/upper proof gate is not satisfied.');

names = paperFigureNames();
for index = 1:numel(names)
    path = fullfile(figureDir, [names{index} '.png']);
    assert(exist(path, 'file') == 2, 'Missing paper figure: %s.', path);
    info = dir(path);
    assert(info.bytes > 10000, 'Paper figure is too small: %s.', path);
end
manifestPath = fullfile(figureDir, 'figure_manifest.csv');
assert(exist(manifestPath, 'file') == 2, 'Missing figure_manifest.csv.');
manifestText = fileread(manifestPath);
passMatches = regexp(manifestText, ',PASS,1,', 'match');
passCount = numel(passMatches);
assert(passCount == 10, 'figure_manifest.csv does not contain ten PASS rows.');

readmePath = fullfile(projectRoot, 'README.md');
readmeText = fileread(readmePath);
for index = 1:numel(names)
    assert(~isempty(strfind(readmeText, [names{index} '.png'])), ... %#ok<STREMP>
        'README does not reference %s.png.', names{index});
end
required = {fullfile(outputDir, 'q1_final_summary.txt'), ...
    fullfile(outputDir, 'tables', 'q1_final_results.csv'), ...
    fullfile(outputDir, 'tables', 'group1_upper_bound_audit.csv'), ...
    fullfile(outputDir, 'logs', 'compute.log')};
for index = 1:numel(required)
    assert(exist(required{index}, 'file') == 2, ...
        'Missing final Q1 artifact: %s.', required{index});
end
fprintf('Q1 PAPER FINAL COMPLETE\n');
